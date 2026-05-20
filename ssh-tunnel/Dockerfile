FROM alpine:latest

RUN apk add --no-cache openssh-client

# SSH key will be mounted at runtime
RUN mkdir -p /root/.ssh && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "ServerAliveInterval 30" >> /etc/ssh/ssh_config && \
    echo "ServerAliveCountMax 3" >> /etc/ssh/ssh_config

# Keep tunnel alive with a loop
CMD sh -c 'while true; do \
    ssh -N \
      -L 0.0.0.0:9100:localhost:9100 \
      -i /root/.ssh/id_rsa \
      -o StrictHostKeyChecking=no \
      -o ServerAliveInterval=30 \
      -o BatchMode=yes \
      ${SSH_USER}@${SSH_HOST}; \
    echo "Tunnel disconnected, retrying in 5s..."; \
    sleep 5; \
  done'
