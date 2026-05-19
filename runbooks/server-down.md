# Runbook: Server Down

## What is this alert?
The `ServerDown` alert fires when the Blackbox Exporter HTTP probe fails for **2 consecutive minutes**. The service endpoint is not returning a 2xx response — it is unreachable or returning errors.

## Likely Causes
- Application container crashed or stopped
- Port binding failure — another process took the port
- Nginx misconfiguration after a config reload
- Network connectivity issue between Blackbox and the service
- OOM kill terminated the application process
- Deployment failed mid-way leaving service in broken state

## First 3 Investigation Steps

**Step 1 — Check if containers are running:**
```bash
docker ps -a
# Look for: Exited, Restarting, or missing containers
```

**Step 2 — Check the application and Nginx logs:**
```bash
docker logs clinsight --tail 50
docker logs nginx --tail 50
# Look for: panic, fatal, port already in use, OOM killed
```

**Step 3 — Test the endpoint directly:**
```bash
# Test from the host
curl -v http://localhost:8000/api/v1/health

# Test Nginx routing
curl -v http://localhost/api/v1/health

# Test Blackbox probe directly
curl "http://localhost:9115/probe?target=http://clinsight:8000/api/v1/health&module=http_2xx"
```

## How to Resolve
**If container stopped:**
```bash
docker start clinsight
# or
docker compose up -d clinsight
```

**If container is in restart loop:**
```bash
docker logs clinsight --tail 100
# Fix the root cause before restarting
```

**If Nginx is the issue:**
```bash
docker exec nginx nginx -t    # test config
docker exec nginx nginx -s reload
```

## Should I Roll Back?
Roll back if:
- Service went down immediately after a deployment
- Container logs show application errors after the deployment

## Escalation
P1 — escalate immediately. Users cannot reach the service.
