FROM alpine:latest

# 1. 安裝核心組件、sing-box 以及輕量網頁伺服器 caddy
RUN apk add --no-cache ca-certificates curl bash unzip openssl caddy \
    && curl -Lo /tmp/sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.10.7/sing-box-1.10.7-linux-amd64.tar.gz \
    && mkdir -p /tmp/sb && tar -xzf /tmp/sb.tar.gz -C /tmp/sb --strip-components=1 \
    && mv /tmp/sb/sing-box /usr/local/bin/ && chmod +x /usr/local/bin/sing-box \
    && rm -rf /tmp/sb*

# 2. 建立目錄並生成自簽 TLS 憑證
RUN mkdir -p /etc/sing-box && openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/sing-box/server.key -out /etc/sing-box/server.key \
    -days 3650 -subj "/CN=hysteria2-docker.onrender.com"

# 3. 寫入 Hysteria 2 配置文件 (監聽內部 10001 埠)
RUN echo '{"log":{"level":"warn"},"inbounds":[{"type":"hysteria2","listen":"0.0.0.0","listen_port":10001,"users":[{"password":"Ronald9988"}],"tls":{"enabled":true,"certificate_path":"/etc/sing-box/server.key","key_path":"/etc/sing-box/server.key"}}],"outbounds":[{"type":"direct"}]}' > /etc/sing-box/config.json

# 4. 建立一個簡單的偽裝網頁，並讓 Caddy 監聽 Render 預設的 10000 埠
RUN mkdir -p /usr/share/caddy && echo "<h1>Hello World</h1>" > /usr/share/caddy/index.html

EXPOSE 10000

# 5. 同時啟動網頁（應付 Render 檢查）以及 sing-box（核心代理）
ENTRYPOINT ["sh", "-c", "caddy file-server --listen :10000 --root /usr/share/caddy & sing-box run -c /etc/sing-box/config.json"]
