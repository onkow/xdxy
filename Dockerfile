FROM golang:alpine AS caddy
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    xcaddy build latest

FROM golang:alpine AS xray
RUN apk update && apk add --no-cache git
WORKDIR /go/src/xray/core
RUN git clone --progress https://github.com/XTLS/Xray-core.git . && \
    go mod download && \
    CGO_ENABLED=0 go build -o /tmp/xray -trimpath -ldflags "-s -w -buildid=" ./main


FROM alpine:latest

ARG AUUID="7bf357e0-5f10-4afb-a2e5-bc0cee0fc6de"
ARG CADDYIndexPage="https://github.com/AYJCSGM/mikutap/archive/master.zip"
ARG ParameterSSENCYPT="chacha20-ietf-poly1305"
ENV PORT 

COPY --from=xray /tmp/xray /usr/bin
COPY --from=caddy /go/caddy /usr/bin
COPY conf /conf/
COPY entrypoint.sh /usr/bin

RUN apk update && \
    apk add --no-cache ca-certificates tor && \
    chmod +x /usr/bin/xray && \
    chmod +x /usr/bin/caddy && \
    chmod +x /usr/bin/entrypoint.sh && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /etc/caddy/ /usr/share/caddy && echo -e "User-agent: *\nDisallow: /" >/usr/share/caddy/robots.txt \
    && wget $CADDYIndexPage -O /usr/share/caddy/index.html && unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ && mv /usr/share/caddy/*/* /usr/share/caddy/ \
    && cat /conf/Caddyfile | sed -e "1c :$PORT" -e "s/\$AUUID/$AUUID/g" -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" >/etc/caddy/Caddyfile \
    && mkdir -p /etc/xray /usr/share/xray \
    && wget -O /usr/share/xray/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat \
    && wget -O /usr/share/xray/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat \
    && cat /conf/xray.json | sed -e "s/\$AUUID/$AUUID/g" -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" >/etc/xray/config.json
	
	
CMD /usr/bin/entrypoint.sh	
