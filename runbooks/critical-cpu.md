# Runbook: Critical CPU Usage

## What is this alert?
The `CPUUsageCritical` alert fires when CPU usage exceeds **90%** for more than **10 consecutive minutes**. This is critical — the system is severely overloaded and user-facing degradation is likely.

## Likely Causes
- DDoS or traffic flood
- Infinite loop or deadlock in application code
- Runaway process consuming all available CPU
- A deployment introduced a serious performance regression
- Resource contention from multiple services on the same host

## First 3 Investigation Steps

**Step 1 — Check if the service is still responding:**
```bash
curl -w "\n%{http_code} %{time_total}s\n" http://localhost:8000/api/v1/health
```

**Step 2 — Find the process consuming CPU:**
```bash
# Real-time process view
htop

# If htop not available
top -b -n 3 -d 1 | grep -E "^(top|Tasks|%Cpu|Cpu|MiB|KiB|PID)"

# Check Docker container CPU usage
docker stats --no-stream
```

**Step 3 — Check error rates in Grafana:**
- Open the SLO dashboard
- Check if error budget burn rate is also elevated
- If burn rate is critical — this is a P1 incident

## How to Resolve
- Restart the offending container: `docker restart <container_name>`
- If traffic flood: apply rate limiting at the Nginx level immediately
- If application regression: roll back the last deployment
- If external attack: block IPs at the firewall level

## Should I Roll Back?
Roll back immediately if:
- CPU exceeded 90% within minutes of a deployment
- Error rate is also elevated (SLO burn rate alert firing)
- Service health check is failing

## Escalation
This is a P1 incident. Escalate immediately if the service is degraded or down. Do not wait.
