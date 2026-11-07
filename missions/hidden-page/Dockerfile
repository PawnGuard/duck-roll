FROM nginx:1.28-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html
COPY robots.txt /usr/share/nginx/html/robots.txt

USER 101:101

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]

EXPOSE 8080
