# FRP Skill

> 从部署到排错，一次就把 FRP 隧道跑通。

[装即用 · Agent Skills · fatedier/frp](https://github.com/fatedier/frp)

## 什么时候用它？

- 你要在内网机器上部署 frpc，连到公网 VPS 的 frps
- frpc 报错 `i/o timeout`、`auth token not match`，需要排错
- 要把内网的 Jupyter/RDP/SSH/Web 一起暴露出去
- 你需要加固 frp 安全配置，不想被扫描器盯上

## 快速开始

这个 skill 嵌在 [fatedier/frp](https://github.com/fatedier/frp) 仓库的 `skills/frp/` 下。
打开仓库后 agent 自动加载。直接说：

> 部署 frps，开启 Dashboard + Token 认证 + TLS 加密
> 帮我把本地 8888 端口（Jupyter）暴露到公网
> frpc 报 i/o timeout，排查原因

## 它会交付什么

| 场景 | 交付物 |
|---|---|
| 部署服务端 | frps systemd 服务 + Dashboard 访问方式 |
| 部署客户端 | frpc 运行 + 隧道验证结果 |
| 暴露多个服务 | 完整 frpc.toml 配置片段 |
| 故障排查 | 症状定位 → 根因分析 → 修复步骤 |

## 触发方式

在 agent 中说以下任意一句话即可触发：

- 「内网穿透」「暴露本地服务」
- 「部署 frps」「配置 frpc」
- 「frp 安全加固」「frp 排错」
- 「把内网 SSH/HTTP/RDP 暴露出去」

## 它和同类有什么不同？

| 对比项 | FRP Skill | 其他 tunnel skill |
|---|---|---|
| 部署模式 | 自托管（源码仓库内嵌） | SaaS / 独立仓库 |
| 故障排查 | 12 行四段式决策表 + 日志速查 | 无或简短 |
| 安全加固 | 7 条反模式黑名单 | 无 |
| 代理类型覆盖 | TCP/UDP/HTTP/STCP/XTCP | 仅 HTTP(S) |
| 实测验证 | 已对阿里 frps 真实 VPS 测试 | 无实测记录 |

## 安全边界

- 不会在无确认时修改 frps/frpc 生产配置
- 所有部署命令明确显示在终端中，不会静默执行
- Dashboard 凭证和 Token 由用户自行设置，skill 不存储
- 涉及暴露端口时提醒设置 `allowPorts` 限制

## 文件结构

```
skills/frp/
├── SKILL.md              # 技能本体（原理/部署/配置/安全/排错）
├── README.md             # 本文件 — 独立展示页
├── test-prompts.json     # 验证 prompt 集
├── creation-report.md    # 创作报告
├── darwin-evaluation.md  # 达尔文评估报告
├── luban-report.md       # 鲁班打磨报告
├── references/           # 参考文件（参数表、排错手册）
├── scripts/              # 一键部署脚本
└── assets/               # 运行截图和输出样例
```
