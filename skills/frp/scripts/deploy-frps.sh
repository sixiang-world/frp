#!/usr/bin/env bash
# deploy-frps.sh — 一键部署 frps 服务端
# 用法: sudo bash deploy-frps.sh [version] [bind_port]
#   默认 version=0.69.1, bind_port=7000
#
# 前置条件: Linux VPS, wget, sudo, systemd
set -euo pipefail

VERSION="${1:-0.69.1}"
BIND_PORT="${2:-7000}"
FRP_DIR="/usr/local/frp"
CONF_DIR="/etc/frp"
LOG_DIR="/var/log"
SERVICE_NAME="frps"

# 检测架构
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_STR="linux_amd64" ;;
    aarch64) ARCH_STR="linux_arm64" ;;
    armv7l)  ARCH_STR="linux_arm" ;;
    mips|mips64) ARCH_STR="linux_mipsle" ;;
    *)
        echo "❌ 不支持的架构: $ARCH"
        exit 1
        ;;
esac

echo "=== FRP Server 部署 ==="
echo "版本: $VERSION"
echo "架构: $ARCH_STR"
echo "绑定端口: $BIND_PORT"

# Step 1: 下载
DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_${ARCH_STR}.tar.gz"
echo "📥 下载: $DOWNLOAD_URL"
wget -q --show-progress "$DOWNLOAD_URL" -O "/tmp/frp_${VERSION}_${ARCH_STR}.tar.gz"
tar xzf "/tmp/frp_${VERSION}_${ARCH_STR}.tar.gz" -C /tmp/
sudo mv "/tmp/frp_${VERSION}_${ARCH_STR}" "$FRP_DIR"
echo "✅ 已安装到 $FRP_DIR"

# Step 2: 配置
sudo mkdir -p "$CONF_DIR"
sudo tee "$CONF_DIR/frps.toml" > /dev/null <<FRPCONF
bindPort = $BIND_PORT

auth.method = "token"
auth.token = ""

webServer.addr = "127.0.0.1"
webServer.port = 7500
webServer.user = "admin"
webServer.password = ""

allowPorts = [
  { start = 6000, end = 6100 }
]

log.to = "$LOG_DIR/frps.log"
log.level = "info"
log.maxDays = 7
FRPCONF

# Token 提示
echo "⚠️  请编辑 $CONF_DIR/frps.toml，设置 auth.token 和 webServer.password"

# Step 3: systemd 服务
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<SERVICEEOF
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=${FRP_DIR}/${SERVICE_NAME} -c ${CONF_DIR}/frps.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# Step 4: 验证
sleep 2
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✅ frps 服务运行中"
    ss -tlnp | grep "$BIND_PORT" || echo "⚠️  端口 $BIND_PORT 未监听，检查防火墙"
else
    echo "❌ frps 启动失败，日志如下:"
    sudo journalctl -u "$SERVICE_NAME" --no-pager -n 20
    exit 1
fi

echo ""
echo "=== 部署完成 ==="
echo "配置文件: $CONF_DIR/frps.toml"
echo "启动命令: sudo systemctl start frps"
echo "查看日志: sudo journalctl -u frps -f"
echo "访问 Dashboard: ssh -L 7500:127.0.0.1:7500 user@<vps-ip>"
echo "                 然后浏览器打开 http://127.0.0.1:7500"
echo ""
echo "🔴 下一步: 编辑 auth.token(≥32字符) 和 webServer.password，然后 sudo systemctl restart frps"
