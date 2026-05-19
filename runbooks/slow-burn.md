# Runbook: Slow SLO Burn Rate

## What is this alert?
The `SloBurnRateSlow` alert fires when the error budget is being consumed at **5x or more** the normal rate over the last **6 hours**. Not immediately catastrophic but needs attention before it escalates to a fast burn.

## What This Means
At a 5x burn rate the monthly budget will be exhausted in approximately **6 days**. You have time to investigate properly but should not ignore this alert.

## Likely Causes
- Slightly elevated error rate from a recent change
- Gradual performance degradation (memory leak, connection pool exhaustion)
- Background job causing intermittent failures
- A dependency becoming intermittently slow or unreliable

## First 3 Investigation Steps

**Step 1 — Calculate current error rate trend:**
```promql
# Compare current 6h burn rate vs 1h burn rate
# If 1h rate is higher than 6h rate — situation is worsening
(1 - sum(rate(http_requests_total{status=~"2.."}[1h])) / sum(rate(http_requests_total[1h]))) / 0.005
(1 - sum(rate(http_requests_total{status=~"2.."}[6h])) / sum(rate(http_requests_total[6h]))) / 0.005
```

**Step 2 — Check the SLO dashboard:**
- Open Grafana → SLO & Error Budget dashboard
- Check error budget remaining percentage
- Look at the burn rate trend over the last 24 hours — is it accelerating?

**Step 3 — Correlate with recent deployments:**
- Check DORA dashboard for recent deployments
- Compare burn rate start time with deployment time

## How to Resolve
- If correlated with a deployment: consider rolling back or hotfixing
- If gradual degradation: profile the application and identify root cause
- If intermittent dependency: add retry logic or circuit breaker

## Error Budget Policy Trigger
At 5x burn rate with less than 25% budget remaining: slow down deployments and prioritise reliability work.

## Escalation
Escalate to the team lead if burn rate is trending upward and root cause cannot be identified within 2 hours.
