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

Step 2: Add tracing to app/main.py
python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Setup tracing

trace.set_tracer_provider(TracerProvider())
otlp_exporter = OTLPSpanExporter(endpoint="http://157.180.45.114:4318/v1/traces")
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))

# Instrument FastAPI

FastAPIInstrumentor.instrument_app(app)
Step 3: Verify traces in Grafana
Open Grafana → Explore → Tempo

Search for traces from service "clinsight"

Click any trace to see the full waterfall view

How Trace Correlation Works
When a log line contains trace_id=abc123, Grafana's Loki derived fields detect it and render it as a clickable link. Clicking opens Tempo with that exact trace, showing every span in the request journey.

Trace Retention
Traces stored for 48 hours

Sufficient for debugging recent issues

Not designed for long-term analysis

Troubleshooting
No traces appearing: Check OTel Collector logs on monitoring VPS

Traces incomplete: Verify all services are instrumented

Trace ID not clickable: Check Loki derived fields config in Grafana
EOF

text

### Add a Tempo dashboard panel config:

```bash
cat > grafana/provisioning/dashboards/tempo-panel.json << 'EOF'
{
  "title": "Tempo Trace Viewer",
  "type": "traces",
  "datasource": "Tempo",
  "targets": [
    {
      "queryType": "traceql",
      "query": "{ .service.name = \"clinsight\" }",
      "refId": "A"
    }
  ],
  "description": "Search and view distributed traces from the clinsight API"
}
EOF
```
