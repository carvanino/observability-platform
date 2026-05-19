terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "docker" {}

# Base paths
locals {
  base_path = abspath("${path.module}/..")
}

# Network
resource "docker_network" "monitoring" {
  name = "monitoring"
}

# Prometheus
resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = "prom/prometheus:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  volumes {
    host_path      = "${local.base_path}/prometheus/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    host_path      = "${local.base_path}/prometheus/rules"
    container_path = "/etc/prometheus/rules"
    read_only      = true
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.retention.time=30d",
    "--web.enable-lifecycle"
  ]
}

# Loki 
resource "docker_container" "loki" {
  name    = "loki"
  image   = "grafana/loki:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3100
    external = var.loki_port
  }

  volumes {
    host_path      = "${local.base_path}/loki/loki.yaml"
    container_path = "/etc/loki/loki.yaml"
    read_only      = true
  }

  command = ["-config.file=/etc/loki/loki.yaml"]
}

# Tempo 
resource "docker_container" "tempo" {
  name    = "tempo"
  image   = "grafana/tempo:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3200
    external = var.tempo_port
  }

  ports {
    internal = 4317
    external = 4317
  }

  ports {
    internal = 4318
    external = 4318
  }

  volumes {
    host_path      = "${local.base_path}/tempo/tempo.yaml"
    container_path = "/etc/tempo/tempo.yaml"
    read_only      = true
  }

  command = ["-config.file=/etc/tempo/tempo.yaml"]
}

# Grafana
resource "docker_container" "grafana" {
  name    = "grafana"
  image   = "grafana/grafana:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_PATHS_PROVISIONING=/etc/grafana/provisioning"
  ]

  volumes {
    host_path      = "${local.base_path}/grafana/grafana.ini"
    container_path = "/etc/grafana/grafana.ini"
    read_only      = true
  }

  volumes {
    host_path      = "${local.base_path}/grafana/provisioning"
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }
}

#  Alertmanager config (generated from template)
resource "local_file" "alertmanager_config" {
  content  = templatefile("${local.base_path}/alertmanager/alertmanager.yml.tpl", {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
  })
  filename = "${local.base_path}/alertmanager/alertmanager.yml"
}

# Alertmanager
resource "docker_container" "alertmanager" {
  name    = "alertmanager"
  image   = "prom/alertmanager:latest"
  restart = "unless-stopped"

  depends_on = [local_file.alertmanager_config]

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9093
    external = var.alertmanager_port
  }

  env = [
    "SLACK_WEBHOOK_URL=${var.slack_webhook_url}"
  ]

  volumes {
    host_path      = "${local.base_path}/alertmanager/alertmanager.yml"
    container_path = "/etc/alertmanager/alertmanager.yml"
    read_only      = true
  }

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml"
  ]
}

# Node Exporter 
resource "docker_container" "node_exporter" {
  name    = "node-exporter"
  image   = "prom/node-exporter:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9100
    external = 9100
  }

  volumes {
    host_path      = "/proc"
    container_path = "/host/proc"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/host/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  command = [
    "--path.procfs=/host/proc",
    "--path.sysfs=/host/sys",
    "--path.rootfs=/rootfs",
    "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
  ]
}

# Blackbox Exporter
resource "docker_container" "blackbox" {
  name    = "blackbox-exporter"
  image   = "prom/blackbox-exporter:latest"
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 9115
    external = 9115
  }
}

#  OpenTelemetry Collector
resource "docker_container" "otel_collector" {
  name    = "otel-collector"
  image   = "otel/opentelemetry-collector-contrib:latest"
  restart = "unless-stopped"
  user    = "0"

  networks_advanced {
    name = docker_network.monitoring.name
  }

  ports {
    internal = 4317
    external = 14317
  }

  ports {
    internal = 4318
    external = 14318
  }

  volumes {
    host_path      = "${local.base_path}/otel/otel-collector.yaml"
    container_path = "/etc/otelcol-contrib/config.yaml"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker/containers"
    container_path = "/var/lib/docker/containers"
    read_only      = true
  }
}
