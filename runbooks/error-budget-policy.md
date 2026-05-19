# Error Budget Policy

## Overview

This document defines how the team responds to error budget consumption. The error budget is a shared resource — it belongs to neither developers nor operations alone. How it is spent is a team decision governed by this policy.

---

## SLO Targets and Error Budgets

| SLI | SLO Target | Window | Error Budget |
|-----|-----------|--------|-------------|
| Availability | 99.5% | 30 days | 216 minutes |
| Latency (p95 < 500ms) | 95% | 30 days | 5% of requests |
| Error Rate | 99% | 30 days | 432 minutes |

---

## Budget Consumption Thresholds and Responses

### 0–50% Consumed — Normal Operations
- No restrictions
- Team ships features at normal velocity
- Weekly review of burn rate in team standup
- Monitor for trends

### 50–75% Consumed — Elevated Awareness
- Engineering lead notified
- Deployment review: any risky changes require additional testing
- Root cause analysis for any incidents that contributed to budget consumption
- No major architectural changes without explicit sign-off

### 75–100% Consumed — Slow Down
- Deployment frequency reduced
- Only bug fixes and reliability improvements are deployed
- All deployments require peer review and staged rollout
- Daily budget review
- Team reliability sprint begins — toil reduction and reliability improvements take priority over features

### 100% Consumed — Feature Freeze
- **Immediate feature freeze** — no new feature deployments
- Only critical bug fixes and rollbacks permitted
- Mandatory reliability sprint — the entire team focuses on reliability
- SLO review meeting within 48 hours — was the target too aggressive?
- Post-incident review for every incident that contributed to budget exhaustion
- Feature freeze lifted only when burn rate drops below 1x AND remaining budget is replenished through the next measurement window

---

## Burn Rate Alert Response

| Alert | Burn Rate | Action |
|-------|----------|--------|
| SloBurnRateSlow | 5x over 6h | Investigate within 2 hours, consider slowing deployments |
| SloBurnRateFast | 14.4x over 1h | Immediate investigation, feature freeze, escalate to lead |

---

## SLO Review Process

SLOs are reviewed:
- **Quarterly** — routine review of targets, adjust if consistently met or consistently missed
- **After major incidents** — determine if target was realistic
- **After significant architecture changes** — new targets may be needed

### Questions Reviewed Each Quarter
1. Did we meet the SLO for the quarter?
2. If yes — was the target too conservative? Should we tighten it?
3. If no — was the target too aggressive? What would a realistic target be?
4. Did error budget policy trigger correctly and was it followed?
5. What toil was identified and addressed?

---

## Decision Authority

| Decision | Owner |
|---------|-------|
| Feature freeze | Engineering Lead |
| SLO target changes | Engineering Lead + Product |
| Lifting feature freeze | Engineering Lead |
| Declaring reliability sprint | Engineering Lead |

---

## Policy Review

This policy is reviewed quarterly alongside SLO targets. Last reviewed: May 2026.
