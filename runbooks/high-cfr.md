# Runbook: High Change Failure Rate

## What is this alert?
The `HighChangeFailureRate` alert fires when more than **15%** of deployments over the last 30 days resulted in a failure, rollback, or hotfix. The DORA elite benchmark for CFR is 0-15%. Exceeding this means the deployment process is consistently introducing production failures.

## What This Means
If you deployed 20 times this month and 4 caused incidents, your CFR is 20% — above the 15% threshold. This pattern indicates a systemic problem in how code is tested, reviewed, or deployed.

## Likely Causes
- Insufficient test coverage — bugs reaching production that should be caught in CI
- Missing environment parity — code works in staging but fails in production
- Rushed deployments without adequate review
- No staged rollout — full traffic hits new code immediately
- Missing feature flags — unable to safely test new code with a subset of users

## First 3 Investigation Steps

**Step 1 — Review recent failed deployments:**
- Open Grafana → DORA dashboard
- Identify which deployments caused failures
- Look for patterns — same service? Same type of change? Same author?

**Step 2 — Check the GitHub Actions failure logs:**
```bash
# Review recent workflow runs for failures
gh run list --limit 20 --json conclusion,name,createdAt
```

**Step 3 — Analyse incident timeline:**
- Cross-reference failed deployments with ServerDown and burn rate alerts
- How long after deployment did the incident occur?
- Was it caught by automated health checks or by users?

## How to Resolve
- **Short term:** pause non-critical deployments until CFR drops below threshold
- **Medium term:** improve test coverage for the most common failure patterns
- **Long term:** implement staged rollouts, feature flags, and canary deployments

## Escalation
Escalate to engineering lead for a process review if CFR exceeds 15% for two consecutive weeks.
