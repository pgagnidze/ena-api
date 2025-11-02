FROM openresty/openresty:alpine-fat

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY compile.lua /etc/nginx/lua/compile.lua

RUN apk add --no-cache git gcc musl-dev \
    && luarocks install ena \
    && luarocks install lua-cjson \
    && apk del git gcc musl-dev

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
