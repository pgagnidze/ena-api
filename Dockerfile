FROM nickblah/luajit:2.1-luarocks-alpine

WORKDIR /app

RUN apk add --no-cache git gcc musl-dev linux-headers \
    && luarocks install mote \
    && luarocks install ena \
    && apk del git gcc musl-dev linux-headers

COPY main.lua .

EXPOSE 8080

CMD ["luajit", "main.lua"]
