# O build web (flutter build web) é feito no GitHub Actions; aqui só empacotamos os arquivos estáticos.
FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
EXPOSE 8080
