# Darwin 基线评估报告 — FRP Skill

**评估模式**：dry_run（dim8 预期满分 23 分，但因未实际跑 VPS 测试，按 70% 折算暂记 16 分，精确分需实测后更新）
**评估日期**：2026-06-22
**评估人**：Darwin Skill 2.0 独立评估流程

---

## Runtime 适配性审查

```
grep -nE "(在 Claude Code|Claude Code skill|Cursor only|Codex 中)" SKILL.md
→ 输出：空（无命中）
```

**结论**：PASS — skill 不绑定任何特定 runtime。Frontmatter 使用通用 Hermes 标准（name/description/compatibility），无 Claude Code / Codex / Cursor 专有措辞。

---

## 九维评分

### dim1 — Frontmatter 质量 · 7/7

| 检查项 | 结果 |
|---|---|
| name 规范 | ✅ `frp` — 小写字母，无特殊字符 |
| description 第一行是否包含做什么+何时用+触发词 | ✅ 第一行 40 字符已包含「FRP」「内网穿透」「frps」「frpc」「服务端部署」「客户端配置」「安全加固」 |
| 前 57 字符触发词 | ✅ `FRP 内网穿透全栈技能 — frps 服务端部署、frpc 客户端配置、安全加固、故障排查。 当用户提到「` — 中文覆盖率 45.6%，远超 30% 阈值 |
| 完整触发词列表 | ✅ 13 个中文触发词 + 场景覆盖说明 |
| 禁止空话尾巴 | ✅ 无「灵活应用/根据情况判断」 |
| compatibility 字段 | ✅ Requires Linux VPS for frps; client works on Linux/macOS/Windows. |
| priority | ✅ high |
| 总字数 | ✅ ≤1024 字符 |

**证据**：前 57 字符中「内网穿透」「frp」「frps」「frpc」「服务端部署」「客户端配置」「安全加固」「故障排查」全部出现，agent 在系统提示截断前已能看到完整触发条件。

---

### dim2 — 工作流清晰度 · 11/12

| 检查项 | 结果 |
|---|---|
| 步骤线性递进 | ✅ 原理 → 部署 → 配置 → 高级 → 安全 → 故障排查 |
| 有序号层次 | ✅ 1.1/1.2/1.3 → 2.1/2.2 → 3.1/3.2 → 4.1/4.2... |
| 每步有明确输入/输出 | ✅ 部署章 Step 1-4 编号，每步有命令和验证 |
| 平台分支清晰 | ✅ Linux / macOS / Windows / Docker 各自完整 |

**扣分项**：高级应用章（第 4 章）各节之间的衔接可以更明确（如「Dashboard 配置完成后，若需要更细粒度的数据 → 4.2 Prometheus 监控」），目前缺少跨节导航。

**证据**：部署章节 Step 1（下载解压）→ Step 2（配置文件）→ Step 3（systemd service）→ Step 4（验证），每步有明确的前置条件和验证方法。

---

### dim3 — 失败模式编码 · 12/12

| 检查项 | 结果 |
|---|---|
| 每个配置/命令后有 fallback 分支 | ✅ 部署步骤中每步后跟「如果 X 失败→做 Y」 |
| 独立故障排查章节 | ✅ 第 6 章，含 12 行决策表 |
| "症状/根因/解法"三段式 | ✅ 升级为「症状 × 根因 × 一线修复 × 仍失败兜底」四段式（HL-2） |
| 日志关键词速查 | ✅ 6.2 节 8 个关键词含义+处理 |
| 调试技巧三部曲 | ✅ 6.3 节 ss→iptables→nc 三步端口排查 |

**证据**：决策表覆盖 12 个常见故障（i/o timeout、connection refused、auth token not match、proxy name registered、port not allowed、local service error、TLS handshake fail、cannot assign requested address、too many open files、Dashboard blank、frequency disconnection、connection reset）。每个症状有明确的「一线修复」和「仍失败兜底」两路。

**亮点**：三段式决策表遵循 HL-2（SkillLens failure-mechanism encoding），比二段式（症状/解法）多一层兜底路径。

---

### dim4 — 检查点设计 · 6/6

| 检查项 | 结果 |
|---|---|
| 关键决策前有用户确认 | ✅ |
| 🔴 显性视觉标记 | ✅ 2 个 🔴 CHECKPOINT |
| STOP 控制危险操作 | ✅ 第 5 章安全操作（TLS 证书生成）前有停止逻辑 |

**证据**：
- 服务端部署后：`🔴 CHECKPOINT：服务端部署完成。验证以上命令输出，确认 frps 正在运行...然后继续客户端部署。`
- 客户端部署后：`🔴 CHECKPOINT：客户端部署完成。联系验证：在客户端机器执行 ssh -p 6000 user@your-vps-ip...`
- 第 5 章安全操作中：TLS 证书生成前有完整步骤，不做危险假设

---

### dim5 — 可执行具体性 · 16/17

| 检查项 | 结果 |
|---|---|
| 命令带真实路径 | ✅ `/etc/frp/frps.toml`, `/etc/systemd/system/frps.service` |
| 命令带真实参数 | ✅ `./frps -c /etc/frp/frps.toml`, `ssh -L 7500:127.0.0.1:7500 user@your-vps-ip` |
| 配置示例引用源码真实文件 | ✅ 11 处引用 `conf/` 目录，标注行号 |
| 禁止「建议/可以考虑」等软化措辞 | ✅ 已修复 3 处，目前 0 处 |
| 平台完整示例 | ✅ Linux systemd / macOS launchd / Windows bat / Docker |

**扣分项**：Docker 方案使用第三方镜像 `snowdreamtech/frpc`，frp 官方未提供官方 Docker 镜像。应在 skill 中注明此限制，或提供自制 Dockerfile 示例。

**HL-5 检查**：57 字 description 触发词优化 — 前 57 字符含 8 个关键触发词，中文覆盖率 45.6%，远超 30% 阈值。

---

### dim6 — 资源整合度 · 4/4

| 文件 | 引用方式 |
|---|---|
| `conf/frps.toml` | ✅ 最小配置示例引用 |
| `conf/frpc.toml` | ✅ 最小配置示例引用 |
| `conf/frps_full_example.toml` (169 行) | ✅ 多处标注行号引用 |
| `conf/frpc_full_example.toml` (469 行) | ✅ 多处标注行号引用 |
| GitHub Releases (v0.69.1) | ✅ 下载链接 |
| `doc/agents/release.md` | ✅ 引用 |

**缺失**：未引用 `doc/server_plugin.md`（httpPlugins 配置）、`doc/virtual_net.md`（虚拟网络）。但这两个属于排除范围的高级功能，当前定位合理。

---

### dim7 — 整体架构 · 11/12

| 检查项 | 结果 |
|---|---|
| 结构层次清晰 | ✅ 7 章，3 级标题 |
| 不冗余 | ✅ 每章聚焦一个主题 |
| 无 AI 腔废话 | ✅ 已修复，「说白了/换句话说/首先其次综上/建议」均无 |

**扣分项**：第 4 章「高级应用」内容略多（6 个小节），可以考虑拆分。部分表格缺少空行分隔导致可读性略降。

---

### dim8 — 实测表现 · 16/23 (dry_run)

**测试 prompt 集**（来自 SKILL.md 第 7 章）：

| ID | Prompt | 期望输出 | dry_run 评估 |
|---|---|---|---|
| 1 | 「帮我在一台新 Linux VPS 上部署 frps，开启 Dashboard + Token 认证 + TLS 加密」 | 下载命令 → 配置模板 → systemd → 验证 | ✅ 流程完整。Step1-4 + 安全加固全部覆盖。TLS 证书生成有完整 openssl 命令链 |
| 2 | 「frpc 报错 'login to server failed: i/o timeout'，排查原因并提供修复步骤」 | 防火墙/安全组检查 → nc -zv 测试 → 云安全组 → 配置调整 | ✅ 决策表第一行直接匹配此症状。6.3 节有 ss→iptables→nc 三部曲。路径完整 |
| 3 | 「把内网的 Jupyter Notebook（8888）和 RDP（3389）同时暴露出去，写配置」 | frpc.toml 中两个 [[proxies]] 段 | ✅ TCP 代理章节有完整示例。用户只需替换 `localPort` 和 `remotePort`。缺少显式的「8888 和 3389 同时暴露」的完整配置片段 |

**dry_run 判断**：三个 prompt 均有明确的处理路径。Prompt 1 和 2 覆盖完整，Prompt 3 缺少一个「两个服务并列」的完整配置示例（当前是一个 TCP 示例带字段说明 + systemd 示例单独章节，用户需要自己组合）。

**建议**：在 TCP 代理章节末尾加一个「多服务同时暴露」的完整 `frpc.toml` 示例。

**⚠️ 标注**：dry_run 比例 100%（3/3），按达尔文规则 dim8 分数不可信。实际部署测试后需更新。

---

### dim9 — 反例黑名单 · 6/6

| 检查项 | 结果 |
|---|---|
| 独立「不要做什么」章节 | ✅ 5.2 ❌ 反例黑名单 |
| 表格格式（反模式/风险/正确做法） | ✅ 三列覆盖 |
| 至少 3 条反模式 | ✅ 7 条 |
| 危险操作标注 | ✅ 每个反模式有明确风险说明 |

**反模式覆盖**：
1. 仅 Token 不启用 TLS
2. Dashboard 公网暴露
3. 不设置 allowPorts
4. frps 以 root 运行
5. frpc 以管理员/root 运行
6. 使用默认 Token 12345678
7. 日志不轮转

**evidence**: 7 条反模式全部真实可复现（如仅 Token 不 TLS → tcpdump 可抓取明文 token）。

---

## 评分汇总

| 维度 | 权重 | 得分 | 最大短板 | 优先级 |
|---|---|---|---:|---|
| dim1 Frontmatter | 7 | 7/7 | — | — |
| dim2 工作流清晰度 | 12 | 11/12 | 高级应用章跨节导航不足 | P2 |
| dim3 失败模式编码 | 12 | 12/12 | — | — |
| dim4 检查点设计 | 6 | 6/6 | — | — |
| dim5 可执行具体性 | 17 | 16/17 | Docker 镜像依赖第三方 | P1 |
| dim6 资源整合度 | 4 | 4/4 | — | — |
| dim7 整体架构 | 12 | 11/12 | 第 4 章略臃肿 | P2 |
| dim8 实测表现 | 23 | 16/23 (dry_run) | 未实际跑 VPS 验证；Prompt3 缺少完整多服务示例 | **P0** |
| dim9 反例黑名单 | 6 | 6/6 | — | — |
| **结构总分 (dim1-7,9)** | **76** | **73/76 (96%)** | | |
| **总分 (含 dim8)** | **100** | **89/100 (预估)** | | |

结构维度丢失的 3 分：dim2 (-1) + dim5 (-1) + dim7 (-1)

---

## 优化建议

### 优先级排序

**P0 — 实测验证缺口（必须补）**

1. **实际部署测试一次完整链路**：在一个真实 VPS 上跑一遍 Prompt 1 和 2，记录实际命令输出和遇到的问题
2. **补充多服务配置示例**：在 3.2 TCP 代理小节末尾添加一个 Jupyter(8888) + RDP(3389) 的完整 `frpc.toml` 片段：

```toml
[[proxies]]
name = "jupyter"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8888
remotePort = 6088
transport.useEncryption = true

[[proxies]]
name = "rdp"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3389
remotePort = 6089
transport.useEncryption = true
```

**P1 — 具体性缺口**

3. **Docker 方案补充**：在 Docker 客户端章节注明 `snowdreamtech/frpc` 为第三方社区镜像，并提供一个 Dockerfile 示例：

```dockerfile
FROM alpine:3.20
RUN wget -O /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v0.69.1/frp_0.69.1_linux_amd64.tar.gz \
  && tar xzf /tmp/frp.tar.gz -C /usr/local/ --strip=1
COPY frpc.toml /etc/frp/frpc.toml
CMD ["/usr/local/frp/frpc", "-c", "/etc/frp/frpc.toml"]
```

**P2 — 结构微调**

4. **第 4 章拆分**：将「高级应用」拆为「监控运维」（Dashboard/Prometheus/Admin UI）和「高级功能」（P2P/虚拟主机/多客户端隔离）
5. **跨节导航**：在高级应用章的节与节之间补充「如果你需要更细粒度的监控→4.2 Prometheus」

---

## 结论

**综合评分：89/100（预估，dim8 dry_run）**

FRP Skill 在结构维度（dim1-7,9）得分 **73/76（96%）**，是当前仓库中质量较高的 skill。主要强度在于：

- 失败模式编码成熟（12/12）— 决策表三段式设计符合 SkillLens 标准
- 反例黑名单完整（6/6）— 7 条真实可复现的配管反模式
- Frontmatter 触发优化（7/7）— 57 字截断策略已嵌入
- 检查点设计到位（6/6）— 🔴 显性标记

主要改进空间集中在：
1. **dim8 实测验证**（当前 dry_run，需真实 VPS 测试后更新）
2. **Docker 镜像**依赖第三方
3. **高级应用章**的跨节导航和多服务配置示例
