# Runbook: High Disk Usage (Warning)

## What is this alert?
The `DiskUsageHigh` alert fires when disk usage on a mount point exceeds **75%**. Action is needed before the disk fills up completely.

## Likely Causes
- Log files growing without rotation
- Docker images and stopped containers accumulating
- Database or metrics data growing beyond expected size
- Application generating large temporary files
- Loki or Prometheus retention not working correctly

## First 3 Investigation Steps

**Step 1 — Find which directories are consuming the most space:**
```bash
df -h                          # see all mount points
du -sh /* 2>/dev/null | sort -rh | head -10
du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -10
```

**Step 2 — Check log file sizes:**
```bash
find /var/log -name "*.log" -size +100M 2>/dev/null
docker system df              # Docker disk usage breakdown
```

**Step 3 — Check retention is working:**
- Open Grafana → Loki datasource → verify logs are being deleted after 30 days
- Check Prometheus: `curl http://localhost:9090/-/status` — verify TSDB retention

## How to Resolve
- Clean Docker: `docker system prune -f` (removes stopped containers, unused images, unused networks)
- Rotate logs: `logrotate -f /etc/logrotate.conf`
- Remove old Prometheus data manually if retention isn't working
- Clear old archives: check `logs/archived/` from Stage 5 if applicable

## Should I Roll Back?
Not applicable — disk usage is infrastructure, not application-related.

## Escalation
Escalate if disk is above 85% and not reducing after cleanup. Critical alert will fire at 90%.
