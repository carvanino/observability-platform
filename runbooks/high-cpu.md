# Runbook: High CPU Usage (Warning)

## What is this alert?
The `CPUUsageHigh` alert fires when CPU usage on a host exceeds **80%** for more than **5 consecutive minutes**. This is a warning — the system is under elevated load but still functional.

## Likely Causes
- Unexpected traffic spike hitting the application
- A runaway process consuming excessive CPU
- Background job or cron task running at an unusual time
- Memory pressure forcing excessive swapping (indirect CPU impact)
- A recent deployment introduced inefficient code

## First 3 Investigation Steps

**Step 1 — Identify which process is consuming CPU:**
```bash
ssh <host>
top -b -n 1 | head -20
# or
ps aux --sort=-%cpu | head -10
```

**Step 2 — Check for recent deployments or changes:**
```bash
# Check deployment history
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"

# Check system logs around the alert time
journalctl --since "30 minutes ago" | grep -i "error\|warning\|deploy"
```

**Step 3 — Check application metrics in Grafana:**
- Open the Node Exporter dashboard
- Look at the CPU time series — is it one core or all cores?
- Cross-reference with the request rate panel — did traffic spike?

## How to Resolve
- If a runaway process: `kill -9 <pid>` after confirming it is safe to kill
- If a traffic spike: check if autoscaling is needed or rate limiting should be applied
- If a recent deployment: consider rolling back if CPU stays elevated
- If a background job: reschedule it to run during off-peak hours

## Should I Roll Back?
Roll back if:
- CPU exceeded 80% immediately after a deployment
- The application is returning errors alongside the CPU spike
- CPU has not recovered after 15 minutes

Do not roll back if:
- CPU spike correlates with legitimate traffic increase
- The spike is isolated to a background job, not the application

## Escalation
Escalate to the on-call engineer if CPU remains above 80% for more than 30 minutes without a clear cause.
