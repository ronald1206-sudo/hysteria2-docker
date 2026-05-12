FROM alpine:latest

# 1. 安裝核心組件、sing-box 以及輕量網頁伺服器 caddy
RUN apk add --no-cache ca-certificates curl bash unzip openssl caddy \
    && curl -Lo /tmp/sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.10.7/sing-box-1.10.7-linux-amd64.tar.gz \
    && mkdir -p /tmp/sb && tar -xzf /tmp/sb.tar.gz -C /tmp/sb --strip-components=1 \
    && mv /tmp/sb/sing-box /usr/local/bin/ && chmod +x /usr/local/bin/sing-box \
    && rm -rf /tmp/sb*

# 2. 建立目錄並寫入 sing-box 的 VLESS+WS 配置文件 (監聽內部 10001 埠)
# 這裡內置了一個固定 UUID：66666666-6666-6666-6666-666666666666
RUN mkdir -p /etc/sing-box && echo '{"log":{"level":"warn"},"inbounds":[{"type":"vless","listen":"127.0.0.1","listen_port":10001,"users":[{"id":"66666666-6666-6666-6666-666666666666"}],"vless_vless_transport_over_websocket":{"enabled":true,"path":"/ronald-vless"}}],"outbounds":[{"type":"direct"}]}' > /etc/sing-box/config.json

# 3. 建立偽裝網頁
RUN mkdir -p /usr/share/caddy && echo "<h1>Welcome to my Personal Site</h1>" > /usr/share/caddy/index.html

# 4. 寫入 Caddyfile：讓 Caddy 監聽 Render 預設的 10000 埠
# 普通流量看網頁，當路徑匹配到 /ronald-vless 且是 WebSocket 時，自動轉發給 sing-box
RUN echo -e ":10000 {\n root * /usr/share/caddy\n file_server\n @proxy {\n header Connection *Upgrade*\n header Upgrade websocket\n path /ronald-vless\n }\n reverse_proxy @proxy 127.0.0.1:10001\n}" > /etc/Caddyfile

EXPOSE 10000

# 5. 同步啟動 Caddy（應付 Render 埠掃描）和 sing-box（核心代理）
ENTRYPOINT ["sh", "-c", "caddy run --config /etc/Caddyfile & sing-box run -c /etc/sing-box/config.json"]
