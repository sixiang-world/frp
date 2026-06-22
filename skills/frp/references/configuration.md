# FRP 配置详解

> 本文档是 SKILL.md 第 3-4 节的完整展开，包含所有代理类型、字段说明和高级用法。
> 完整配置示例见项目 `conf/frpc_full_example.toml`（469 行）和 `conf/frps_full_example.toml`（169 行）。

---

## 全局配置字段

| 字段 | 位置 | 说明 | 默认值 |
|------|------|------|--------|
| `serverAddr` | frpc | 服务端 IP 或域名 | 必填 |
| `serverPort` | frpc | 服务端绑定端口 | 必填 |
| `bindPort` | frps | 服务端监听端口 | 必填 |
| `auth.token` | 两端 | 认证令牌 | 必填（生产） |
| `auth.method` | 两端 | `"token"` 或 `"oidc"` | `"token"` |
| `log.to` | 两端 | 日志路径或 `"console"` | `"console"` |
| `log.level` | 两端 | `trace/debug/info/warn/error` | `"info"` |
| `log.maxDays` | 两端 | 日志保留天数 | 3 |

---

## 代理类型详解

### TCP 代理 — SSH / 数据库 / RDP

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

| 字段 | 作用 |
|------|------|
| `remotePort` | frps 在此端口监听。`remotePort = 0` 时随机分配 |
| `transport.useEncryption` | 传输层加密。即使已有 TLS 连接层，双层加密更安全 |
| `loadBalancer.group` | 同组内多个 frpc 实例轮询分发（负载均衡） |
| `healthCheck` | frpc 定期检查本地服务健康，检测到故障后从 frps 移除该代理 |

### UDP 代理 — DNS / 游戏服务器

```toml
[[proxies]]
name = "dns"
type = "udp"
localIP = "114.114.114.114"
localPort = 53
remotePort = 6002
```

**限制：**
- `udpPacketSize` 在 frps / frpc 两端必须一致（默认 1500）
- UDP 代理下 `healthCheck` 不可用
- 基于 UDP 的场景应评估是否可用 STCP 替代（流量不经服务端）

### HTTP 代理 — 网站域名路由

```toml
# frpc 配置
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

frps 额外配置：

```toml
vhostHTTPPort = 80
vhostHTTPSPort = 443
subDomainHost = "frps.com"
```

**路由规则：**
1. 用户访问 `http://frps-ip:80` → frps 检查 Host 头
2. 匹配 `customDomains` 或 `subdomain` → 转发到对应 frpc
3. `subdomain` + `subDomainHost` 自动组合为 `web01.frps.com`
4. `hostHeaderRewrite`：后端服务需要特定 Host 头时修改
5. `locations`：路径路由限制（仅在匹配路径下转发）

### HTTPS 代理

```toml
[[proxies]]
name = "web02"
type = "https"
localIP = "127.0.0.1"
localPort = 8000
customDomains = ["web02.yourdomain.com"]
transport.proxyProtocolVersion = "v2"
```

HTTPS 代理有两种模式：
- frps 终止 TLS 后转发 HTTP 到后端（type = "https" + frps 配置证书）
- TCP 直通（type = "tcp"），frps 不解析 TLS，纯四层转发

### STCP 代理（安全 TCP）

frps 只做信令中继，不转发数据流量。需要 visitor 端才能访问。

**服务端（数据源）：**

```toml
[[proxies]]
name = "secret_tcp"
type = "stcp"
secretKey = "abcdefg"
localIP = "127.0.0.1"
localPort = 22
allowUsers = ["*"]
```

**访问端（visitor）：**

```toml
[[visitors]]
name = "secret_tcp_visitor"
type = "stcp"
serverName = "secret_tcp"
secretKey = "abcdefg"
bindAddr = "127.0.0.1"
bindPort = 9000
```

访问者连接 `127.0.0.1:9000` 即可到达源机器的 SSH 端口。

### XTCP 代理（P2P 直连）

利用 NAT 打洞，流量不经过 frps。

**服务端（数据源）：**

```toml
[[proxies]]
name = "p2p_tcp"
type = "xtcp"
secretKey = "abcdefg"
localIP = "127.0.0.1"
localPort = 22
allowUsers = ["user1", "user2"]
```

**访问端（visitor）：**

```toml
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

> XTCP 打洞失败后自动回退到 STCP 模式（`fallbackTo`），保证连通性。

---

## Dashboard 监控

frps Dashboard 配置：

```toml
webServer.addr = "127.0.0.1"    # 始终绑定 127.0.0.1，不暴露公网
webServer.port = 7500
webServer.user = "admin"
webServer.password = "strong-password"
```

访问方式（SSH 隧道）：`ssh -L 7500:127.0.0.1:7500 user@vps-ip`

Dashboard 提供：
- 总览：在线客户端数、代理数、流量统计
- 客户端列表：连接状态、版本、IP
- 代理列表：配置、流量、连接数
- 实时统计：带宽、延迟

### REST API 端点

```bash
curl -u admin:password http://127.0.0.1:7500/api/serverinfo
curl -u admin:password http://127.0.0.1:7500/api/proxy/tcp
curl -u admin:password http://127.0.0.1:7500/api/proxy/tcp/ssh
curl -u admin:password http://127.0.0.1:7500/api/clients
curl -u admin:password "http://127.0.0.1:7500/api/v2/proxies?offset=0&limit=20"
curl -u admin:password "http://127.0.0.1:7500/api/v2/clients?offset=0&limit=20"
```

### Prometheus 集成

```toml
# frps 配置
enablePrometheus = true
```

`http://127.0.0.1:7500/metrics` 暴露指标：
- `frp_server_traffic_in` / `frp_server_traffic_out`
- `frp_server_connections`
- `frp_server_proxy_count`（按类型分类）

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'frps'
    scrape_interval: 15s
    static_configs:
      - targets: ['127.0.0.1:7500']
```

---

## 客户端 Admin UI（动态代理管理）

frpc 内置 Admin UI：

```toml
webServer.addr = "127.0.0.1"
webServer.port = 7400
webServer.user = "admin"
webServer.password = "admin"
```

通过 REST API 动态增删代理（无需重启 frpc）：

```bash
# 新增代理
curl -X POST -H "Content-Type: application/json" \
  -u admin:admin \
  -d '{"name":"temp-web","type":"http","localIP":"127.0.0.1","localPort":8080,"remotePort":6080}' \
  http://127.0.0.1:7400/api/proxy

# 列出代理
curl -u admin:admin http://127.0.0.1:7400/api/proxy

# 删除代理
curl -X DELETE -u admin:admin http://127.0.0.1:7400/api/proxy/temp-web
```

---

## 多客户端隔离

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

Dashboard 上可以看到 `team-alpha.ssh` 和 `team-beta.ssh` 分别对应不同客户端。

---

## 虚拟主机路由

```toml
# frps 配置
vhostHTTPPort = 80
vhostHTTPSPort = 443
subDomainHost = "example.com"
```

```toml
# frpc — 博客
[[proxies]]
name = "blog"
type = "http"
localIP = "127.0.0.1"
localPort = 8080
customDomains = ["blog.example.com"]

# frpc — API
[[proxies]]
name = "api"
type = "http"
localIP = "127.0.0.1"
localPort = 3000
customDomains = ["api.example.com"]
```

frps 根据 Host 头将 `blog.example.com` 和 `api.example.com` 分别路由到不同内网服务。
