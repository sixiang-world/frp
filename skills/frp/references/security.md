# FRP 安全加固参考

> 本文档是 SKILL.md 第 5 节的完整展开。
> 核心三件套和反例黑名单见主文件，以下是证书生成、用户隔离和防火墙细节。

---

## TLS 证书生成（自签名）

### 步骤 1：生成 CA

```bash
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=FRP CA"
```

### 步骤 2：生成服务端证书

```bash
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=frps.example.com"
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
```

### 步骤 3：部署到 frps

```bash
sudo mkdir -p /etc/frp/tls
sudo cp server.crt server.key ca.crt /etc/frp/tls/
sudo chmod 600 /etc/frp/tls/server.key   # 私钥仅 root 可读
```

### 步骤 4：配置 frps

```toml
transport.tls.force = true
transport.tls.certFile = "/etc/frp/tls/server.crt"
transport.tls.keyFile = "/etc/frp/tls/server.key"
```

### 步骤 5：配置 frpc

```toml
transport.tls.enable = true
transport.tls.trustedCaFile = "/etc/frp/tls/ca.crt"
```

> **为什么 Token + TLS 必须同时启用？**
> 仅 Token 认证时，Token 在控制连接建立的第 3 个 TCP 段中明文传输，抓包即可获取。
> TLS 加密整个控制连接，Token 不会被嗅探。

---

## 专用系统用户

```bash
# 创建 frp 系统用户（无登录权限、无 home 目录）
sudo useradd --system --no-create-home --shell /usr/sbin/nologin frp

# 设置文件权限
sudo chown -R frp:frp /etc/frp
sudo chown frp:frp /var/log/frps.log
sudo chown frp:frp /var/log/frpc.log
```

systemd 中指定 `User=frp` 而非 `User=nobody`。

---

## 防火墙规则

```bash
# ufw
sudo ufw allow 7000/tcp          # frps 控制端口
sudo ufw allow 6000:6100/tcp     # 代理端口范围
# 7500（Dashboard）不对外放行——通过 SSH 隧道访问

# iptables
iptables -A INPUT -p tcp --dport 7000 -j ACCEPT
iptables -A INPUT -p tcp --dport 6000:6100 -j ACCEPT
iptables -A INPUT -p tcp --dport 7500 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 7500 -j DROP
```

---

## 安全配置模板（生产环境就绪）

```toml
# /etc/frp/frps.toml — 生产配置

bindPort = 7000

# 认证
auth.method = "token"
auth.token = "your-strong-token-here-32chars-min"

# TLS
transport.tls.force = true
transport.tls.certFile = "/etc/frp/tls/server.crt"
transport.tls.keyFile = "/etc/frp/tls/server.key"

# Dashboard（仅本地访问）
webServer.addr = "127.0.0.1"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "change-this-password-now"

# 端口限制
allowPorts = [
  { start = 6000, end = 6100 },
  { single = 3001 }
]
maxPortsPerClient = 5

# 日志
log.to = "/var/log/frps.log"
log.level = "info"
log.maxDays = 7

# Prometheus 监控
enablePrometheus = true
```

---

## 安全反模式对照（展开版）

| 反模式 | 风险等级 | 攻击面 | 正确做法 |
|--------|:--------:|--------|----------|
| 仅 Token 不启用 TLS | 🔴 高危 | Token 明文暴露于控制连接第 3 个 TCP 段 | Token + TLS 同时启用 |
| Dashboard 绑定 0.0.0.0 | 🔴 高危 | 配置信息、代理拓扑、客户端列表全网可见 | 绑定 127.0.0.1 + SSH 隧道 |
| 不设置 allowPorts | 🔴 高危 | 客户端可申请任意端口（含 1-1023 特权端口） | 始终设置 `allowPorts` |
| frps 以 root 运行 | 🔴 高危 | RCE 漏洞 → 服务器 root 权限沦陷 | `User=nobody` 或 `User=frp` |
| 使用默认 Token | 🟡 中危 | 扫描 7000 端口即可尝试登录 | ≥32 字符，含大小写+数字+特殊字符 |
| 日志不轮转 | 🟡 中危 | 日志填满磁盘 → frps 异常退出 | 设置 `log.maxDays` 或 logrotate |
| 公网暴露控制端口 7000 | 🟡 中危 | 端口扫描 + 自动爆破尝试 | 限制源 IP 或使用非标准端口 |

---

## 最佳实践清单

- [ ] Token + TLS 同时启用
- [ ] Dashboard 绑定 `127.0.0.1`
- [ ] `allowPorts` 限制可用端口范围
- [ ] frps/frpc 非 root 运行
- [ ] Token ≥ 32 字符
- [ ] 日志轮转配置
- [ ] 私钥文件权限 600
- [ ] 防火墙仅放行必要端口
- [ ] 定期检查 frps 日志（`log.maxDays`）
- [ ] 更新时注意版本兼容性
