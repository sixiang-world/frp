#!/usr/bin/env bash
# gen-tls-certs.sh — 生成 FRP 自签名 TLS 证书
# 用法: bash gen-tls-certs.sh [输出目录] [域名]
#   默认输出目录: ./frp-tls
#   默认域名: frps.example.com
#
# 生成文件:
#   ca.key / ca.crt — CA 密钥和证书
#   server.key / server.crt — 服务端密钥和证书
set -euo pipefail

OUT_DIR="${1:-./frp-tls}"
DOMAIN="${2:-frps.example.com}"

mkdir -p "$OUT_DIR"
echo "📁 输出目录: $(realpath "$OUT_DIR")"
echo "🔑 域名: $DOMAIN"

# 生成 CA
openssl genrsa -out "$OUT_DIR/ca.key" 2048
openssl req -new -x509 -days 3650 -key "$OUT_DIR/ca.key" -out "$OUT_DIR/ca.crt" -subj "/CN=FRP CA"
echo "✅ CA 证书: $OUT_DIR/ca.crt"

# 生成服务端证书
openssl genrsa -out "$OUT_DIR/server.key" 2048
openssl req -new -key "$OUT_DIR/server.key" -out "$OUT_DIR/server.csr" -subj "/CN=$DOMAIN"
openssl x509 -req -days 365 -in "$OUT_DIR/server.csr" -CA "$OUT_DIR/ca.crt" -CAkey "$OUT_DIR/ca.key" -CAcreateserial -out "$OUT_DIR/server.crt"

chmod 600 "$OUT_DIR/server.key"
echo "✅ 服务端证书: $OUT_DIR/server.crt"
echo "✅ 服务端密钥: $OUT_DIR/server.key"

echo ""
echo "=== 部署指南 ==="
echo ""
echo "1. 复制到 frps:"
echo "   sudo mkdir -p /etc/frp/tls"
echo "   sudo cp $OUT_DIR/server.crt $OUT_DIR/server.key $OUT_DIR/ca.crt /etc/frp/tls/"
echo "   sudo chmod 600 /etc/frp/tls/server.key"
echo ""
echo "2. frps 配置 (/etc/frp/frps.toml):"
echo "   transport.tls.force = true"
echo "   transport.tls.certFile = \"/etc/frp/tls/server.crt\""
echo "   transport.tls.keyFile = \"/etc/frp/tls/server.key\""
echo ""
echo "3. frpc 配置 (/etc/frp/frpc.toml):"
echo "   transport.tls.enable = true"
echo "   transport.tls.trustedCaFile = \"/etc/frp/tls/ca.crt\""
echo ""
echo "4. 重启服务:"
echo "   sudo systemctl restart frps"
echo "   sudo systemctl restart frpc"
