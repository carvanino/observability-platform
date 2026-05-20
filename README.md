# Production-Grade Observability Platform

A complete LGTM observability stack with SLO/Error Budget tracking, DORA metrics, structured alerting, and Infrastructure as Code — deployable with a single command.

---

## Architecture

```
                          INTERNET
                              │
                         HTTP requests
                              │
                              ▼
                    ┌─────────────────┐
                    │   Your Service  │
                    │  (clinsight)    │
                    └────────┬────────┘
                             │ emits
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
         Metrics           Logs          Traces
              │              │              │
              ▼              ▼              ▼
         Prometheus        Loki           Tempo
              │              │              │
              └──────────────┴──────────────┘
                             │
                             ▼
                          Grafana
                   (unified observability)
                             │
                             ▼
                       Alertmanager
                             │
                             ▼
                    #DevOps-Alerts (Slack)

Supporting components:
  Node Exporter      → host metrics (CPU, RAM, Disk, Network)
  Blackbox Exporter  → external HTTP probing + SSL expiry
  OpenTelemetry      → log and trace shipping pipeline
```

---

## Stack Components

| Component | Purpose | Port |
|-----------|---------|------|
| Prometheus | Metrics collection and storage | 9090 |
| Loki | Log aggregation | 3100 |
| Tempo | Distributed trace storage | 3200 |
| Grafana | Unified observability UI | 3000 |
| Alertmanager | Alert routing to Slack | 9093 |
| Node Exporter | Host-level metrics | 9100 |
| Blackbox Exporter | HTTP and SSL probing | 9115 |
| OpenTelemetry Collector | Log and trace shipping | 4317/4318 |

---

## Prerequisites

- Docker Engine 24+
- Terraform 1.5+
- A Linux VPS (minimum 2 vCPU, 4GB RAM)
- Slack webhook URL for alert notifications

---

## Quick Start — Zero to Running in 5 Commands

```bash
# 1. Clone the repository
git clone https://github.com/carvanino/observability-platform.git
cd observability-platform

# 2. Configure secrets
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars   # add your Grafana password and Slack webhook

# 3. Initialise Terraform
cd terraform && terraform init

# 4. Deploy the full stack
terraform apply -var-file="terraform.tfvars" -auto-approve

# 5. Open Grafana
open http://localhost:3000
# Login: admin / your-password
```

That's it. The entire LGTM stack is running.

---

## Repository Structure

```
observability-platform/
├── terraform/
│   ├── main.tf                    # all Docker resources
│   ├── variables.tf               # variable declarations
│   ├── outputs.tf                 # URLs printed after apply
│   └── terraform.tfvars           # secrets (gitignored)
│
├── prometheus/
│   ├── prometheus.yml             # scrape config
│   └── rules/
│       ├── infrastructure.yml     # CPU, memory, disk, server alerts
│       ├── slo.yml                # burn rate alerts
│       └── cicd.yml               # DORA alerts (CFR, MTTR)
│
├── loki/
│   └── loki.yaml                  # log storage config (30 day retention)
│
├── tempo/
│   └── tempo.yaml                 # trace storage config (48h retention)
│
├── alertmanager/
│   └── alertmanager.yml           # routing + inhibition + Slack config
│
├── otel/
│   └── otel-collector.yaml        # log and trace shipping pipelines
│
├── grafana/
│   ├── grafana.ini                # Grafana application config
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yaml   # Prometheus, Loki, Tempo connections
│       └── dashboards/
│           ├── dashboards.yaml    # dashboard provider config
│           ├── node-exporter.json # host metrics dashboard
│           ├── blackbox.json      # endpoint health dashboard
│           ├── slo.json           # SLO and error budget dashboard
│           ├── dora.json          # DORA metrics dashboard
│           └── unified.json       # log + trace correlation dashboard
│
└── runbooks/
    ├── high-cpu.md
    ├── critical-cpu.md
    ├── high-memory.md
    ├── critical-memory.md
    ├── high-disk.md
    ├── critical-disk.md
    ├── server-down.md
    ├── fast-burn.md
    ├── slow-burn.md
    ├── high-cfr.md
    ├── high-mttr.md
    ├── error-budget-policy.md
    └── post-incident-review.md
```

---

## Four Golden Signals — SLI Definitions

Each SLI is a ratio of good events to total events, expressed as a PromQL query.

### 1. Latency
```promql
# P95 request latency
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket[5m])
)

# Latency SLI — percentage of requests under 500ms
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
/
sum(rate(http_request_duration_seconds_count[5m]))
```

### 2. Traffic
```promql
# Requests per second
sum(rate(http_requests_total[5m]))
```

### 3. Errors
```promql
# Error rate SLI — percentage of successful requests
sum(rate(http_requests_total{status=~"2.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

### 4. Saturation
```promql
# CPU saturation
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory saturation
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes)
/
node_memory_MemTotal_bytes * 100
```

---

## SLO Targets and Error Budgets

| SLI | SLO Target | Window | Error Budget |
|-----|-----------|--------|-------------|
| Availability | 99.5% | 30 days | 216 minutes |
| Latency (p95 < 500ms) | 95% | 30 days | 5% of requests |
| Error Rate | 99% | 30 days | 432 minutes |

See [Error Budget Policy](runbooks/error-budget-policy.md) for the full policy including feature freeze thresholds and escalation procedures.

---

## Alert Rules

All alert rules are version-controlled in `prometheus/rules/`.

### Infrastructure Alerts

| Alert | Condition | Severity |
|-------|-----------|---------|
| CPUUsageHigh | CPU > 80% for 5m | Warning |
| CPUUsageCritical | CPU > 90% for 10m | Critical |
| MemoryUsageHigh | Memory > 80% for 5m | Warning |
| MemoryUsageCritical | Memory > 90% for 5m | Critical |
| DiskUsageHigh | Disk > 75% | Warning |
| DiskUsageCritical | Disk > 90% | Critical |
| ServerDown | Blackbox probe fails 2m | Critical |

### SLO Burn Rate Alerts

| Alert | Condition | Severity |
|-------|-----------|---------|
| SloBurnRateFast | 14.4x burn rate over 1h | Critical |
| SloBurnRateSlow | 5x burn rate over 6h | Warning |

### CI/CD Alerts

| Alert | Condition | Severity |
|-------|-----------|---------|
| HighChangeFailureRate | CFR > 15% over 30d | Critical |
| HighMTTR | Average MTTR > 60 minutes | Warning |

---

## Grafana Dashboards

All dashboards are provisioned as JSON — never manually configured.

| Dashboard | Description |
|-----------|-------------|
| **Node Exporter** | CPU, memory, disk, network I/O, load averages |
| **Blackbox Exporter** | Uptime, HTTP response time, SSL expiry countdown |
| **SLO & Error Budget** | SLI gauges, budget remaining, burn rate time series |
| **DORA Metrics** | DF, LTC, CFR, MTTR with benchmark classifications |
| **Unified Observability** | Metrics + logs + traces with clickable trace correlation |

---

## Log and Trace Correlation

The Loki datasource is configured with derived fields that detect trace IDs in log lines and render them as clickable links to Tempo.

When a log line contains `trace_id=abc123`:
1. Grafana renders the trace ID as a hyperlink
2. Clicking opens Tempo with that exact trace
3. The full request journey — every span, every service, every duration — is visible

This allows you to go from a metric spike → correlated logs → root cause trace in under 2 minutes.

---

## Runbooks

Every alert has a corresponding runbook answering:
- What is this alert?
- What are the likely causes?
- First 3 investigation steps
- How to resolve
- When to roll back
- When and who to escalate to

| Runbook | Alert |
|---------|-------|
| [high-cpu.md](runbooks/high-cpu.md) | CPUUsageHigh |
| [critical-cpu.md](runbooks/critical-cpu.md) | CPUUsageCritical |
| [high-memory.md](runbooks/high-memory.md) | MemoryUsageHigh |
| [critical-memory.md](runbooks/critical-memory.md) | MemoryUsageCritical |
| [high-disk.md](runbooks/high-disk.md) | DiskUsageHigh |
| [critical-disk.md](runbooks/critical-disk.md) | DiskUsageCritical |
| [server-down.md](runbooks/server-down.md) | ServerDown |
| [fast-burn.md](runbooks/fast-burn.md) | SloBurnRateFast |
| [slow-burn.md](runbooks/slow-burn.md) | SloBurnRateSlow |
| [high-cfr.md](runbooks/high-cfr.md) | HighChangeFailureRate |
| [high-mttr.md](runbooks/high-mttr.md) | HighMTTR |

---

## Data Retention

| Component | Retention |
|-----------|----------|
| Prometheus metrics | 30 days |
| Loki logs | 30 days |
| Tempo traces | 48 hours |

---

## Tearing Down

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

---

## Known Limitations

- Single-node deployment — not designed for high availability
- Tempo trace retention is 48 hours — sufficient for debugging but not long-term analysis
- DORA metrics require a GitHub Actions exporter to be configured separately
- Grafana dashboards for SLO, DORA, and Unified are placeholders — build them in the UI and export as JSON

---

## Blog Post

https://medium.com/@akinolatofunmi/monitoring-with-grafana-bfeffb568861

---

## GitHub Repository

[https://github.com/carvanino/observability-platform](https://github.com/carvanino/observability-platform)
