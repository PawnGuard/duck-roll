FROM nginx:1.28-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY site/ /usr/share/nginx/html/
COPY incident-dashboard.html.template /usr/local/share/hidden-page/incident-dashboard.html.template
COPY start.sh /usr/local/bin/hidden-page-start

USER 101:101

ENTRYPOINT ["/bin/sh", "/usr/local/bin/hidden-page-start"]

EXPOSE 8080
