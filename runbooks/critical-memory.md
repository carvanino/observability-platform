# Runbook: Critical Memory Usage

## What is this alert?
The `MemoryUsageCritical` alert fires when memory usage exceeds **90%** for more than **5 consecutive minutes**. The system is at risk of OOM (Out of Memory) kills — the OS may start terminating processes to free memory.

## Likely Causes
- Severe memory leak
- Application holding large amounts of data in memory
- Memory exhaustion from a traffic surge
- Another process on the host consuming unexpected memory

## First 3 Investigation Steps

**Step 1 — Check if OOM kills have already happened:**
```bash
dmesg | grep -i "oom\|killed" | tail -20
journalctl -k | grep -i "oom\|out of memory" | tail -20
```

**Step 2 — Check available memory urgently:**
```bash
free -h
# If available < 200MB — act immediately
```

**Step 3 — Identify largest memory consumers:**
```bash
ps aux --sort=-%mem | head -5
docker stats --no-stream
```

## How to Resolve
**Immediate action:**
```bash
# Restart the highest memory-consuming container
docker restart <container_name>
```

**If OOM kills are happening:**
- The OS has already started killing processes
- Check which containers/services are still running: `docker ps`
- Restart any stopped services immediately

**If all containers are running but memory is still critical:**
- Clear system caches: `sync && echo 3 > /proc/sys/vm/drop_caches`
- This is temporary — investigate root cause immediately after

## Should I Roll Back?
Yes — roll back immediately if:
- Memory spike followed a deployment
- OOM kills are occurring

## Escalation
P1 incident. Escalate immediately. OOM kills will cause service outages.
