# 完整部署参考

> 本文件包含 frps 服务端和 frpc 客户端在各平台的完整部署步骤。
> 快速上手用 SKILL.md 2.1-2.2 节，本节为完整的逐行参考。

---

## 服务端部署（Linux VPS）

### 前置条件

- 一台有公网 IP 的 Linux VPS（Ubuntu 20.04+ / CentOS 7+ / Debian 11+）
- 架构确认：`arch` 或 `uname -m`
  - `x86_64` → `linux_amd64`
  - `aarch64` → `linux_arm64`

### Step 1：下载并安装

```bash
# 确认最新版本号：https://github.com/fatedier/frp/releases
# 当前稳定版 v0.69.1
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz
tar xzf frp_0.69.1_linux_amd64.tar.gz
sudo mv frp_0.69.1_linux_amd64 /usr/local/frp
```

ARM64（树莓派等）替换为 `frp_0.69.1_linux_arm64.tar.gz`。
MIPS（路由器）替换为 `frp_0.69.1_linux_mipsle.tar.gz`。

### Step 2：配置文件

```bash
sudo mkdir -p /etc/frp
sudo cp /usr/local/frp/frps.toml /etc/frp/
```

编辑 `/etc/frp/frps.toml`：

```toml
bindPort = 7000
auth.method = "token"
auth.token = "your-strong-token-here-32chars-min"
webServer.addr = "127.0.0.1"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "change-this-password-now"
allowPorts = [
  { start = 6000, end = 6100 }
]
log.to = "/var/log/frps.log"
log.level = "info"
log.maxDays = 7
```

完整配置示例见 `conf/frps_full_example.toml`（169 行）。

### Step 3：systemd 服务

```bash
sudo tee /etc/systemd/system/frps.service > /dev/null << 'EOF'
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/frps -c /etc/frp/frps.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frps
sudo systemctl start frps
```

> **关于用户**：禁止以 root 运行 frps！`User=nobody` 已是最小权限。
> 如果系统没有 `nobody` 用户（如 Debian），改为 `User=frp` 并创建专属用户：
> ```bash
> sudo useradd --system --no-create-home --shell /usr/sbin/nologin frp
> sudo chown -R frp:frp /etc/frp
> ```

### Step 4：验证

```bash
sudo systemctl status frps
# 应输出 Active: active (running)

sudo tail -30 /var/log/frps.log
# 应包含 "frps started successfully"

ss -tlnp | grep 7000
# 应显示 LISTEN 状态的 frps 进程
```

**失败处理：**
- `ss` 无 7000 端口 → 防火墙未放行
- `permission denied` → `/etc/frp/` 权限不足（需 `chmod 644`）
- `exec format error` → 架构不对，用 `arch` 确认后重下

---

## 客户端部署

### Linux 客户端

```bash
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz
tar xzf frp_0.69.1_linux_amd64.tar.gz
sudo mv frp_0.69.1_linux_amd64 /usr/local/frp
```

配置 `/etc/frp/frpc.toml`：

```toml
serverAddr = "your-vps-public-ip"
serverPort = 7000
auth.token = "your-strong-token-here-32chars-min"

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

systemd 服务：

```bash
sudo tee /etc/systemd/system/frpc.service > /dev/null << 'EOF'
[Unit]
Description=FRP Client
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/frp/frpc -c /etc/frp/frpc.toml
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frpc
sudo systemctl start frpc
```

验证：

```bash
sudo systemctl status frpc
sudo journalctl -u frpc --no-pager -n 20
# 应出现 "login to server success"
```

### macOS 客户端

```bash
# Homebrew 安装（推荐）
brew install frp

# 或手动下载
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_darwin_amd64.tar.gz
tar xzf frp_0.69.1_darwin_amd64.tar.gz
sudo mv frp_0.69.1_darwin_amd64 /usr/local/frp
```

开机自启（launchd）：

```bash
sudo tee /Library/LaunchDaemons/com.frp.frpc.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.frp.frpc</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/frp/frpc</string>
        <string>-c</string>
        <string>/etc/frp/frpc.toml</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/frpc.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/frpc.log</string>
</dict>
</plist>
EOF

sudo launchctl load -w /Library/LaunchDaemons/com.frp.frpc.plist
```

### Windows 客户端

1. 下载 `frp_0.69.1_windows_amd64.zip` 解压到 `C:\Program Files\frp\`
2. 创建 `C:\Program Files\frp\frpc.toml`（配置与 Linux 相同）
3. 创建 `frpc-server.bat`：

```batch
@echo off
"C:\Program Files\frp\frpc.exe" -c "C:\Program Files\frp\frpc.toml"
```

4. 通过「任务计划程序」设置开机启动（触发器：系统启动，操作：启动程序指向 frpc.exe）

> **注意**：Windows Defender 可能拦截 frpc。在安全中心添加排除项：`C:\Program Files\frp\` 目录。

### Docker 客户端

```bash
docker run -d --restart=always \
  --name frpc \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  --network host \
  snowdreamtech/frpc:0.69.1
```

> Docker Desktop（macOS/Windows）不支持 `--network host`，需改为端口映射。

验证：`docker logs frpc --tail 20` 应出现 `login to server success`。

---

## 部署检查清单

- [ ] frps 进程运行中（`systemctl status frps`）
- [ ] 控制端口 7000 监听（`ss -tlnp | grep 7000`）
- [ ] 控制端口公网可达（`nc -zv <vps-ip> 7000`）
- [ ] frpc 已登录成功（日志含 `login to server success`）
- [ ] 代理已注册成功（日志含 `start proxy success`）
- [ ] 实际应用层可用（`ssh -p 6000 user@vps-ip` 可连接到内网）
- [ ] Token + TLS 已开启（文件注脚见 `references/security.md`）
- [ ] Dashboard 绑定 127.0.0.1（非 0.0.0.0）
- [ ] allowPorts 已限制范围
- [ ] frps/frpc 非 root 运行（`ps aux | grep frp` 确认用户）
