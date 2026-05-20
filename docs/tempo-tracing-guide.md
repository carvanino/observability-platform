# Tempo Distributed Tracing — Setup & Instrumentation Guide

## What is Tempo?

Tempo is a distributed tracing backend. It tracks a single request as it travels through multiple services, showing you every step, how long each took, and where failures occurred.

## How We Use Tempo

In our stack, Tempo receives traces from the OpenTelemetry Collector, stores them for 48 hours, and serves them to Grafana for visualization.

## Architecture

App Server Monitoring VPS
┌──────────────────┐ ┌─────────────────┐
│ clinsight API │ │ │
│ (instrumented │─── OTLP traces ──▶│ OTel Collector │──▶ Tempo (3200)
│ with OTel SDK) │ │ │
└──────────────────┘ └─────────────────┘
│
▼
Grafana (3000)
(click trace ID → Tempo)

text

## Instrumenting the FastAPI App

### Step 1: Install OpenTelemetry packages

```bash
uv add opentelemetry-api opentelemetry-sdk opentelemetry-instrumentation-fastapi opentelemetry-exporter-otlp
```
