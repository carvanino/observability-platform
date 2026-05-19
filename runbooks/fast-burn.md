# Runbook: Fast SLO Burn Rate

## What is this alert?
The `SloBurnRateFast` alert fires when the error budget is being consumed at **14.4x or more** the normal rate over the last **1 hour**. At this rate the entire monthly error budget will be exhausted in approximately **2 days**. Immediate action required.

## What This Means
Your SLO is 99.5% availability over 30 days. Your monthly error budget is 216 minutes of allowed downtime. A 14.4x burn rate means you are spending that budget 14.4 times faster than sustainable. If nothing changes, the budget is gone in ~50 hours.

## Likely Causes
- Elevated error rate (5xx responses) from a bad deployment
- Latency degradation causing timeouts
- Dependency failure (database, external API) affecting request success
- Infrastructure issue (CPU, memory, disk) causing request failures

## First 3 Investigation Steps

**Step 1 — Check current error rate:**
```promql
# Run in Grafana → Explore → Prometheus
rate(http_requests_total{status=~"5.."}[5m])
/
rate(http_requests_total[5m])
```

**Step 2 — Check Loki for error patterns:**
- Open Grafana → Explore → Loki
- Query: `{job="clinsight"} |= "error" | level="error"`
- Look for repeating error messages

**Step 3 — Find the causing trace in Tempo:**
- Look for a trace ID in the error logs
- Click the trace ID → opens in Tempo
- Identify which span has elevated duration or errors

## How to Resolve
- If bad deployment: roll back immediately
- If dependency failure: implement circuit breaker or fallback
- If infrastructure: address the underlying resource issue first

## Error Budget Policy Trigger
At fast burn rate: **feature freeze immediately**. No new deployments until burn rate returns below 1x.

## Escalation
P1 — escalate to engineering lead. Every minute of inaction depletes the monthly budget.
