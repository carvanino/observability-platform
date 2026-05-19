# Blameless Post-Incident Review (PIR)

## Incident Summary

| Field | Value |
|-------|-------|
| Incident ID | INC-001 |
| Date | 2026-05-10 |
| Duration | 47 minutes |
| Severity | P1 |
| Affected Service | clinsight API |
| Impact | 100% of requests returning 502 Bad Gateway |
| SLO Impact | ~22% of monthly error budget consumed |

---

## Timeline

| Time (UTC) | Event |
|-----------|-------|
| 14:23 | Deployment of v2.4.1 triggered via GitHub Actions |
| 14:25 | Deployment completed — pipeline showed green |
| 14:27 | Blackbox probe begins failing — `ServerDown` alert fires |
| 14:27 | Slack notification received in #DevOps-Alerts |
| 14:29 | On-call engineer acknowledges alert |
| 14:32 | Engineer SSHes into VPS — finds clinsight container restarting repeatedly |
| 14:35 | Container logs reviewed — database connection string is wrong in new env var |
| 14:38 | Decision made to roll back to v2.4.0 |
| 14:41 | Rollback deployed via GitHub Actions |
| 14:43 | clinsight container starts successfully |
| 14:44 | Blackbox probe returns success — `ServerDown` resolved notification sent to Slack |
| 15:10 | Full incident review meeting held |

---

## Root Cause

A new environment variable `DATABASE_URL` was added in v2.4.1 but was not added to the production environment configuration. The application failed to start because it could not parse a nil database URL on startup. The container entered a crash loop — starting, failing, restarting — which caused all inbound requests to receive 502 responses from Nginx.

The root cause is a missing step in the deployment checklist: new environment variables must be provisioned in production before the deployment is rolled out.

---

## What Went Wrong in Detection and Tooling

1. **CI pipeline showed green despite the deployment failing.** The GitHub Actions workflow only checks that the Docker image builds and the container starts — it does not verify that the application's health endpoint returns 200 after startup. The pipeline should run a post-deployment health check.

2. **Detection took 2 minutes.** The Blackbox probe runs every 30 seconds and requires 2 consecutive failures before alerting. This is by design to prevent false alarms, but it means a complete outage takes up to 2 minutes to surface. This is acceptable for this SLO.

3. **No pre-deployment validation for environment variables.** There was no automated check to verify all required environment variables are present before a deployment proceeds.

---

## Impact

- 47 minutes of complete service unavailability
- 100% of requests returned 502 during the incident window
- Error budget consumed: 47 minutes out of 216 minutes (21.8%)
- After this incident, 78.2% of the monthly error budget remains

---

## Action Items

| Action | Owner | Due Date | Status |
|--------|-------|---------|--------|
| Add post-deployment health check to GitHub Actions pipeline | Engineering | 2026-05-17 | Open |
| Create environment variable checklist in deployment runbook | Engineering | 2026-05-14 | Open |
| Add automated env var validation step to CI pipeline | Engineering | 2026-05-24 | Open |
| Review Terraform variable definitions to include all required env vars | DevOps | 2026-05-17 | Open |

---

## What Went Well

- Alert fired within 2 minutes of the outage starting — well within acceptable detection time
- Slack notification was structured and actionable — engineer had the dashboard and runbook link immediately
- Rollback decision was made quickly and executed cleanly
- Total time from alert to resolution was 17 minutes — within the MTTR SLO

---

## Lessons Learned

1. **Green CI does not mean working deployment.** Build validation and runtime validation are different things. Both are needed.

2. **Environment variable mismatches are a common deployment failure.** A simple automated check comparing required env vars in the application against provisioned env vars would catch this class of failure entirely.

3. **The observability stack worked as designed.** The Blackbox probe detected the outage, Alertmanager routed the alert correctly, and the structured Slack payload gave the responding engineer everything needed to start investigating immediately. The tooling was not the problem.

---

## Blameless Statement

This incident was caused by a gap in the deployment process — not by any individual's mistake. The engineer who wrote v2.4.1 followed the existing process correctly. The process itself did not include a step for provisioning new environment variables before deployment. The action items above address the process gap, not individual behaviour.
