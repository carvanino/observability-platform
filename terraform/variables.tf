variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for Alertmanager notifications"
  type        = string
  sensitive   = true
}

variable "grafana_port" {
  description = "Port Grafana is exposed on"
  type        = number
  default     = 3000
}

variable "prometheus_port" {
  description = "Port Prometheus is exposed on"
  type        = number
  default     = 9090
}

variable "alertmanager_port" {
  description = "Port Alertmanager is exposed on"
  type        = number
  default     = 9093
}

variable "loki_port" {
  description = "Port Loki is exposed on"
  type        = number
  default     = 3100
}

variable "tempo_port" {
  description = "Port Tempo is exposed on"
  type        = number
  default     = 3200
}

variable "github_token" {
  description = "GitHub Personal Access Token for DORA metrics"
  type        = string
  sensitive   = true
}
