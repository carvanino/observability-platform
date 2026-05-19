# Runbook: High Memory Usage (Warning)

## What is this alert?
The `MemoryUsageHigh` alert fires when memory usage exceeds **80%** for more than **5 consecutive minutes**. The system is under memory pressure but still operational.

## Likely Causes
- Memory leak in the application — gradual increase over time
- Caching layer growing unbounded
- Too many concurrent requests holding memory
- A recent deployment increased memory consumption
- Log buffers or queues accumulating in memory

## First 3 Investigation Steps

**Step 1 — Check current memory breakdown:**
```bash
free -h
# Look at: total, used, free, buff/cache, available
```

**Step 2 — Identify which process is using the most memory:**
```bash
ps aux --sort=-%mem | head -10
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

**Step 3 — Check if memory is trending up or stable:**
- Open Node Exporter dashboard in Grafana
- Look at the memory time series for the last 2 hours
- A steady upward trend = memory leak
- A sudden jump = recent event (deployment, traffic spike)

## How to Resolve
- If memory leak suspected: restart the affected container to release memory, then investigate root cause
- If caching: check cache eviction policies and reduce cache TTL
- If traffic-related: scale horizontally if possible
- Long term: profile the application for memory leaks

## Should I Roll Back?
Roll back if:
- Memory increased sharply immediately after a deployment
- Memory is trending upward with no signs of stabilising

## Escalation
Escalate if memory usage continues climbing toward 90% — that will trigger the critical alert and potential OOM kills.
