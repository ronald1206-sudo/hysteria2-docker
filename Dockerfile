FROM alpine:latest

# 1. 安裝核心組件與最新穩定版 sing-box
RUN apk add --no-cache ca-certificates curl bash unzip openssl \
    && curl -Lo /tmp/sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.10.7/sing-box-1.10.7-linux-amd64.tar.gz \
    && mkdir -p /tmp/sb && tar -xzf /tmp/sb.tar.gz -C /tmp/sb --strip-components=1 \
    && mv /tmp/sb/sing-box /usr/local/bin/ && chmod +x /usr/local/bin/sing-box \
    && rm -rf /tmp/sb*

# 2. 建立目錄並生成自簽 TLS 憑證
RUN mkdir -p /etc/sing-box && openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout /etc/sing-box/server.key -out /etc/sing-box/server.crt \
    -days 3650 -subj "/CN=render-hy2.onrender.com"

# 3. 寫入正宗 sing-box 最新標準的 Hysteria 2 配置文件 (監聽 Render 默認的 10000 端口)
RUN echo '{"log":{"level":"warn"},"inbounds":[{"type":"hysteria2","listen":"0.0.0.0","listen_port":10000,"users":[{"password":"Ronald9988"}],"tls":{"enabled":true,"certificate_path":"/etc/sing-box/server.crt","key_path":"/etc/sing-box/server.key"}}],"outbounds":[{"type":"direct"}]}' > /etc/sing-box/config.json

EXPOSE 10000
# 確保容器一啟動就立刻執行 sing-box 服務
ENTRYPOINT ["/usr/local/bin/sing-box", "run", "-c", "/etc/sing-box/config.json"]
