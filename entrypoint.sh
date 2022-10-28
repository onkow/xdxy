#!/bin/sh

# start
tor &
xray -config /etc/xray/config.json &
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile