# FRP 故障排查完整参考

> 本文档是 SKILL.md 第 6 节的完整展开。快速排查用主文件的精简决策表，
> 以下是所有已知故障的完整症状‑根因‑解法对照。

---

## 症状 × 根因 × 解法 决策表

| 症状 | 根因 | 一线修复 | 仍失败兜底 |
|------|------|----------|------------|
| `login to server failed: i/o timeout` | 防火墙/安全组未放行 `serverPort` | 检查云服务商安全组入站规则 | `nc -zv <vps-ip> 7000` 从客户端测试连通性 |
| `login to server failed: connection refused` | frps 未运行或绑定地址错误 | `sudo systemctl status frps` | 检查 frps 日志 `tail -50 /var/log/frps.log` |
| `login to server failed: auth token not match` | 两端 token 不一致 | 比对 frps 和 frpc 的 `auth.token` | 确认配置文件路径正确、无隐藏空格/换行 |
| `proxy name [xxx] is already registered` | 代理名称重复 | 给代理起唯一名称或用 `user` 字段隔离 | 检查所有 frpc 的 `name` 字段 |
| `port [6000] not allowed` | 端口超出 `allowPorts` 范围 | 将端口加入 `allowPorts` 列表 | 选择一个范围内的 `remotePort` |
| `connect to local service [127.0.0.1:22] error` | 本地服务未运行或端口不对 | `sudo systemctl status sshd` | `curl 127.0.0.1:22` 确认本地监听 |
| i/o timeout（频繁断连） | 网络不稳定或 keepalive 不当 | 检查 `transport.heartbeatInterval` 和 `transport.heartbeatTimeout` | 确认 frps 的 `heartbeatTimeout` > frpc 的 `heartbeatInterval` |
| `tls: first record does not look like a TLS handshake` | frps 要求 TLS 但 frpc 未启用 | frpc 配置 `transport.tls.enable = true` | 检查 `transport.tls.force` 是否只在 frps 开启了 |
| `dial tcp <vps-ip>:<port>: connect: cannot assign requested address` | 客户端端口耗尽（TIME_WAIT 积压） | 增大 `net.ipv4.ip_local_port_range` | `sudo sysctl -w net.ipv4.tcp_tw_reuse=1` |
| frps 日志报 `too many open files` | 文件描述符耗尽 | 检查 `LimitNOFILE=1048576` 是否生效 | `ulimit -n` 确认当前值 |
| Dashboard 加载空白 | `webServer` 未配置或端口被占 | `ss -tlnp \| grep 7500` | 检查 `webServer.port` 配置是否生效后重启 frps |
| `no available connections` | 连接池耗尽 | 增大 `transport.poolCount` | 检查是否有大量短连接场景需要调整 pool size |
| `nat hole punch failed` | P2P 打洞失败 | 改用 STCP 或检查两端 NAT 类型 | 确认至少一端为 Full Cone NAT |
| frpc 日志被刷爆 | 日志级别太低或无限重连 | 设置 `log.maxDays` | 用 logrotate 限制日志大小 |

---

## 日志关键词速查

| 关键词 | 含义 | 处理 |
|--------|------|------|
| `login to server success` | 客户端连接成功 | 正常，无需处理 |
| `start proxy success` | 代理注册成功 | 正常 |
| `connection closed` | 连接正常关闭 | 观察频次，过高可能异常 |
| `connection reset by peer` | 连接被对端重置 | 检查网络稳定性、各端防火墙 |
| `i/o timeout` | 网络超时 | 见决策表 |
| `auth token not match` | Token 认证失败 | 比对两端 token |
| `no available connections` | 连接池耗尽 | 增大 `transport.poolCount` |
| `nat hole punch failed` | P2P 打洞失败 | 改用 STCP 或检查 NAT 类型 |
| `too many open files` | 文件描述符耗尽 | 检查 `LimitNOFILE` |
| `proxy name [xxx] is already registered` | 代理名重复 | 更改代理名或用 user 隔离 |
| `login to server failed` | 登录失败（后接具体原因） | 查看后缀判断具体问题 |

---

## 调试技巧

### 临时调高日志级别

```bash
# 前台运行，输出 debug 日志
sudo -u nobody /usr/local/frp/frps -c /etc/frp/frps.toml --log-level debug
```

### 端口可用性三部曲

```bash
# 1. 服务端是否在监听
ss -tlnp | grep 7000

# 2. 防火墙是否放行
iptables -L -n | grep 7000
# 或看云服务商安全组

# 3. 公网可达性测试（从另一台机器执行）
nc -zv <vps-ip> 7000
# 应输出: Connection to <vps-ip> 7000 port [tcp/*] succeeded!
```

### SSH host key 指纹验证

确认 TCP 隧道路由正确，防止中间人攻击：

```bash
# 1. 获取本机 SSH host key 指纹
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# 2. 获取 frps 映射端口的 host key 指纹
ssh-keygen -lf <(ssh-keyscan -p 6000 <vps-ip> 2>/dev/null | grep ed25519)

# 3. 比较两条指纹
# 一致 → 隧道正确，流量到达本机 SSH
# 不一致 → 流量被劫持或 frps 配置错误
```

### 抓包验证 Token 是否明文

```bash
# 在 frpc 机器抓包（确认未启用 TLS 前不要用于生产）
sudo tcpdump -i any -X port 7000
# 检查数据包中是否出现 token 字符串
```

---

## 已知约束

| 场景 | 约束 |
|------|------|
| UDP 代理 | `healthCheck` 不可用 |
| 跨版本兼容 | 较新 frpc（v0.69.1）可连较旧 frps（v0.62.1），配置均为 TOML 格式 |
| Docker Desktop | `--network host` 不可用（macOS/Windows） |
| P2P 打通 | 至少一端需为 Full Cone / 端口限制型 NAT |
| XTCP fallback | 如果 `fallbackTo` 指向的 STCP visitor 不存在，打洞失败后不自动降级 |
