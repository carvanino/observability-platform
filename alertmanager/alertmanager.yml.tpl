global:
  slack_api_url: "${SLACK_WEBHOOK_URL}"
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-notifications-warning'
  routes:
    - match:
        severity: critical
      receiver: 'slack-notifications-critical'
      continue: false
    - match:
        severity: warning
      receiver: 'slack-notifications-warning'
      continue: false

receivers:
  - name: 'slack-notifications-warning'
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

  - name: 'slack-notifications-critical'
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

inhibit_rules:
  - source_match:
      alertname: 'ServerDown'
    target_match_re:
      alertname: 'CPU.*|Memory.*|Disk.*|SLO.*'
    equal: ['instance']
