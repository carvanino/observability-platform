output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://localhost:${var.grafana_port}"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://localhost:${var.prometheus_port}"
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = "http://localhost:${var.alertmanager_port}"
}

output "loki_url" {
  description = "Loki URL"
  value       = "http://localhost:${var.loki_port}"
}

output "tempo_url" {
  description = "Tempo URL"
  value       = "http://localhost:${var.tempo_port}"
}
