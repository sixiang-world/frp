# FRP Skill 创作报告

## 验料结论

**这个 skill 值得做吗？为什么？**

**结论：值得做，而且有明确的市场缺口。**

理由：

1. **用户基数大、需求刚性**：frp（fatedier/frp）是 GitHub 上 91k+ stars 的开源项目，是中国最流行的内网穿透工具。每个需要暴露内网服务的人都要经历「部署 frps → 配置 frpc → 调试 → 加固」的完整链路，这个链路内的每一步都有踩坑点。

2. **唯一完全自托管的全协议方案**：在同类工具中（见下），只有 FRP 支持 TCP/UDP/HTTP/HTTPS/STCP/XTCP 全部协议且完全自托管。这意味着它的配置维度和安全责任远超 Ngrok（纯 SaaS、一行命令）和 Cloudflare Tunnel（需域名、依赖 CF）。

3. **已有 skill 质量极低**：GitHub 上唯一的 FRP agent skill（feng3d-labs/frp-skill）仅有 0 stars，只提供了简单的部署脚本+模板，缺乏安全、故障排查、高级配置等核心内容。这是一个清晰的市场空白。

4. **「内网穿透」是高频触发词**：无论是远程办公、开发调试、IoT 管理，还是 demo 展示，内网穿透都是 agent 用户的常见需求。一个高质量的 FRP skill 可以成为用户长期依赖的工具。

### 定位判断

**不是「又一个部署脚本」**。现有的 frp-skill 已经提供了基本的部署能力。

**这是「FRP 运维知识库」**—— 一个 agent 可执行的 FRP 全栈操作指南。覆盖从「理解架构」到「生产部署」到「安全加固」到「故障诊断」的完整生命周期。agent 不需要每次都问用户「你的 frps 在哪」，而是可以直接指导用户完成完整部署。

核心差异化：深度 ≈ 官方文档的水平，但可执行性 > 官方文档（每个配置项后跟「失败怎么办」、「checkpoint 等待确认」）。

---

## 访行记录

### 调研同类 skill

| 同类 Skill | 链接 | 类型 | 一句话定位 | 可学的手艺 | 不能照搬的点 |
|---|---|---|---|---|---|
| feng3d-labs/frp-skill | https://github.com/feng3d-labs/frp-skill | 直接 | frp 内网穿透 npm 包集合，提供 frps/frpc 部署脚本和模板 | 模板的简洁性、Windows 客户端杀软处理 | 太浅——只有部署脚本，无安全/故障排查/高级配置 |
| ngrok/agent-skills (expose-localhost) | https://github.com/ngrok/agent-skills | 间接 | 官方 ngrok skill，一行命令暴露本地服务 | 「先问清楚再执行」的交互模式、Traffic Policy 示例、前端确认流程 | ngrok 是 SaaS 产品，不需要自建服务器，复杂度低很多 |
| xiaoyuboi/cloudflare-tunnel-skill | https://github.com/xiaoyuboi/cloudflare-tunnel-skill | 间接 | Cloudflare Tunnel 工作流，支持 Quick Tunnel 和 Named Tunnel | 85 stars 的传播力说明「解决真实问题」比「功能多」重要、双语言 README、脚本与 skill 分离 | Cloudflare Tunnel 的自身体系（域名、Tunnel Token），不能直接映射到 FRP |
| OctavianTocan/cloudflared-tunnel-ops | https://github.com/OctavianTocan/cloudflared-tunnel-ops | 间接 | cloudflared tunnel ops skill | 简洁的 frontmatter 设计 | 功能单一 |

### 调研搜索词

- `frp skill SKILL.md github` → 找到 feng3d-labs/frp-skill
- `ngrok agent skill` → 找到 ngrok/agent-skills
- `cloudflare tunnel agent skill` → 找到 xiaoyuboi/cloudflare-tunnel-skill 等

### 差异化定位

| 维度 | 现有 frp-skill | 本 Skill |
|---|---|---|
| 覆盖范围 | 仅部署 | 原理 → 部署 → 配置 → 高级 → 安全 → 故障排查 |
| 配置文件 | 提供模板 | 引用源码 `conf/` 目录，标注行数 |
| 安全加固 | 无 | 独立章节 + 反例黑名单 + 7 条反模式 |
| 故障排查 | 无 | 决策表（12 行）+ 日志关键词 + 调试技巧 |
| 检查点 | 无 | 🔴 CHECKPOINT 在关键步骤后等待确认 |
| 测试验证 | 无 | 3 个测试 prompt |
| 资源引用 | 无 | 引用源码 `conf/` 和 `doc/` 中的真实文件 |

---

## 质量自评（达尔文 9 维）

| 维度 | 自评分 | 评语 |
|---|---|---|
| dim1 Frontmatter | 7/7 | description 前 57 字符包含「FRP 内网穿透全栈技能」，覆盖 frps/frpc/内网穿透/安全加固/故障排查等触发词。兼容性字段标注。priority=high |
| dim2 工作流清晰度 | 11/12 | 按「理解原理 → 部署 → 配置 → 高级 → 安全 → 故障排查」线性递进，每章有明确的输入/输出。部署章节按 Step 1-4 编号。扣 1 分因为部分章节标题可进一步对齐（但整体清晰度达标） |
| dim3 失败模式编码 | 12/12 | 每个配置/命令后跟条件分支（「如果 X 失败 → 做 Y」）。独立的故障排查章节含 12 行决策表 + 日志关键词速查 + 调试技巧 |
| dim4 检查点 | 6/6 | 两个 🔴 CHECKPOINT（服务端部署完成、客户端部署完成），在第 5 章安全操作前有明确停止逻辑（「SSL 自签证书生成」需先确认再替换生产配置） |
| dim5 可执行具体性 | 16/17 | 所有命令带真实路径（`/etc/frp/frps.toml`）和参数（`./frps -c /etc/frp/frps.toml`），配置示例引用 `conf/` 真实文件路径。扣 1 分因为 Docker 例子中 `snowdreamtech/frpc` 镜像来自第三方，可能有兼容性问题 |
| dim6 资源整合度 | 4/4 | 引用源码 `conf/frps.toml`、`conf/frpc.toml`、`conf/frps_full_example.toml`（169行）、`conf/frpc_full_example.toml`（469行），引用 `doc/agents/release.md`，引用 GitHub Releases 下载链接 |
| dim7 整体架构 | 11/12 | 7 个章节层次递进、不冗余。禁用 AI 腔。扣 1 分因为「高级应用」章节的 P2P 与虚拟主机路由之间可再加一层分离 |
| dim9 反例黑名单 | 6/6 | 独立 5.2 ❌ 反例黑名单，7 条反模式（表格化），覆盖「仅 Token 无 TLS」「Dashboard 公网」「不设 allowPorts」「root 运行」「默认 Token」「日志不轮转」 |
| **结构总分** | **73/76** | |

（dim8 实测表现留白，由后续达尔文评估跑测试 prompt 打分。当前版本为 dry-run 预估。）

---

## 已知待改进

1. **缺少脚本资产（scripts/）**：当前版本只提供了可执行的命令模板，未包含可直接下载的自动化脚本（如 `setup-frps.sh`、`generate-tls-certs.sh`）。后续应补充 `scripts/` 目录。

2. **缺少 reference 文件**：
   - `references/parameters.md`：完整参数参考表
   - `references/troubleshooting.md`：独立的排错手册（可被其他 skill 引用）
   - `references/deploy-checklist.md`：部署核对清单

3. **Docker 镜像来源**：当前使用了第三方镜像 `snowdreamtech/frpc`，应同时提供官方 Dockerfile 方案或指向 frp 官方镜像（frp 官方尚未有官方 Docker 镜像）。

4. **Windows 客户端配置不够详细**：Windows 的 frpc 安装和自启部分较为简略，缺少 PowerShell 脚本、缺少杀软白名单自动配置脚本。

5. **没有实测运行过**（dim8 留白）：skill 中的所有命令和配置在写时已验证语法正确性，但未在实际 VPS 上完整跑通。需要后续达尔文评估实际跑一遍。

6. **SSH Tunnel Gateway 未覆盖**：frp v0.52+ 的 SSH Tunnel Gateway 功能（`sshTunnelGateway`）在 `conf/frps_full_example.toml` 中有配置示例，但当前 skill 未覆盖。这是一个重要的高级特性。

---

## 后续优化方向

### 实测修正（2026-06-22 真实 VPS 测试后）

以下内容已在真实测试后得到验证或修正：

**已验证的流程：**
- ✅ frpc 源码构建（`make frpc`）→ 启动 → 连接 frps → 注册代理 → 全部通过
- ✅ TCP 代理端口转发：`47.77.227.16:6102` → 本机 `127.0.0.1:8080`（HTTP 200 返回）
- ✅ UDP DNS 代理：`47.77.227.16:6103` → `8.8.8.8:53`（`dig +short google.com` 返回 IP）
- ✅ STCP 安全 TCP：visitor 模式两 frpc 实例成功互通
- ✅ frpc v0.69.1-dev 兼容 frps v0.62.1（跨小版本兼容）

**验证后发现的修正：**
- ❌ SKILL 中写的是 `GET /api/status` → 实际该端点不存在，改为 `GET /api/serverinfo`
- ✅ 新增了 `/api/serverinfo`、`/api/clients`、`/api/v2/proxies?offset=0&limit=20` 等真实端点
- ✅ 日志关键词（`login to server success`、`start proxy success`、`join connections`）与真实输出完全一致

### 短期（1-2 轮迭代）

1. **补充 scripts/ 目录**
   - `scripts/setup-frps.sh`：一键部署 frps（下载 + 配置 + systemd + 防火墙）
   - `scripts/setup-frpc.sh`：一键部署 frpc（下载 + 配置 + systemd）
   - `scripts/generate-tls.sh`：生成 TLS 自签证书

2. **补充 references/ 目录**
   - `references/parameters.md`：完整参数参考表
   - `references/troubleshooting.md`：故障排查手册

3. **运行达尔文评估**
   - 用 3 个测试 prompt 实际跑一遍 skill
   - 发现 missing 的步骤或错误的命令
   - 补上 dim8 实测得分

### 中期（3-5 轮迭代）

4. **覆盖 SSH Tunnel Gateway**
   - 这是 frp v0.52 的重要新特性，是完整技能必须覆盖的内容
   - 对比 Ngrok 的 SSH 反向隧道功能

5. **扩展 Windows 客户端文档**
   - PowerShell 自启脚本
   - 杀软白名单配置
   - 注册为 Windows Service（使用 `nssm`）

6. **补充 Server Plugin 章节**
   - 引用 `doc/server_plugin.md` 的内容
   - 给出自定义 HTTP 插件的配置示例

### 长期

7. **创建自动化测试框架**
   - 用 Docker Compose 搭建本地 frps + frpc 测试环境
   - 自动化验证每种代理类型（tcp/udp/http/https/stcp/xtcp）
   - 验证安全配置的正确性

8. **FRP v2 兼容性准备**
   - 跟踪 fatedier/frp v2 开发进度
   - v1 → v2 迁移指南

9. **多 Agent Runtime 兼容**
   - 当前面向 Claude Code / Hermes Agent 格式
   - 测试在 Codex / OpenCode / Cursor 等 runtime 上的兼容性

---

## 文件交付清单

| 文件 | 路径 | 行数 | 状态 |
|---|---|---|---|
| SKILL.md | `skills/frp/SKILL.md` | ~520 行 | ✅ 已创建 |
| creation-report.md | `skills/frp/creation-report.md` | 本篇 | ✅ 已创建 |
