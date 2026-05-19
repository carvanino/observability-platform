global:
  slack_api_url: "${SLACK_WEBHOOK_URL}"
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-notifications-high'
  routes:
    - match:
        severity: critical
      receiver: 'slack-notifications-critical'
      continue: false

receivers:
  - name: 'slack-notifications-high'
    slack_configs:
      - channel: '#devops-alerts'
        send_resolved: true
        title: "{{ .CommonAnnotations.summary }}"
        text: "{{ .CommonAnnotations.description }}\nValue: {{ .CommonAnnotations.value }}\nDashboard: {{ .CommonAnnotations.dashboard_url }}\nRunbook: {{ .CommonAnnotations.runbook_url }}"
  - name: 'slack-notifications-critical'
    slack_configs:
      - channel: '#devops-alerts'
        send_resolved: true
        title: "{{ .CommonAnnotations.summary }}"
        text: "{{ .CommonAnnotations.description }}\nValue: {{ .CommonAnnotations.value }}\nDashboard: {{ .CommonAnnotations.dashboard_url }}\nRunbook: {{ .CommonAnnotations.runbook_url }}"

inhibit_rules:
  - source_match:
      alertname: 'ServerDown'
    target_match_re:
      alertname: 'CPU.*|Memory.*|Disk.*|SLO.*'
    equal: ['instance']