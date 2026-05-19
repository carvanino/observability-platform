# Runbook: Critical Disk Usage

## What is this alert?
The `DiskUsageCritical` alert fires when disk usage exceeds **90%**. The disk is nearly full — write operations will start failing imminently, causing service outages.

## Likely Causes
- All causes from the warning runbook, now at a critical level
- Log shipping or metrics retention failed silently for an extended period
- A large file was written unexpectedly (core dump, large upload)

## First 3 Investigation Steps

**Step 1 — Find the largest files immediately:**
```bash
find / -xdev -type f -size +500M 2>/dev/null | sort -k5 -rn
du -sh /* 2>/dev/null | sort -rh | head -5
```

**Step 2 — Emergency Docker cleanup:**
```bash
docker system prune -af --volumes
# WARNING: this removes ALL unused images and volumes
# Confirm no critical data is in unnamed volumes first
```

**Step 3 — Check for core dumps or crash files:**
```bash
find / -name "core.*" -o -name "*.dump" 2>/dev/null | head -10
ls -lh /tmp/ | sort -k5 -rh | head -10
```

## How to Resolve
**Immediate — free space now:**
```bash
# Clear journal logs older than 3 days
journalctl --vacuum-time=3d

# Clear Docker build cache
docker builder prune -af

# Truncate large log files (only if they can be recreated)
truncate -s 0 /var/log/large-file.log
```

**After stabilising:** implement log rotation and verify retention policies.

## Should I Roll Back?
Not applicable for disk issues.

## Escalation
P1 — escalate immediately. When disk hits 100% the system will crash.
