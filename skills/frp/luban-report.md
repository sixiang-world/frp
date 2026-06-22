# FRP Skill 打磨报告 · 鲁班工坊

> 打磨日期：2026-06-22
> 作品：`skills/frp/SKILL.md`（847 行，28 KB）
> 项目：fatedier/frp（107,477 ★ · 15,075 forks）
> 验收师傅：鲁班

---

## 1. 验料结果（Skill 前提挑战）

**挑战 1 — 真实问题：成立。**

FRP 是 GitHub 上 107K+ stars 的最流行自托管内网穿透工具。每个需要暴露内网服务的人都必须走「部署 frps → 配置 frpc → 调试 → 加固」的完整链路。Agent 用户频繁提出「内网穿透」「暴露本地服务」「frp 配置」等需求，现有 agent 缺乏可执行的 FRP 知识库。

**挑战 2 — 独特角度：成立。**

唯一性来自两点：(a) **方法论** — 按「原理→部署→配置→安全→诊断」线性递进，既是操作手册又是排错指南，不同于纯命令列表；(b) **源码整合** — 直接引用该项目 `conf/` 目录下的 4 个真实 `.toml` 配置文件并标注行号，与仓库同源同维护。

**挑战 3 — 安装理由：部分成立。**

它被安装在 frp 仓库内部，天然与项目绑定。对任何使用此仓库的开发者来说，agent 打开目录时自动加载，不需要额外安装步骤。但作为独立 skill 发布到 ClawHub/skills.sh 时，缺少一键安装脚本和 standalone README。

**挑战 4 — 公共传播性：成立。**

一句话钩子：「从部署到排错，完整 FRP 运维知识库。」可展示产物包括：Dashboard API 调用截图、故障决策表对比、TCP/UDP/STCP 三种代理类型的成功测试输出。

**验料结论：好料，继续打磨。**

---

## 2. 访行记录（同类 Skill 横向对标）

| 同类 Skill | 链接 | 类型 | 一句话定位 | 可学的手艺 | 不能照搬的点 |
|---|---|---|---|---|---|
| feng3d-labs/frp-skill | [GitHub](https://github.com/feng3d-labs/frp-skill) | **直接** | frp 内网穿透 npm 包，0 stars，仅部署脚本+模板 | 安装路径简洁（`npx skills add`），模板分离资产 | 无安全/故障排查/高级特性，定位太浅 |
| ngrok/agent-skills (expose-localhost) | [GitHub](https://github.com/ngrok/agent-skills) | **间接** | 官方 ngrok skill，一行命令暴露本地服务，12 stars | 「先 ask all questions upfront」的交互模式，Traffic Policy 示例 | ngrok 是 SaaS 无需自建服务，复杂度低 |
| xiaoyuboi/cloudflare-tunnel-skill | [GitHub](https://github.com/xiaoyuboi/cloudflare-tunnel-skill) | **间接** | Cloudflare Tunnel 工作流，85 stars，Quick+Named 双模式 | 双语言 README、脚本与 skill 分离、场景列表（适合/不适合） | 依赖 Cloudflare 域名，与 FRP 的运维模型不同 |
| OctavianTocan/cloudflared-tunnel-ops | [GitHub](https://github.com/OctavianTocan/cloudflared-tunnel-ops) | **手艺** | cloudflared 隧道运维，1 star | 极简 frontmatter 结构 | 功能单一 |
| vicoa-ai/agent-skills (live-preview) | [GitHub](https://github.com/vicoa-ai/agent-skills) | **手艺** | 启动本地服务并通过 tunnel 暴露，0 stars | 自动化端口探测、先检查再启动的工作流（HL-1 模式） | 非 frp 专用，不涉及安全/配置 |

**搜索渠道**：GitHub API (`search/repositories?q=frp+skill+SKILL.md`, `ngrok+agent+skill`, `cloudflare+tunnel+agent+skill`)，覆盖直接/间接/手艺三类。

---

## 3. 生态位判断

**纵向结论**：这个 Skill 从「源码仓库内嵌知识库」出发，下一阶段应走向「独立可发布的公共 Skill 资产」——增加 README、安装脚本、参考文件。

**横向结论**：同类 Skill 的立足点主要来自三要素：安装摩擦低（一行命令）、场景明确（具体问题 vs 泛功能）、展示强（截图/GIF/输出样例）。FRP skill 在深度上远超同行但缺前两样。

**交叉洞察**：我们真正该抢的生态位不是「又一个部署脚本」（已有 frp-skill 做了），也不是「FRP 完整文档」（官方文档已经有了），而是 **「Agent 可执行的 FRP 排障知识库」**——用户说一句话，agent 能一步步带着操作、验证、排错，最终交付一个可用的隧道。

**一句话新定位**：「不教你怎么写 frp 配置，教你一次就把隧道跑通。」

---

## 4. 过尺结果（活体检查 + 九维评分）

### 4.1 活体检查

已做（2026-06-22 真实 VPS 测试）：

| 检查项 | 结果 | 证据 |
|---|---|---|
| **真实运行产物对账** | ✅ 通过 | 本地 frpc → 阿里 frps v0.62.1，TCP/UDP/STCP 三种代理全部验证 |
| **数据新鲜度** | ✅ 新鲜 | skill 创建于 2026-06-22，测试日志即创建日志 |
| **CI 对账** | ⏸ 不适用 | skill 是文档资产，不在 CI 覆盖范围内 |
| **真实渲染** | ⏸ 不适用 | SKILL.md 是纯文本，无页面渲染需求 |
| **真实调用** | ✅ 通过 | 部署命令（`make frpc`、`frpc -c`）、验证命令（`ssh -p`、`curl`、`dig`、`dig`）、API 调用（`/api/serverinfo`）全部实跑且通过 |
| **二进制可用性** | ✅ 通过 | 从源码 `make frpc` 编译成功，连接 frps 成功 |

**纠正项**：实跑后发现 `GET /api/status` 不存在，改为 `GET /api/serverinfo`，已修复。

### 4.2 九维评分

| 维度 | 权重 | 得分 | 主要证据 | 最大短板 | 优先级 |
|---|---:|---:|---|---|---|
| Frontmatter | 7 | **7** | 前 57 字含 8 个触发词，中文覆盖率 45.6% | — | — |
| 工作流清晰度 | 12 | **11** | 7 章线性递进，部署 Step1-4 编号 | 高级章缺跨节导航 | P2 |
| 失败模式编码 | 12 | **12** | 12 行四段式决策表 + 日志速查 + 调试三部曲 | — | — |
| 检查点设计 | 6 | **6** | 2 个 🔴 CHECKPOINT，显性标记 | — | — |
| 可执行具体性 | 17 | **16** | 命令全真路径参数，引用 conf/ 真实文件 | Docker 方案用第三方镜像 | P1 |
| 资源整合度 | 4 | **4** | 引用 conf/ 目录 4 文件、GitHub Releases、doc/ | — | — |
| 整体架构 | 12 | **11** | 结构清晰无冗余，无 AI 腔 | 高级章略臃肿 | P2 |
| 实测表现 | 23 | **16** | TCP/UDP/STCP 三种代理真实 VPS 验证 | 未跑 HTTP vhost 和 XTCP | **P0** |
| 反例与黑名单 | 7 | **7** | 7 条反模式表格化，覆盖安全全场景 | — | — |
| **总分** | **100** | **90** | | | |

**评分依据（关键项明细）：**

- **Frontmatter（7/7）**：`description` 前 57 字符 `FRP 内网穿透全栈技能 — frps 服务端部署、frpc 客户端配置、安全加固、`，含 FRP/内网穿透/frps/frpc/安全加固。`compatibility` 字段声明平台兼容性。`priority=high`。

- **失败模式编码（12/12）**：HL-2 四段式表（症状/根因/一线修复/仍失败兜底）覆盖 12 种故障。独立 6.2 日志关键词 8 条。6.3 调试三部曲（ss→iptables→nc）。

- **检查点设计（6/6）**：部署章结束 🔴 CHECKPOINT（服务端/客户端）。安全章 TLS 证书生成前有完整验证链。HL-1 视觉标记 + 强制性措辞。

- **反例黑名单（7/7）**：5.2 独立章节，7 条反模式（仅 Token 不 TLS / Dashboard 公网 / 不设 allowPorts / root 运行 / 默认 Token / 日志不轮转 / frpc 管理员运行），三列表格（反模式/风险/正确做法）。

- **实测表现（16/23）**：已在阿里 VPS 实跑，覆盖 TCP(UDP/STCP)。未跑 HTTP vhost（阿里 frps 未配置 `vhostHTTPPort`）和 XTCP（需两台独立机器）。实测纠正了 Dashboard API 端点错误。dry_run 比例 0%（全是 full_test）。

---

## 5. 差距清单

### P0：不补就无法公开

- [ ] **实测覆盖不足**：HTTP vhost 和 XTCP 未测试。HTTP 需 frps 开启 `vhostHTTPPort`，XTCP 需两台分离机器
- [ ] **无 standalone README**：skill 目录下无 `README.md`，ClawHub/skills.sh 等平台无法索引
- [ ] **无 test-prompts.json**：测试 prompt 在 SKILL.md §7 中内联，其他工具/agent 无法自动化读取

### P1：补上后明显提升安装率

- [ ] **缺一键安装脚本**：无 `scripts/` 目录。与 feng3d-labs/frp-skill（`npx skills add`）相比安装摩擦高
- [ ] **Docker 镜像来源**：用社区镜像 `snowdreamtech/frpc`，应改为官方 Dockerfile 或注明限制
- [ ] **缺 reference 文件**：`references/parameters.md`（完整参数参考）、`references/troubleshooting.md`（独立排错手册）

### P2：锦上添花

- [ ] **高级章可拆分**：第 4 章 6 个小节，可拆为「监控运维」和「高级功能」
- [ ] **跨节导航**：添加「如需更细粒度监控→4.2」「P2P 打洞失败→6.1」
- [ ] **示例输出截图**：Dashboard 界面、API 返回结果、连接日志等截图入 assets/

### 与同行相比，我们最缺的 3 件事

1. **一键安装路径** — feng3d-labs/frp-skill 用 `npx skills add`，我们的安装路径是「git clone + 手动复制」
2. **独立 README 首屏** — cloudflare-tunnel-skill 有双语言 README 和场景列表达 85 stars
3. **Showcase 可见产物** — 无截图/GIF/输出样例，对手的 README 首屏有可展示结果

### 与同行相比，我们最有机会打穿的 3 件事

1. **与 frp 源码仓库同构** — 其他 skill 是独立仓库，装完还要去 frp 官网查文档；我们的 skill 直接在 frp 仓库内，agent 打开工作目录即可用
2. **排障决策表深度** — 其他 tunnel skill 没有「12 行症状×根因×解法」的故障排查能力
3. **安全反模式清单** — 7 条可直接复现的反模式（同行无安全章节），是运维人员的硬需求

---

## 6. 三个打磨方向

### 方案 A：细修 — 补资产不补内容（推荐）

**新定位**：「源码仓库内嵌知识库 → 可发布的公共 skill 资产」

**改动范围**（只用结构，不改内容）：
- 新增 `README.md` — 一句话钩子 + 触发词 + 快速开始 + 目录结构 + 安全边界
- 新增 `test-prompts.json` — 从 §7 抽取为独立 JSON
- 新增 `scripts/setup-frps.sh` — 一键部署脚本
- 新增 `assets/` — Dashboard 截图、API 返回真实数据截图
- 新增 `.gitignore` for test artifacts

**优点**：
- 改动边界清晰，不引入内容风险
- README 和脚本是 ClawHub/skills.sh 索引的关键，直接影响传播率
- 已有全部内容，组合即可

**风险**：
- 工作量适中（4+ 个新文件），但无技术风险

**适合条件**：需要快速提升传播力的场景。

### 方案 B：精雕 — 补充缺失内容的实测覆盖

**新定位**：「唯一经过真实双机验证的 FRP skill」

**改动范围**：
- 在另一台服务器（如 do-hermes）部署第二个 frps 做 HTTP/XTCP 交叉测试
- 根据测试结果修正确认 HTTP vhost 和 XTCP 配置示例
- 将测试过程的日志、curl 输出、screenshot 沉淀到 `assets/`

**优点**：
- 实测结果可直接作为 showcase 素材（dim8 + 传播力双赢）
- HTTP/XTCP 后完整覆盖 FRP 所有核心代理类型

**风险**：
- 需要配置第二台 VPS 的 frps
- 耗时长于方案 A

**适合条件**：当前 skil 已在生产使用，需要提升可信度的场景。

### 方案 C：开套件 — 升级为 frp 多服务管理套件

**新定位**：「不再是单个 knowledge skill，而是一个 frp 运维工具链」

**改动范围**：
- `skills/frp-manager/` — frps/frpc 进程管理和健康检查（`systemctl status`、自动重启）
- `skills/frp-troubleshoot/` — 纯故障排查 skill（引用但不重复 SKILL.md 第 6 章）
- `skills/frp-config/` — 配置生成器和验证器（`frpc verify`、TOML 语法检查）
- 每个子 skill 共享 `references/` 目录

**优点**：
- 模块复用，适合大规模运维
- 每个子 skill 更专注，减少 SKILL.md 的单文件膨胀
- 与花叔生态的「Dispatcher 模式」对齐

**风险**：
- 大幅度改动，需要用户预确认（鲁班强制停手点）
- 当前 SKILL.md 847 行尚未到需要拆分的阈值

**适合条件**：用户已稳定使用当前 skill 一段时间，确认需要切分。

---

### 推荐选择：方案 B（精雕）

**推荐理由**：
- 当前 skill 的结构质量高（维度总分 90），最大的短板是实测覆盖不全（dim8 得分仅 16/23）
- 路径最清晰：在另一台机器起 frps → 测试 HTTP + XTCP → 将过程沉淀为 assets
- 实测产物可直接提升展示和传播力
- 方案 A 可并行进行（README + scripts 不依赖实测）
- 方案 C 为时过早，SKILL.md 远未到拆分临界点

**🔴 STOP：等用户确认方向再继续慢刨。**

---

## 7. 候选改写方案（待方向确认）

> 以下改写基于**方案 B（精雕）** 路线，待用户确认后执行。

### 本轮只刨

**面 1**：新增 `README.md` + `test-prompts.json`（与实测不冲突，可先行）
**面 2**：HTTP vhost 测试 + XTCP 交叉测试（需第二台 frps）
**面 3**：将测试日志/curl 输出/screenshot 沉淀到 `assets/` 和 SKILL.md 相应章节

### 建议文件变更

| 文件 | 操作 | 原因 |
|---|---|---|
| `skills/frp/README.md` | **新增** | ClawHub 索引必备；一句话钩子+快速开始 |
| `skills/frp/test-prompts.json` | **新增** | §7 内联 prompts 标准化为可解析 JSON |
| `skills/frp/scripts/setup-frps.sh` | **新增** | 一键部署 frps（下载+配置+systemd+防火墙） |
| `skills/frp/assets/dashboard-api.png` | **新增** | Dashboard API 返回真实截图 |
| `skills/frp/SKILL.md` | **修改** | HTTP vhost 示例验证后修正、XTCP 双机测试报告补充 |
| `skills/frp/.gitignore` | **新增** | 排除 `frpc-test*.toml`、`frpc-test*.log` |

### 验证方式

1. HTTP vhost 测试：在 do-hermes 起 frps 设 `vhostHTTPPort=80` → frpc 注册 HTTP proxy → `curl -H "Host: test.frps.com"` 验证
2. XTCP 测试：do-hermes frps 作为信令 → 两台 frpc（当前机器 + 另一机器）注册 XTCP → SSH 直连验证
3. README 有效性：首次见到的人能否在 10 秒内理解 skill 用途

---

## 8. README 与 Showcase 升级建议

### README 草案

```markdown
# FRP Skill

> 从部署到排错，一次就把 FRP 隧道跑通。

[装即用 · Agent Skills · fatedier/frp]

## 什么时候用它？

- 你要在内网机器上部署 frpc，连到公网 VPS 的 frps
- frpc 报错 `i/o timeout`、`auth token not match`，需要排错
- 要把内网的 Jupyter/RDP/SSH/Web 一起暴露出去
- 你需要加固 frp 安全配置，不想被扫描器盯上

## 快速开始

这个 skill 嵌在 [fatedier/frp](https://github.com/fatedier/frp) 仓库中。
打开仓库后，agent 自动加载。直接说：
「部署 frps，开启 Dashboard + Token 认证 + TLS 加密」

## 目录

- `SKILL.md` — 技能本体（原理/部署/配置/安全/排错）
- `test-prompts.json` — 验证 prompt 集
- `scripts/` — 一键部署脚本
- `assets/` — 运行截图和输出样例
```

### Showcase 优先级

1. **GIF**：`assets/demo-tcp-tunnel.gif` — 从 curl 到 ssh 到 tunnel 全流程 30 秒
2. **截图**：Dashboard 界面、API `/api/serverinfo` 返回、故障决策表
3. **示例输出**：`test-prompts.json` 中每个 prompt 的执行结果（真实服务器输出）

---

## 9. 执行计划

### 24 小时内完成

- [ ] **方向确认**：等待用户对方案 B 的确认
- [ ] `README.md` + `test-prompts.json` + `.gitignore` 新增
- [ ] 文档化 HTTP vhost 测试方案

### 3 天内完成

- [ ] HTTP vhost 测试（在 do-hermes 起第二台 frps）
- [ ] 根据测试结果修正 SKILL.md 中 HTTP 代理章节
- [ ] XTCP 双机测试

### 7 天内完成

- [ ] `assets/` 截图和示例输出
- [ ] `scripts/setup-frps.sh` 一键脚本
- [ ] 全量 commit + push

### 本轮不做

- 不拆分子 skill（SKILL.md 仅 847 行，远未到必须拆分的阈值）
- 不补充 Windows 自动化脚本（已有详细文档，缺的是实机测试）
- 不补充 Server Plugin 章节（属于排除边界）

---

## 10. 出师证书

```
┌────────────────────────────────────────┐
│         出师证书 · 鲁班工坊              │
│                                        │
│  作品：FRP Skill                        │
│  过尺：打磨前 90 分 → 打磨后 92 分（估） │
│  定位：Agent 可执行的 FRP 排障知识库      │
│  绝活：12 行四段式故障决策表 + 7 条        │
│        可复现安全反模式                   │
│  下一步：HTTP vhost + XTCP 双机实测       │
│                                        │
│  验收师傅：鲁班                          │
└────────────────────────────────────────┘
```

---

## 11. 回炉清单

### 对标观察

| 同行 | 观察点 | 检查频率 |
|---|---|---|
| feng3d-labs/frp-skill | 是否新增安全/排错内容 | 每月 |
| xiaoyuboi/cloudflare-tunnel-skill | README 组织方式、stars 增长 | 每月 |
| ngrok/agent-skills | 交互模式更新、Traffic Policy 变化 | 每季度 |
| fatedier/frp 官方 | 配置格式变更（v2 的 TOML 变化）、新代理类型 | 每次 release |

### 迭代纪律

- 每次 frp release 后检查 SKILL.md 是否需要更新兼容性
- 每次打磨后 commit 即 push
- 测试脚本固化到 `scripts/`，不在 terminal 中即兴写

### 下一轮入口

- HTTP vhost 测试完成后的 SKILL.md 修正
- 双机 XTCP 测试完成后的补充内容
- 如果用户反馈排版/可读性问题，优先优化

---

## 12. 需要用户确认的问题

1. **打磨方向**：方案 B（精雕 — 补充 HTTP vhost + XTCP 实测覆盖）是当前推荐路线，是否同意？
2. **测试资源**：HTTP vhost 测试需要在当前机器（do-hermes）起一个临时 frps，是否允许？
3. **发布范围**：README 和 scripts 完成后，是否要将此 skill 发到 ClawHub/skills.sh？

---

## 13. 附录：参考来源

- [feng3d-labs/frp-skill](https://github.com/feng3d-labs/frp-skill) — 直接同行
- [ngrok/agent-skills (expose-localhost)](https://github.com/ngrok/agent-skills) — 间接同行
- [xiaoyuboi/cloudflare-tunnel-skill](https://github.com/xiaoyuboi/cloudflare-tunnel-skill) — 间接同行
- [OctavianTocan/cloudflared-tunnel-ops](https://github.com/OctavianTocan/cloudflared-tunnel-ops) — 手艺同行
- [vicoa-ai/agent-skills (live-preview)](https://github.com/vicoa-ai/agent-skills) — 手艺同行
- [fatedier/frp Releases](https://github.com/fatedier/frp/releases) — 官方
- [fatedier/frp conf/](https://github.com/fatedier/frp/tree/dev/conf) — 配置参考
