ARG IMAGE_TAG=3.20.3
FROM alpine:${IMAGE_TAG}

RUN apk add --no-cache openssh-server shadow \
    && adduser -D -s /bin/sh hydra \
    && adduser -D -s /bin/sh operator \
    && mkdir -p /etc/ssh /home/operator/.ssh /run/sshd \
    && chown -R operator:operator /home/operator/.ssh \
    && chmod 700 /home/operator/.ssh \
    && ssh-keygen -A \
    && printf '%s\n' \
      'PasswordAuthentication yes' \
      'KbdInteractiveAuthentication no' \
      'PermitRootLogin no' \
      'AllowUsers hydra operator' \
      >> /etc/ssh/sshd_config

COPY entrypoint.sh /usr/local/bin/hydras-entrypoint
RUN chmod 755 /usr/local/bin/hydras-entrypoint

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/hydras-entrypoint"]
