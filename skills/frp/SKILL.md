---
name: frp
description: >-
  FRP内网穿透/端口转发/NAT穿透神器！frps/frpc部署/配置/安全/排查。
  用户说「内网穿透」「frp」「frps」「frpc」「端口转发」「NAT穿透」
  「暴露本地服务」「反向代理」「穿透公司内网」「远程访问内网」
  「将内网服务映射到公网」时触发。
  覆盖：SSH/HTTP/HTTPS/TCP/UDP/P2P/STCP/XTCP/Dashboard。
---

# FRP — Fast Reverse Proxy

## TL;DR

FRP 是自托管的内网穿透反向代理工具。公网 VPS 运行 frps，内网机器运行 frpc，两者建立隧道后即可通过 VPS 的 IP+端口访问内网服务。

| 目标 | 命令/配置 |
|------|-----------|
| 服务端下载 | `wget https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz && tar xzf frp_*.tar.gz` |
| 服务端配置 | `bindPort = 7000` + `auth.token = "..."` |
| 启动服务端 | `./frps -c /etc/frp/frps.toml` |
| 客户端配置 | `serverAddr = "your-vps"` + `[[proxies]] name = "ssh" type = "tcp" localPort = 22 remotePort = 6000` |
| 启动客户端 | `./frpc -c /etc/frp/frpc.toml` |

---

## 1. 架构

```
公网用户 → VPS (frps) → 内网机器 (frpc) → localhost 服务
```

- **控制连接**：frpc → frps 长连接，用于心跳、认证、配置同步
- **数据连接**：请求到达 frps 后，触发 frpc 建立数据连接转发流量
- **frps 是中转节点**，纯四层流量转发，不缓存不解析应用层协议

### 适用场景

| 场景 | 代理类型 |
|------|----------|
| SSH 远程管理 | TCP |
| HTTP 网站 | HTTP（支持域名路由 + BasicAuth） |
| HTTPS 服务 | HTTPS / TCP |
| 数据库远程连接 | TCP |
| P2P 直连（不经过服务器） | STCP / XTCP |
| RDP 远程桌面 | TCP |
| SMB 文件共享 | STCP |

> 完整配置示例见项目 `conf/frpc_full_example.toml`（469 行）和 `conf/frps_full_example.toml`（169 行）。

### 同类对比

| 特性 | FRP | Ngrok | Cloudflare Tunnel | Tailscale |
|------|-----|-------|-------------------|-----------|
| 部署模式 | 自托管 | SaaS | SaaS（需域名） | P2P Mesh |
| 需要公网 IP | 是（VPS） | 否 | 否 | 否 |
| TCP/UDP 转发 | 完整支持 | TCP+HTTP | HTTP/SSH | 全协议 |
| P2P 直连 | 支持（XTCP） | 不提供 | 不提供 | 原生 |
| 自托管程度 | 完全 | 核心闭源 | 开源 tunnel | 部分开源 |

---

## 2. 快速部署

### 2.1 服务端（Linux VPS）— 一键脚本

```bash
# 用部署脚本（自动检测架构、配置 systemd）
sudo bash scripts/deploy-frps.sh
```

或手动部署：

```bash
# 下载
VERSION="0.69.1"
ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && S="linux_amd64" || S="linux_arm64"
wget "https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_${S}.tar.gz"
tar xzf "frp_${VERSION}_${S}.tar.gz"
sudo mv "frp_${VERSION}_${S}" /usr/local/frp

# 配置
sudo mkdir -p /etc/frp
# 写入 /etc/frp/frps.toml（见下方模板）

# systemd 服务
# 见 references/deployment.md 完整版

# 启动验证
sudo systemctl enable frps && sudo systemctl start frps
ss -tlnp | grep 7000
```

**最小配置模板 `/etc/frp/frps.toml`：**

```toml
bindPort = 7000
auth.method = "token"
auth.token = "your-32-char-min-token"
webServer.addr = "127.0.0.1"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "change-this-now"
allowPorts = [{ start = 6000, end = 6100 }]
log.to = "/var/log/frps.log"
log.level = "info"
log.maxDays = 7
```

> **🔴 STOP：生产前必须改 `auth.token`（≥32 字符）和 `webServer.password`，否则任何人都可用默认密码登录 Dashboard。**

### 2.2 客户端（Linux）

```bash
# 安装（同服务端步骤）
wget ... && tar xzf ... && sudo mv ... /usr/local/frp

# 配置 /etc/frp/frpc.toml
[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

> macOS / Windows / Docker 客户端完整部署见 `references/deployment.md`。

### 验证隧道

```bash
ssh -p 6000 user@<vps-ip>
# 应连接到内网机器的 SSH 服务
```

**🔴 CHECKPOINT：** 确认以上命令能登录内网机器，再继续后续配置。

---

## 3. 核心配置

### 3.1 全局字段

| 字段 | 位置 | 说明 |
|------|------|------|
| `serverAddr` | frpc | 服务端 IP 或域名 |
| `serverPort` | frpc | 服务端绑定端口 |
| `bindPort` | frps | 服务端监听端口 |
| `auth.token` | 两端 | 认证令牌（生产必填） |

### 3.2 代理类型速查

**TCP（SSH/DB/RDP）：**
```toml
[[proxies]]
type = "tcp"
localIP = "127.0.0.1"; localPort = 3306; remotePort = 6001
transport.useEncryption = true
healthCheck.type = "tcp"
```

**HTTP（网站）：**
```toml
[[proxies]]
type = "http"; localPort = 80
customDomains = ["web.yourdomain.com"]
# frps 需开启 vhostHTTPPort
```

**STCP（安全 TCP）：**
```toml
[[proxies]]
type = "stcp"; secretKey = "abc"
# 访问端需要 [[visitors]] 段配置
```

> **🔴 STOP：添加新代理前，确认 remotePort 不与其他代理冲突，且已加入 frps 的 `allowPorts` 列表。**

> 所有代理类型完整示例 + 字段说明见 `references/configuration.md`。

---

## 4. 安全

### 4.1 三件套（必须同时启用）

```toml
# frps
auth.method = "token"
auth.token = "your-32-char-min-token"
transport.tls.force = true
transport.tls.certFile = "/etc/frp/tls/server.crt"
transport.tls.keyFile = "/etc/frp/tls/server.key"

# frpc
auth.token = "your-32-char-min-token"
transport.tls.enable = true
transport.tls.trustedCaFile = "/etc/frp/tls/ca.crt"
```

> TLS 证书生成脚本：`bash scripts/gen-tls-certs.sh`

### 4.2 反例黑名单

| 反模式 | 风险 | 正确做法 |
|--------|------|----------|
| 仅 Token 不启用 TLS | Token 在控制连接中明文传输 | Token + TLS 同时启用 |
| Dashboard 绑定 0.0.0.0 | 配置信息、客户端列表全网可见 | 绑定 `127.0.0.1` + SSH 隧道 |
| 不设置 allowPorts | 客户端可申请任意端口（含 1-1023） | 始终设置 `allowPorts` |
| frps 以 root 运行 | RCE 漏洞 → 服务器沦陷 | `User=nobody` 或 `User=frp` |
| Token 长度不足 | 被暴力破解 | ≥32 字符，含大小写+数字+特殊字符 |

> 完整安全配置 + 证书生成 + 防火墙规则见 `references/security.md`。

---

## 5. 故障排查

### 5.1 快速决策表

| 症状 | 一线修复 | 兜底 |
|------|----------|------|
| `login to server failed: i/o timeout` | 检查安全组入站规则 | `nc -zv <vps-ip> 7000` |
| `login to server failed: connection refused` | `systemctl status frps` | 查看日志 |
| `auth token not match` | 比对两端 token | 确认配置无隐藏字符 |
| `proxy name already registered` | 用唯一名称或 `user` 字段隔离 | 检查所有 frpc |
| `port [6000] not allowed` | 加入 `allowPorts` | 选范围内的 port |

> **🔴 STOP：修改生产环境配置前，先备份当前配置：`cp /etc/frp/frps.toml /etc/frp/frps.toml.bak`**

### 5.2 端口排查三部曲

```bash
# 1. 服务端监听
ss -tlnp | grep 7000
# 2. 防火墙
iptables -L -n | grep 7000
# 3. 公网可达
nc -zv <vps-ip> 7000
```

> 完整决策表（15 条）+ 日志速查 + 调试技巧 + SSH 指纹验证见 `references/troubleshooting.md`。

---

## 6. 脚本速查

| 脚本 | 用途 | 用法 |
|------|------|------|
| `scripts/deploy-frps.sh` | 一键部署 frps（自动检测架构） | `sudo bash scripts/deploy-frps.sh [version] [port]` |
| `scripts/gen-tls-certs.sh` | 生成自签名 TLS 证书 | `bash scripts/gen-tls-certs.sh [out_dir] [domain]` |
| `scripts/health-check.sh` | 检查 frps/frpc 运行状态 | `bash scripts/health-check.sh [server_ip] [port]` |

---

## 7. 测试 Prompts

以下 prompt 用于验证本 skill 的覆盖质量：

1. **「帮我在一台新 Linux VPS 上部署 frps，开启 Dashboard + Token 认证 + TLS 加密」**
   → 验证 2.1 服务端部署 + 安全加固。期望输出：下载命令 → 配置模板 → systemd 服务 → 验证命令。

2. **「frpc 报错 'login to server failed: i/o timeout'，帮我排查并提供修复步骤」**
   → 验证 5.1 决策表。期望输出：防火墙检查 → `nc -zv` 测试 → 安全组调整。

3. **「把内网的 Jupyter（8888）和 RDP（3389）同时通过 frp 暴露出去，写配置」**
   → 验证 3.2 TCP 代理配置。期望输出：两个 `[[proxies]]` 段，含 remotePort 和加密选项。

---

> 全部子页面索引：
> - `references/deployment.md` — 各平台完整部署（Linux/macOS/Windows/Docker）
> - `references/configuration.md` — 完整配置详解（Dashboard/API/Prometheus/多客户端隔离）
> - `references/troubleshooting.md` — 完整故障决策表（15 条）+ 日志速查 + SSH 指纹验证
> - `references/security.md` — TLS 证书生成 + 防火墙规则 + 生产配置模板
> - `references/test-procedure.md` — v0.69.1-dev ↔ v0.62.1 端到端实测记录
> - `scripts/deploy-frps.sh` — 一键服务端部署
> - `scripts/gen-tls-certs.sh` — 自签名 TLS 证书生成
> - `scripts/health-check.sh` — 运行状态检查
