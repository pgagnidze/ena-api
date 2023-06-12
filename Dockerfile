FROM openresty/openresty:jammy

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY compile.lua /etc/nginx/lua/compile.lua

RUN apt-get update && apt-get install -y git gcc && luarocks install ena && luarocks install lua-cjson

EXPOSE 8080

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
