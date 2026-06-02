global:
  slack_api_url: "${SLACK_WEBHOOK_URL}"
  resolve_timeout: 5m
  smtp_smarthost: "${SMTP_HOST}:${SMTP_PORT}"
  smtp_from: "${SMTP_FROM}"
  smtp_auth_username: "${SMTP_AUTH_USERNAME}"
  smtp_auth_password: "${SMTP_AUTH_PASSWORD}"
  smtp_require_tls: true

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-and-email-warning'
  routes:
    - match:
        severity: critical
      receiver: 'slack-and-email-critical'
      continue: false
    - match:
        severity: warning
      receiver: 'slack-and-email-warning'
      continue: false

receivers:
  - name: 'slack-and-email-warning'
    slack_configs:
      - channel: '#devops-alerts'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}warning{{ else }}good{{ end }}'
        title: '{{ if eq .Status "firing" }}:warning: FIRING{{ else }}:white_check_mark: RESOLVED{{ end }} — {{ .CommonLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Severity:* {{ .Labels.severity | toUpper }}
          *Status:* {{ .Status | toUpper }}
          *Host:* {{ .Labels.instance | default "N/A" }}
          *Value:* {{ .Annotations.value | default "N/A" }}
          *Summary:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Dashboard:* {{ .Annotations.dashboard_url }}
          *Runbook:* {{ .Annotations.runbook_url }}
          *Started:* {{ .StartsAt.Format "2006-01-02 15:04:05 UTC" }}
          {{ end }}
    email_configs:
      - to: 'orjiugo.victor@gmail.com,jameskefaslungu@gmail.com,herchaos08@gmail.com'
        send_resolved: true
        headers:
          subject: '[WARNING]{{ if eq .Status "resolved" }} RESOLVED{{ end }} — {{ .CommonLabels.alertname }}'
        html: |
          <h2>{{ if eq .Status "firing" }}⚠️ FIRING{{ else }}✅ RESOLVED{{ end }} — {{ .CommonLabels.alertname }}</h2>
          {{ range .Alerts }}
          <table>
            <tr><td><b>Alert</b></td><td>{{ .Labels.alertname }}</td></tr>
            <tr><td><b>Severity</b></td><td>{{ .Labels.severity | toUpper }}</td></tr>
            <tr><td><b>Status</b></td><td>{{ .Status | toUpper }}</td></tr>
            <tr><td><b>Host</b></td><td>{{ .Labels.instance | default "N/A" }}</td></tr>
            <tr><td><b>Value</b></td><td>{{ .Annotations.value | default "N/A" }}</td></tr>
            <tr><td><b>Summary</b></td><td>{{ .Annotations.summary }}</td></tr>
            <tr><td><b>Description</b></td><td>{{ .Annotations.description }}</td></tr>
            <tr><td><b>Dashboard</b></td><td><a href="{{ .Annotations.dashboard_url }}">View Dashboard</a></td></tr>
            <tr><td><b>Runbook</b></td><td><a href="{{ .Annotations.runbook_url }}">View Runbook</a></td></tr>
            <tr><td><b>Started</b></td><td>{{ .StartsAt.Format "2006-01-02 15:04:05 UTC" }}</td></tr>
          </table>
          {{ end }}

  - name: 'slack-and-email-critical'
    slack_configs:
      - channel: '#devops-alerts'
        send_resolved: true
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'
        title: '{{ if eq .Status "firing" }}:red_circle: CRITICAL FIRING{{ else }}:white_check_mark: RESOLVED{{ end }} — {{ .CommonLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Severity:* {{ .Labels.severity | toUpper }}
          *Status:* {{ .Status | toUpper }}
          *Host:* {{ .Labels.instance | default "N/A" }}
          *Value:* {{ .Annotations.value | default "N/A" }}
          *Summary:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Dashboard:* {{ .Annotations.dashboard_url }}
          *Runbook:* {{ .Annotations.runbook_url }}
          *Started:* {{ .StartsAt.Format "2006-01-02 15:04:05 UTC" }}
          {{ end }}
    email_configs:
      - to: 'orjiugo.victor@gmail.com,jameskefaslungu@gmail.com,herchaos08@gmail.com'
        send_resolved: true
        headers:
          subject: '[CRITICAL]{{ if eq .Status "resolved" }} RESOLVED{{ end }} — {{ .CommonLabels.alertname }}'
        html: |
          <h2>{{ if eq .Status "firing" }}🔴 CRITICAL FIRING{{ else }}✅ RESOLVED{{ end }} — {{ .CommonLabels.alertname }}</h2>
          {{ range .Alerts }}
          <table>
            <tr><td><b>Alert</b></td><td>{{ .Labels.alertname }}</td></tr>
            <tr><td><b>Severity</b></td><td>{{ .Labels.severity | toUpper }}</td></tr>
            <tr><td><b>Status</b></td><td>{{ .Status | toUpper }}</td></tr>
            <tr><td><b>Host</b></td><td>{{ .Labels.instance | default "N/A" }}</td></tr>
            <tr><td><b>Value</b></td><td>{{ .Annotations.value | default "N/A" }}</td></tr>
            <tr><td><b>Summary</b></td><td>{{ .Annotations.summary }}</td></tr>
            <tr><td><b>Description</b></td><td>{{ .Annotations.description }}</td></tr>
            <tr><td><b>Dashboard</b></td><td><a href="{{ .Annotations.dashboard_url }}">View Dashboard</a></td></tr>
            <tr><td><b>Runbook</b></td><td><a href="{{ .Annotations.runbook_url }}">View Runbook</a></td></tr>
            <tr><td><b>Started</b></td><td>{{ .StartsAt.Format "2006-01-02 15:04:05 UTC" }}</td></tr>
          </table>
          {{ end }}

inhibit_rules:
  - source_match:
      alertname: 'ServerDown'
    target_match_re:
      alertname: 'CPU.*|Memory.*|Disk.*|SLO.*'
    equal: ['instance']
