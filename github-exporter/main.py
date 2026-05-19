import os
import time
import requests
from datetime import datetime, timezone
from prometheus_client import start_http_server, Gauge, Counter
from prometheus_client.core import REGISTRY

# ── Config ─────────────────────────────────────────────────────────
GITHUB_TOKEN  = os.environ.get("GITHUB_TOKEN", "")  # optional for public repos
GITHUB_OWNER  = os.environ.get("GITHUB_OWNER", "hngprojects")
GITHUB_REPO   = os.environ.get("GITHUB_REPO", "clinical-api")
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "300"))  # 5 minutes

HEADERS = {"Accept": "application/vnd.github.v3+json"}
if GITHUB_TOKEN:
    HEADERS["Authorization"] = f"token {GITHUB_TOKEN}"

BASE_URL = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}"

# ── Prometheus metrics ─────────────────────────────────────────────
deployment_frequency = Gauge(
    "dora_deployment_frequency_daily",
    "Average number of deployments per day over last 30 days"
)

change_failure_rate = Gauge(
    "dora_change_failure_rate_percent",
    "Percentage of deployments that caused failures over last 30 days"
)

lead_time_seconds = Gauge(
    "dora_lead_time_seconds",
    "Average time from workflow trigger to completion in seconds"
)

mttr_seconds = Gauge(
    "dora_mttr_seconds",
    "Mean time to restore — average time failed workflows take to recover"
)

deployments_total = Gauge(
    "dora_deployments_total",
    "Total deployments in last 30 days"
)

deployments_failed = Gauge(
    "dora_deployments_failed_total",
    "Total failed deployments in last 30 days"
)


def get_workflow_runs():
    """Fetch workflow runs from the last 30 days."""
    runs = []
    page = 1
    cutoff = time.time() - (30 * 24 * 60 * 60)

    while True:
        url = f"{BASE_URL}/actions/runs?per_page=100&page={page}"
        response = requests.get(url, headers=HEADERS, timeout=30)

        if response.status_code != 200:
            print(f"GitHub API error: {response.status_code} {response.text}")
            break

        data = response.json()
        workflow_runs = data.get("workflow_runs", [])

        if not workflow_runs:
            break

        for run in workflow_runs:
            created = datetime.fromisoformat(
                run["created_at"].replace("Z", "+00:00")
            ).timestamp()

            if created < cutoff:
                return runs

            runs.append(run)

        page += 1
        time.sleep(0.5)  # respect rate limits

    return runs


def calculate_dora_metrics(runs):
    """Calculate DORA metrics from workflow runs."""
    if not runs:
        return

    # Filter to deployment workflows only
    deploy_runs = [
        r for r in runs
        if any(kw in r.get("name", "").lower()
               for kw in ["deploy", "release", "publish", "production", "staging"])
    ]

    # Fall back to all runs if no deploy workflows found
    if not deploy_runs:
        deploy_runs = runs

    total = len(deploy_runs)
    failed = len([r for r in deploy_runs if r["conclusion"] in ["failure", "cancelled"]])
    successful = [r for r in deploy_runs if r["conclusion"] == "success"]

    # Deployment Frequency — deployments per day over 30 days
    df = total / 30.0
    deployment_frequency.set(round(df, 3))
    deployments_total.set(total)
    deployments_failed.set(failed)

    # Change Failure Rate
    cfr = (failed / total * 100) if total > 0 else 0
    change_failure_rate.set(round(cfr, 2))

    # Lead Time — average duration of successful runs
    durations = []
    for run in successful:
        if run.get("created_at") and run.get("updated_at"):
            start = datetime.fromisoformat(run["created_at"].replace("Z", "+00:00"))
            end   = datetime.fromisoformat(run["updated_at"].replace("Z", "+00:00"))
            durations.append((end - start).total_seconds())

    if durations:
        avg_lead_time = sum(durations) / len(durations)
        lead_time_seconds.set(round(avg_lead_time, 2))

    # MTTR — average duration of failed runs (proxy for recovery time)
    failed_durations = []
    for run in deploy_runs:
        if run["conclusion"] in ["failure"] and run.get("created_at") and run.get("updated_at"):
            start = datetime.fromisoformat(run["created_at"].replace("Z", "+00:00"))
            end   = datetime.fromisoformat(run["updated_at"].replace("Z", "+00:00"))
            failed_durations.append((end - start).total_seconds())

    if failed_durations:
        avg_mttr = sum(failed_durations) / len(failed_durations)
        mttr_seconds.set(round(avg_mttr, 2))

    print(f"[{datetime.now()}] DORA metrics updated:")
    print(f"  Deployment Frequency: {df:.3f}/day ({total} deployments in 30d)")
    print(f"  Change Failure Rate:  {cfr:.2f}% ({failed}/{total} failed)")
    print(f"  Lead Time:           {sum(durations)/len(durations)/60:.1f} min avg" if durations else "  Lead Time: no data")
    print(f"  MTTR:                {sum(failed_durations)/len(failed_durations)/60:.1f} min avg" if failed_durations else "  MTTR: no failed runs")


def main():
    # Start Prometheus HTTP server
    start_http_server(9999)
    print(f"GitHub Actions Exporter started on port 9999")
    print(f"Monitoring: {GITHUB_OWNER}/{GITHUB_REPO}")
    print(f"Poll interval: {POLL_INTERVAL}s")

    while True:
        try:
            print(f"\nFetching workflow runs from GitHub API...")
            runs = get_workflow_runs()
            print(f"Found {len(runs)} workflow runs in last 30 days")
            calculate_dora_metrics(runs)
        except Exception as e:
            print(f"Error collecting metrics: {e}")

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
