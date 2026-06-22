---
name: frp
description: >
  FRP 内网穿透全栈技能 — frps 服务端部署、frpc 客户端配置、安全加固、故障排查。
  当用户提到「内网穿透」「frp」「frps/frpc」「暴露本地服务」「远程访问内网」
  「端口转发」「NAT穿透」「反向代理内网」「穿透公司内网」「访问家里服务」
  「将内网服务映射到公网」时触发。
  覆盖场景：SSH 远程管理、HTTP/HTTPS 网站暴露、TCP/UDP 端口映射、
  P2P 直连、Dashboard 监控、多客户端管理。
compatibility: Requires Linux VPS for frps; client works on Linux/macOS/Windows.
priority: high
---

# FRP — Fast Reverse Proxy

## TL;DR 一句话

FRP 是一个**自托管**的内网穿透反向代理工具。你在公网 VPS 上运行 frps（服务端），内网机器运行 frpc（客户端），frpc 注册隧道后，公网即可通过 VPS 的 IP+端口访问内网服务。

**5 个动作速查：**

| 目标 | 命令/配置 |
|---|---|
| 服务端下载并解压 | `wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz && tar xzf frp_0.69.1_linux_amd64.tar.gz` |
| 服务端最小配置 | `bindPort = 7000`（写入 `/etc/frp/frps.toml`） |
| 启动服务端 | `./frps -c /etc/frp/frps.toml` |
| 客户端最小配置 | `serverAddr = "your-vps-ip" \n serverPort = 7000 \n [[proxies]] \n name = "ssh" \n type = "tcp" \n localIP = "127.0.0.1" \n localPort = 22 \n remotePort = 6000` |
| 启动客户端 | `./frpc -c /etc/frp/frpc.toml` |

---

## 1. 理解原理

### 1.1 架构

```
公网用户                         VPS (frps)                      内网机器 (frpc)
   │                               │                                │
   │  ───── 访问 vps:6000 ────►   │                                │
   │                               │  ─── 转发到 frpc 隧道 ────►   │
   │                               │                                │ ──► localhost:22
   │                               │                                │     (SSH 服务)
```

- **控制连接**：frpc → frps 建立一条长连接，用于心跳、认证、配置同步
- **数据连接**：用户请求到达 frps 后，通过控制连接触发 frpc 建立一条新数据连接（或复用已有连接池里的连接），流量经由此连接转发到本地服务
- **frps 是中转节点**，不是代理服务器（与 nginx 不同），它不缓存、不解析应用层协议，纯四层流量转发

### 1.2 适用场景表

| 场景 | 推荐代理类型 | 说明 |
|---|---|---|
| SSH 远程管理 | TCP | 最基础场景，一行配置即可 |
| HTTP 网站 | HTTP | 支持域名路由、VirtualHost、BasicAuth |
| HTTPS 服务 | HTTPS / TCP | 在 frps 终止 TLS 或直通 |
| 数据库远程连接 | TCP | MySQL/PostgreSQL/Redis 等 |
| UDP 服务（DNS、游戏） | UDP | 注意 UDP 包大小一致（1500 默认） |
| P2P 直连（不经过服务器） | STCP / XTCP | 流量不经 VPS，适合大带宽传输 |
| RDP 远程桌面 | TCP | 配合 rdp 协议类型 |
| SMB 文件共享 | STCP | 安全性高，仅授权访问 |
| 本地服务组合暴露 | TCP + HTTP | 多个服务复用同一个 frpc |

### 1.3 同类对比表

| 特性 | FRP | Ngrok | Cloudflare Tunnel | Tailscale |
|---|---|---|---|---|
| 部署模式 | 自托管 | SaaS | SaaS（需域名） | P2P Mesh |
| 需要公网 IP | 是（VPS） | 否（ngrok 提供） | 否（CF 边缘节点） | 需要至少一台节点出站 |
| TCP/UDP 转发 | 完整支持 | TCP+HTTP | HTTP/SSH 为主 | 全协议（WireGuard） |
| HTTP 域名路由 | 支持 | 支持 | 原生 CDN | 不适用 |
| P2P 直连 | 支持（XTCP） | 不提供 | 不提供 | 原生 |
| 认证方式 | Token/OIDC/TLS | OAuth/Basic | Cloudflare Access | 基于密钥 |
| 开源 | 完全开源 | 核心闭源 | 开源 tunnel 组件 | 部分开源 |
| 配置复杂度 | 中高 | 低 | 中 | 低 |
| 传输加密 | 可选（TLS） | 默认 | 自动 | 自动 |
| 数据隔离 | 完全 | 共享 | 共享 | 点对点 |

**定位结论**：FRP 是唯一**完全自托管**、**支持全协议**、**可精细控制安全边界**的内网穿透方案。适合对数据主权、网络拓扑、安全策略有严格要求的团队或个人。

---

## 2. 快速部署

### 2.1 服务端（Linux VPS）

> **前置条件**：一台有公网 IP 的 Linux VPS（Ubuntu 20.04+ / CentOS 7+ / Debian 11+）

**Step 1：下载并解压**

```bash
# v0.69.1（最新稳定版，2026-06-01）
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz
tar xzf frp_0.69.1_linux_amd64.tar.gz
sudo mv frp_0.69.1_linux_amd64 /usr/local/frp
```

ARM64（树莓派等）替换为 `frp_0.69.1_linux_arm64.tar.gz`。
MIPS（路由器）替换为 `frp_0.69.1_linux_mipsle.tar.gz`。
完整列表见 [Releases](https://github.com/fatedier/frp/releases)。

**Step 2：创建配置文件**

```bash
sudo mkdir -p /etc/frp
sudo cp /usr/local/frp/frps.toml /etc/frp/
```

编辑 `/etc/frp/frps.toml`，写入最小配置（完整示例见 `conf/frps_full_example.toml`）：

```toml
# /etc/frp/frps.toml
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

> `webServer.addr = "127.0.0.1"` 确保 Dashboard 不暴露在公网，通过 SSH 隧道访问。

**Step 3：创建 systemd 服务**

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
> 如果系统没有 `nobody` 用户或用 Debian，改为 `User=frp` 并创建专属用户。

**Step 4：验证运行状态**

```bash
sudo systemctl status frps
# 输出应有 Active: active (running)

# 查看日志
sudo tail -30 /var/log/frps.log
# 应包含 "frps started successfully" 字样

# 检查端口监听
ss -tlnp | grep 7000
# 应显示 LISTEN 状态的 frps 进程
```

> 如果 `ss -tlnp` 没有输出 7000 端口：检查防火墙是否放行了端口。
> 如果 journal 报 `permission denied`：检查 `/etc/frp/frps.toml` 权限（需 `chmod 644`），或 `User=nobody` 是否有权写入 log.to 路径。
> 如果 systemd 报 `exec format error`：下载的二进制架构不对，用 `arch` 命令确认系统架构后重新下载对应版本。

**🔴 CHECKPOINT：服务端部署完成。**
验证以上命令输出，确认 frps 正在运行、Dashboard URL 可用（见下），然后继续客户端部署。

**访问 Dashboard：** Dashboard 绑定在 `127.0.0.1:7500`，通过 SSH 隧道访问：

```bash
# 在本地机器执行
ssh -L 7500:127.0.0.1:7500 user@your-vps-ip
# 然后浏览器打开 http://127.0.0.1:7500
```

如果希望快捷查看，改用 `curl`：

```bash
# 获取服务端状态
curl -u admin:strong-password http://127.0.0.1:7500/api/serverinfo
# 查看所有代理（按类型 tcp/udp/http/stcp/xtcp）
curl -u admin:strong-password http://127.0.0.1:7500/api/proxy/tcp
# 查看已连接的客户端
curl -u admin:strong-password http://127.0.0.1:7500/api/clients
```

---

### 2.2 客户端（Linux / macOS / Windows / Docker）

#### Linux 客户端

**安装：**

```bash
# 架构确认同服务端保持一致
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz
tar xzf frp_0.69.1_linux_amd64.tar.gz
sudo mv frp_0.69.1_linux_amd64 /usr/local/frp
```

**配置 `/etc/frp/frpc.toml`：**

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

**systemd 服务：**

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

**验证：**

```bash
sudo systemctl status frpc
# 查看日志确认连接成功
sudo journalctl -u frpc --no-pager -n 20
# 日志应出现 "login to server success"
```

#### macOS 客户端

```bash
# Homebrew 安装（推荐）
brew install frp

# 或手动下载
wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_darwin_amd64.tar.gz
tar xzf frp_0.69.1_darwin_amd64.tar.gz
sudo mv frp_0.69.1_darwin_amd64 /usr/local/frp

# 使用 launchd 实现开机自启
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

#### Windows 客户端

1. 下载 `frp_0.69.1_windows_amd64.zip` 并解压到 `C:\Program Files\frp\`
2. 创建 `C:\Program Files\frp\frpc.toml`（配置与 Linux 相同）
3. 创建 `frpc-server.bat`：

```batch
@echo off
"C:\Program Files\frp\frpc.exe" -c "C:\Program Files\frp\frpc.toml"
```

4. 通过「任务计划程序」设置开机启动（触发器：系统启动，操作：启动程序指向 frpc.exe）

> **注意**：Windows Defender 可能拦截 frpc 作为恶意软件。在安全中心添加排除项：`C:\Program Files\frp\` 目录。

#### Docker 客户端

```bash
# 使用官方镜像
docker run -d --restart=always \
  --name frpc \
  -v /etc/frp/frpc.toml:/etc/frp/frpc.toml \
  --network host \
  snowdreamtech/frpc:0.69.1
```

> Docker 方案需要使用 `--network host`（Linux）或映射端口；如果使用 Docker Desktop（macOS/Windows），`--network host` 不可用，需改为端口映射。

**验证 Docker 客户端：**

```bash
docker logs frpc --tail 20
# 应出现 "login to server success"
```

**🔴 CHECKPOINT：客户端部署完成。**
联系验证：在客户端机器执行 `ssh -p 6000 user@your-vps-ip`，如果能 SSH 到内网机器的 localhost:22，则管道打通。

> **失败处理**：
> - `ssh: connect to host your-vps-ip port 6000: Connection refused` → frps 未在监听 6000 或防火墙未放行 6000
> - `ssh: Connection closed` → frpc 正常连接了但本地 SSH 服务拒绝 → 检查 frpc 所在机器的 `sshd` 是否在 22 端口运行
> - `Permission denied` → SSH 认证失败，与 frp 无关，检查 SSH 密钥或密码

---

## 3. 核心配置详解

### 3.1 全局配置字段

本节涉及的所有完整配置示例位于源码 `conf/` 目录下：

| 字段 | 位置 | 说明 | 默认值 |
|---|---|---|---|
| `serverAddr` | frpc | 服务端 IP 或域名 | 必填 |
| `serverPort` | frpc | 服务端绑定端口 | 必填 |
| `bindPort` | frps | 服务端监听端口 | 必填 |
| `auth.token` | 两端 | 认证令牌 | 必填（生产） |
| `auth.method` | 两端 | `"token"` 或 `"oidc"` | `"token"` |
| `log.to` | 两端 | 日志路径或 `"console"` | `"console"` |
| `log.level` | 两端 | `trace/debug/info/warn/error` | `"info"` |
| `log.maxDays` | 两端 | 日志保留天数 | 3 |

完整参考：`conf/frps_full_example.toml`（169 行）和 `conf/frpc_full_example.toml`（469 行）。

### 3.2 代理类型详解

每种代理类型使用 `conf/` 中的真实示例作为引用。

#### TCP 代理 — SSH / 数据库 / RDP

文件参考：`conf/frpc.toml`（最小示例）和 `conf/frpc_full_example.toml` lines 181-220。

```toml
[[proxies]]
name = "mysql"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3306
remotePort = 6001
transport.useEncryption = true
transport.useCompression = false
loadBalancer.group = "db_cluster"
loadBalancer.groupKey = "db_key_123"
healthCheck.type = "tcp"
healthCheck.timeoutSeconds = 3
healthCheck.maxFailed = 3
healthCheck.intervalSeconds = 10
```

**关键字段：**

- `remotePort`：frps 监听在这个端口，外部连接 `vps-ip:remotePort` 即可访问本地服务
- `remotePort = 0`：frps 随机分配一个可用端口，通过 Dashboard 或 API 查看
- `transport.useEncryption = true`：传输层加密，打开后即使有 TLS 连接层加密，双层加密更安全
- `loadBalancer.group`：同组内多个 frpc 实例将收到轮询分发（负载均衡）
- `healthCheck`：frpc 定期检查本地服务健康，检测到故障后从 frps 移除该代理

#### UDP 代理 — DNS / 游戏服务器

文件参考：`conf/frpc_full_example.toml` lines 230-235。

```toml
[[proxies]]
name = "dns"
type = "udp"
localIP = "114.114.114.114"
localPort = 53
remotePort = 6002
```

> **UDP 注意事项**：
> - `udpPacketSize` 在 frps 和 frpc 两端必须一致，默认 1500
> - UDP 代理下 `healthCheck` 不可用
> - 基于 UDP 的场景应评估是否可用 STCP 替代（流量不经过服务器）

#### HTTP 代理 — 网站通过域名路由

文件参考：`conf/frpc_full_example.toml` lines 238-267。

```toml
[[proxies]]
name = "web01"
type = "http"
localIP = "127.0.0.1"
localPort = 80
httpUser = "admin"
httpPassword = "admin"
subdomain = "web01"
customDomains = ["web01.yourdomain.com"]
locations = ["/", "/pic"]
hostHeaderRewrite = "example.com"
```

**服务端额外配置（frps）：**

```toml
vhostHTTPPort = 80
vhostHTTPSPort = 443
subDomainHost = "frps.com"
```

**关键规则：**
- 用户通过 `http://frps-ip:80`（或域名）访问 → frps 检查 `Host` 头 → 匹配 `customDomains` 或 `subdomain` → 转发到对应 frpc
- `subdomain` + `subDomainHost` 自动组合为 `web01.frps.com`
- `hostHeaderRewrite`：当后端服务需要特定 Host 头时修改
- `locations`：路径路由限制

#### HTTPS / TCP / STCP / XTCP 代理

**HTTPS**（参考 `conf/frpc_full_example.toml` lines 269-280）：

```toml
[[proxies]]
name = "web02"
type = "https"
localIP = "127.0.0.1"
localPort = 8000
customDomains = ["web02.yourdomain.com"]
transport.proxyProtocolVersion = "v2"
```

**STCP（安全 TCP，需认证访问）**（参考 `conf/frpc_full_example.toml` lines 384-395）：

```toml
[[proxies]]
name = "secret_tcp"
type = "stcp"
secretKey = "abcdefg"
localIP = "127.0.0.1"
localPort = 22
allowUsers = ["*"]
```

STCP 模式下，frps 只做信令中继，不转发数据流量。访问方需要**另一个** frpc 以 visitor 角色连接：

```toml
[[visitors]]
name = "secret_tcp_visitor"
type = "stcp"
serverName = "secret_tcp"
secretKey = "abcdefg"
bindAddr = "127.0.0.1"
bindPort = 9000
```

此时访问 `127.0.0.1:9000` 即可到达源机器的 SSH 端口。

**XTCP（P2P 直连）**（参考 `conf/frpc_full_example.toml` lines 397-413, 435-458）：

```toml
# 服务端（数据源）
[[proxies]]
name = "p2p_tcp"
type = "xtcp"
secretKey = "abcdefg"
localIP = "127.0.0.1"
localPort = 22
allowUsers = ["user1", "user2"]

# 访问端（visitor）
[[visitors]]
name = "p2p_tcp_visitor"
type = "xtcp"
serverUser = "user1"
serverName = "p2p_tcp"
secretKey = "abcdefg"
bindAddr = "127.0.0.1"
bindPort = 9001
keepTunnelOpen = false
maxRetriesAnHour = 8
minRetryInterval = 90
fallbackTo = "stcp_visitor"
fallbackTimeoutMs = 5000
```

> `fallbackTo`：XTCP 打洞失败后自动回退到 STCP 模式（经由服务器中转），保证连通性。

---

## 4. 高级应用

### 4.1 Dashboard 监控

frps Dashboard 提供实时状态查看：

```toml
webServer.addr = "127.0.0.1"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "strong-password"
```

**访问方式：** 始终绑定 `127.0.0.1` 并通过 SSH 隧道访问：

```bash
ssh -L 7500:127.0.0.1:7500 user@vps-ip
```

Dashboard 页面提供：
- 总览：在线客户端数、代理数、流量统计
- 客户端列表：每个 frpc 的连接状态、版本、IP
- 代理列表：每个代理的配置、流量、连接数
- 实时统计：带宽、延迟

**API 端点（可直接 curl）：**

```bash
# 获取服务端状态：版本、端口、连接数、代理类型分布
curl -u admin:strong-password http://127.0.0.1:7500/api/serverinfo

# 查看指定类型的代理（tcp/udp/http/https/stcp/xtcp）
curl -u admin:strong-password http://127.0.0.1:7500/api/proxy/tcp

# 按名称查看某个代理的详情
curl -u admin:strong-password http://127.0.0.1:7500/api/proxy/tcp/ssh

# 查看客户端列表
curl -u admin:strong-password http://127.0.0.1:7500/api/clients

# v2 分页 API（支持分页参数 ?offset=0&limit=20）
curl -u admin:strong-password "http://127.0.0.1:7500/api/v2/proxies?offset=0&limit=20"
curl -u admin:strong-password "http://127.0.0.1:7500/api/v2/clients?offset=0&limit=20"
```

### 4.2 Prometheus 监控

frps 支持自动暴露 Prometheus 指标：

```toml
enablePrometheus = true
```

配置后，`http://127.0.0.1:7500/metrics` 暴露以下指标：

- `frp_server_traffic_in` / `frp_server_traffic_out`
- `frp_server_connections`
- `frp_server_proxy_count`（按类型分类）

Prometheus 集成示例：

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'frps'
    scrape_interval: 15s
    static_configs:
      - targets: ['127.0.0.1:7500']
```

### 4.3 客户端 Admin UI 与动态代理

frpc 内置 Admin UI（参考 `conf/frpc_full_example.toml` lines 74-79）：

```toml
webServer.addr = "127.0.0.1"
webServer.port = 7400
webServer.user = "admin"
webServer.password = "admin"
```

**作用1：查看 frpc 运行状态**（浏览器打开 `http://127.0.0.1:7400`）

**作用2：动态增删代理（Store 模式）** — 不需要重启 frpc，通过 REST API 管理：

```bash
# 新增一个代理
curl -X POST -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"name":"temp-web","type":"http","localIP":"127.0.0.1","localPort":8080,"remotePort":6080}' \
  http://127.0.0.1:7400/api/proxy

# 列出当前代理
curl -u admin:admin http://127.0.0.1:7400/api/proxy

# 删除一个代理
curl -X DELETE -u admin:admin http://127.0.0.1:7400/api/proxy/temp-web
```

### 4.4 P2P 打洞原理与配置

XTCP 模式利用 NAT 打洞技术，使两端直接建立 UDP 通道，流量不经过 VPS：

| 条件 | 说明 |
|---|---|
| 两端 NAT 类型 | 至少一端为 Full Cone / 端口限制型 NAT |
| 信令服务 | frps 仅做双方地址交换，打洞成功后退出数据路径 |
| 失败回退 | 配置 `fallbackTo` 和 `fallbackTimeoutMs` 自动降级为 STCP |
| 适用场景 | 文件传输、视频流、大带宽内网服务 |

**配置要点：**

- 如果 `fallbackTo` 指向的 STCP visitor 不存在，XTCP 打洞失败后连接不会被兜底
- `keepTunnelOpen = true` 时 frpc 可持续维持隧道，减少打洞延迟
- 如果打洞始终失败（日志 `nat hole punch failed`），检查两端 NAT 类型或改用 STCP

### 4.5 虚拟主机路由

当 frps 的 `vhostHTTPPort` 和 `vhostHTTPSPort` 开启后，frps 根据 HTTP Host 头或 TLS SNI 字段将请求路由到不同 frpc：

```toml
# frps 配置
vhostHTTPPort = 80
vhostHTTPSPort = 443
subDomainHost = "example.com"
```

frpc 示例：

```toml
[[proxies]]
name = "blog"
type = "http"
localIP = "127.0.0.1"
localPort = 8080
customDomains = ["blog.example.com"]
```

```toml
[[proxies]]
name = "api"
type = "http"
localIP = "127.0.0.1"
localPort = 3000
customDomains = ["api.example.com"]
```

用户访问 `blog.example.com:80` 和 `api.example.com:80` 被 frps 分别路由到不同内网服务。

### 4.6 多客户端隔离

通过 `user` 字段隔离不同客户端的代理命名空间：

```toml
# frpc A
user = "team-alpha"
[[proxies]]
name = "ssh"
# 实际代理名为 team-alpha.ssh

# frpc B
user = "team-beta"
[[proxies]]
name = "ssh"
# 实际代理名为 team-beta.ssh
```

frps Dashboard 上可以看到 `team-alpha.ssh` 和 `team-beta.ssh` 分别对应不同的客户端。

---

## 5. 安全加固

### 5.1 最佳实践

**三件套（必须同时启用）：**

```toml
# frps 配置
auth.method = "token"
auth.token = "your-strong-token-here-32chars-min"
transport.tls.force = true
transport.tls.certFile = "/etc/frp/server.crt"
transport.tls.keyFile = "/etc/frp/server.key"
```

```toml
# frpc 配置
auth.token = "your-strong-token-here-32chars-min"
transport.tls.enable = true
transport.tls.trustedCaFile = "/etc/frp/ca.crt"
```

**生成自签名 TLS 证书：**

```bash
# 生成 CA 密钥和证书
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=FRP CA"

# 生成服务端证书
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=frps.example.com"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
```

**最小端口原则：**

```toml
# frps — 只允许 6000-6100 和 3001
allowPorts = [
  { start = 6000, end = 6100 },
  { single = 3001 }
]
# maxPortsPerClient = 5  # 每个客户端最大端口数
```

**创建专用 frp 用户：**

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin frp
# 然后在 systemd 中改为 User=frp
# 确保 /etc/frp/ 的权限为 frp:frp，/var/log/frps.log 可写
sudo chown -R frp:frp /etc/frp
sudo chown frp:frp /var/log/frps.log
```

**防火墙规则：**

```bash
# 仅放行必要端口
sudo ufw allow 7000/tcp    # frps 控制端口
sudo ufw allow 6000:6100/tcp  # 代理端口
sudo ufw allow 7500/tcp    # 仅限受信 IP，不对外放行
```

### 5.2 ❌ 反例黑名单

| 反模式 | 风险 | 正确做法 |
|---|---|---|
| **仅 Token 认证，不启用 TLS** | Token 在控制连接建立时明文传输（第 3 个 TCP 段），抓包即可获取 Token | Token + TLS 必须同时启用。`transport.tls.force = true` + `auth.token` |
| **Dashboard 绑定 0.0.0.0 公网暴露** | 配置信息、客户端列表、代理拓扑全部公开；若未改默认密码（admin/admin），攻击者可完全控制 | Dashboard 始终绑定 `127.0.0.1`，通过 SSH 隧道访问 |
| **不设置 allowPorts** | 客户端可申请任意端口（包括 1-1023 特权端口），导致端口滥用、被用作跳板攻击 | 始终设置 `allowPorts` 约束可用端口范围 |
| **frps 以 root 运行** | 如果 frps 存在 RCE 漏洞，攻击者获得服务器 root 权限 | 使用 `nobody` 或创建专用 `frp` 系统用户，systemd 中指定 `User=frp` |
| **frpc 以管理员/root 运行** | 同上，内网完全暴露 | frpc 同样使用最小权限用户运行 |
| **使用默认 Token `12345678`** | 任何人都可扫描 7000 端口并尝试登录 | Token 长度 ≥ 32 字符，含大小写字母+数字+特殊字符 |
| **日志不轮转** | 日志填满磁盘导致 frps 异常退出、系统无响应 | 设置 `log.maxDays` 或使用 logrotate |

---

## 6. 故障排查

### 6.1 症状 × 根因 × 解法 决策表

| 症状 | 根因 | 一线修复 | 仍失败兜底 |
|---|---|---|---|
| `login to server failed: i/o timeout` | 防火墙/安全组未放行 `serverPort`（7000） | 检查云服务商安全组入站规则 | `nc -zv <vps-ip> 7000` 从客户端测试连通性 |
| `login to server failed: connection refused` | frps 未运行或绑定地址错误 | `sudo systemctl status frps` | 检查 frps 日志 `tail -50 /var/log/frps.log` |
| `login to server failed: auth token not match` | 两端 token 不一致 | 比对 frps 和 frpc 的 `auth.token` | 确认配置文件路径正确、无隐藏空格/换行 |
| `proxy name [xxx] is already registered` | 代理名称重复 | 给代理起唯一名称或用 `user` 字段做命名空间隔离 | 检查所有 frpc 的 `name` 字段 |
| `port [6000] not allowed` | 端口超出 `allowPorts` 范围 | 将端口加入 `allowPorts` 列表 | 或为代理选择一个范围内的 `remotePort` |
| `connect to local service [127.0.0.1:22] error` | 本地服务未运行或端口不对 | `sudo systemctl status sshd` | `curl 127.0.0.1:22` 确认本地监听 |
| i/o timeout (频繁断连) | 网络不稳定或 keepalive 配置不当 | 检查 `transport.heartbeatInterval` 和 `transport.heartbeatTimeout` | 确认 frps 的 `transport.heartbeatTimeout` 大于 frpc 的 `heartbeatInterval` |
| `tls: first record does not look like a TLS handshake` | frps 要求 TLS 但 frpc 未启用 | frpc 配置 `transport.tls.enable = true` | 检查 `transport.tls.force` 是否只在 frps 开启了 |
| `dial tcp <vps-ip>:<port>: connect: cannot assign requested address` | 客户端端口耗尽（TIME_WAIT 积压） | 增大 `net.ipv4.ip_local_port_range` | `sudo sysctl -w net.ipv4.tcp_tw_reuse=1` |
| frps 日志报 `too many open files` | 文件描述符耗尽 | 检查 `LimitNOFILE=1048576` 是否生效 | `ulimit -n` 确认当前值 |
| Dashboard 加载空白 | `webServer` 未配置或端口被占 | `ss -tlnp | grep 7500` | 检查 `webServer.port` 配置是否生效后重启 frps |

### 6.2 日志关键词速查

| 关键词 | 含义 | 处理 |
|---|---|---|
| `login to server success` | 客户端连接成功 | 正常，无需处理 |
| `start proxy success` | 代理注册成功 | 正常 |
| `connection closed` | 连接正常关闭 | 观察频次，过高可能异常 |
| `connection reset by peer` | 连接被对端重置 | 检查网络稳定性、各端防火墙 |
| `i/o timeout` | 网络超时 | 见上表 |
| `auth token not match` | Token 认证失败 | 比对两端 token |
| `no available connections` | 连接池耗尽 | 增大 `transport.poolCount` |
| `nat hole punch failed` | P2P 打洞失败 | 改用 STCP 或检查 NAT 类型 |

### 6.3 调试技巧

**临时调高日志级别定位问题：**

```bash
# 临时在前台运行 frps 并输出 debug 日志
sudo -u nobody /usr/local/frp/frps -c /etc/frp/frps.toml --log-level debug
```

**确认端口可用性三部曲：**

```bash
# 1. 服务端是否在监听
ss -tlnp | grep 7000

# 2. 防火墙是否放行
iptables -L -n | grep 7000
# 或云服务商控制台查看安全组

# 3. 公网可达性测试（在另一台机器执行）
nc -zv <vps-ip> 7000
# Connection to <vps-ip> 7000 port [tcp/*] succeeded!
```

**抓包验证 Token 是否明文：**

```bash
# 在 frpc 机器抓包（确认未启用 TLS 前不要用于生产）
sudo tcpdump -i any -X port 7000
# 检查数据包中是否出现 token 字符串
```

---

## 7. 测试 Prompts

以下 prompt 用于验证本 skill 的覆盖质量和可执行性：

1. **「帮我在一台新 Linux VPS 上部署 frps，开启 Dashboard + Token 认证 + TLS 加密」**
   → 验证 2.1 服务端部署 + 5 安全加固的完整链路。期望输出：下载命令 → 配置模板 → systemd 服务 → 验证命令。

2. **「frpc 报错 'login to server failed: i/o timeout'，帮我排查原因并提供修复步骤」**
   → 验证 6.1 故障决策表中的第一行。期望输出：防火墙/安全组检查 → `nc -zv` 测试 → 云服务商安全组规则调整 → 配置修改。

3. **「我需要通过 frp 把内网的 Jupyter Notebook（8888）和 RDP（3389）同时暴露出去，写配置」**
   → 验证 3.2 TCP 代理配置。期望输出：frpc.toml 中两个 `[[proxies]]` 段，分别对应 8888 和 3389，含 `remotePort`、加密选项。
