# Runbook: High Mean Time to Restore

## What is this alert?
The `HighMTTR` alert fires when the average time to resolve incidents exceeds **60 minutes**. The DORA elite benchmark for MTTR is under 1 hour. Exceeding this means the team is spending too long recovering from incidents.

## What This Means
MTTR is measured from when an alert fires to when the incident is resolved. If this average is above 60 minutes, either incidents are complex, the response process is slow, or investigation tools are insufficient.

## Likely Causes
- Slow alert detection — incidents go unnoticed for too long before alerting
- Unclear runbooks — responders don't know what to do when an alert fires
- Missing observability — logs or traces not available to diagnose the issue quickly
- Slow rollback process — reverting a bad deployment takes too long
- Alert fatigue — team ignoring alerts due to too many false positives

## First 3 Investigation Steps

**Step 1 — Review the MTTR breakdown on the DORA dashboard:**
- Open Grafana → DORA dashboard
- Look at the MTTR time series
- Is it consistently high or were there a few very long incidents skewing the average?

**Step 2 — Review recent incident timelines:**
- Look at the blameless PIR documents
- Where did time get lost? Detection, diagnosis, or resolution?
- Was the runbook helpful or unclear?

**Step 3 — Check alert-to-acknowledge time:**
- How long between alert firing and engineer acknowledging?
- If more than 5 minutes — the notification process needs improvement

## How to Resolve
- **If detection is slow:** reduce Blackbox probe interval, reduce `for` duration on critical alerts
- **If diagnosis is slow:** improve runbooks, add more context to alert annotations, improve dashboard drill-down
- **If resolution is slow:** implement faster rollback process, add feature flags
- **If alert fatigue:** audit alert rules, remove noisy low-value alerts

## Escalation
Escalate to engineering lead for a full incident response review if MTTR stays above 60 minutes for more than one week.
