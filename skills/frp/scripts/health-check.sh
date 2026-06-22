#!/usr/bin/env bash
# health-check.sh — FRP 健康检查
# 用法: bash health-check.sh [server_ip] [control_port]
#   默认 server_ip 从 /etc/frp/frpc.toml 读取
#   默认 control_port=7000
set -euo pipefail

# 尝试从 frpc 配置读取服务端地址
FRPC_CONF="/etc/frp/frpc.toml"
if [ -f "$FRPC_CONF" ]; then
    SERVER_ADDR=$(grep -oP 'serverAddr\s*=\s*"\K[^"]+' "$FRPC_CONF" 2>/dev/null || echo "")
    SERVER_PORT=$(grep -oP 'serverPort\s*=\s*\K\d+' "$FRPC_CONF" 2>/dev/null || echo "")
fi

SERVER_IP="${1:-${SERVER_ADDR:-127.0.0.1}}"
CONTROL_PORT="${2:-${SERVER_PORT:-7000}}"

echo "=== FRP 健康检查 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查进程
echo "--- 进程状态 ---"
if pgrep -x frps > /dev/null 2>&1; then
    echo "✅ frps 运行中"
else
    echo "❌ frps 未运行"
fi
if pgrep -x frpc > /dev/null 2>&1; then
    FRPC_PID=$(pgrep -x frpc)
    FRPC_RUNTIME=$(ps -o etime= -p "$FRPC_PID" 2>/dev/null | xargs)
    echo "✅ frpc 运行中 (PID $FRPC_PID, 运行时间 $FRPC_RUNTIME)"
else
    echo "❌ frpc 未运行"
fi
echo ""

# 2. 端口监听
echo "--- 端口监听 ---"
if ss -tlnp 2>/dev/null | grep -q "$CONTROL_PORT"; then
    echo "✅ 控制端口 $CONTROL_PORT 已监听"
    ss -tlnp | grep "$CONTROL_PORT"
else
    echo "⚠️  控制端口 $CONTROL_PORT 未监听"
fi
echo ""

# 3. 公网可达性
echo "--- 公网可达性 ---"
if [ "$SERVER_IP" != "127.0.0.1" ] && timeout 5 nc -zv "$SERVER_IP" "$CONTROL_PORT" 2>/dev/null; then
    echo "✅ $SERVER_IP:$CONTROL_PORT 可达"
else
    case "$SERVER_IP" in
        127.0.0.1|localhost)
            echo "ℹ️  本地检查，跳过公网可达性测试"
            ;;
        *)
            echo "❌ $SERVER_IP:$CONTROL_PORT 不可达（检查防火墙）"
            ;;
    esac
fi
echo ""

# 4. 日志检查
echo "--- 日志状态 ---"
LOG_FILES=("/var/log/frps.log" "/var/log/frpc.log")
for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        LAST_LINE=$(tail -1 "$log" 2>/dev/null | head -c 100)
        echo "📄 $log (最后更新: $(stat -c '%y' "$log" 2>/dev/null | cut -d. -f1))"
        echo "   最后一行: $LAST_LINE"
    fi
done
echo ""

# 5. 资源使用
echo "--- 资源使用 ---"
if pgrep -x frps > /dev/null; then
    ps -o pid,rss,%mem,%cpu,etime -p "$(pgrep -x frps | head -1)" 2>/dev/null | tail -1 | awk '{print "frps: RSS="$2"KB, MEM="$3"%, CPU="$4"%"}'
fi
if pgrep -x frpc > /dev/null; then
    ps -o pid,rss,%mem,%cpu,etime -p "$(pgrep -x frpc | head -1)" 2>/dev/null | tail -1 | awk '{print "frpc: RSS="$2"KB, MEM="$3"%, CPU="$4"%"}'
fi

echo ""
echo "=== 检查完成 ==="
