# FRP 端到端测试流程（2026-06-22 实测验证）

## 测试环境

| 角色 | 服务器 | IP | 版本 |
|------|--------|-----|------|
| frps 服务端 | ali-hermes（阿里云上海） | 47.77.227.16:6100 | v0.62.1 |
| frpc 客户端 | do-hermes（DigitalOcean 新加坡） | 本机 | v0.69.1-dev（源码构建） |
| 测试代理 | TCP SSH 隧道 | remotePort=6101 → localhost:22 | — |

## 测试步骤

### Step 1：构建 frpc

```bash
cd /path/to/frp/source
make frpc
# 输出: bin/frpc
```

### Step 2：创建配置文件

```toml
# frpc-test.toml — 连接 ali-hermes frps
serverAddr = "47.77.227.16"
serverPort = 6100
auth.token = "LE6a3NKyKtE2Y4Sa6d4rZ6vZ21bREm9HGktZ8AaPuJY="

log.to = "./frpc-test.log"
log.level = "debug"
log.maxDays = 1

[[proxies]]
name = "test-ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6101
transport.useEncryption = true
```

### Step 3：启动 frpc

```bash
cd /path/to/frp/source && bin/frpc -c frpc-test.toml
```

### Step 4：验证登录

预期日志输出：

```
[I] start frpc service for config file [frpc-test.toml]
[I] try to connect to server...
[I] login to server success, get run id [xxxxxxxxxxxx]
[I] proxy added: [test-ssh]
[I] [test-ssh] start proxy success
```

### Step 5：SSH host key 指纹验证

```bash
# 检查本机 SSH key
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# 检查 frps 映射端口的 SSH key
ssh-keygen -lf <(ssh-keyscan -p 6101 47.77.227.16 2>/dev/null | grep ed25519)

# 检查阿里服务器原生 SSH key（用于对比）
ssh-keygen -lf <(ssh-keyscan -p 22 47.77.227.16 2>/dev/null | grep ed25519)
```

**通过条件**：映射端口 (6101) 的 host key == 本机 host key ≠ 阿里 SSH host key

## 验证结论

- frpc v0.69.1-dev ↔ frps v0.62.1：✅ 跨小版本兼容
- Token 认证：✅ 正常工作
- transport.useEncryption：✅ 加密连接成功
- TCP 代理隧道：✅ SSH 完全可达
- SSH host key 指纹法：✅ 可区分正确路由 vs 中间人
