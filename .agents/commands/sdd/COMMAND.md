---
name: sdd
description: "通用 SDD 工作流协调器。使用 /sdd start 启动全流程，或按 setup / proposal / brainstorming / spec / build / close 分阶段执行。"
---

# /sdd

这是模板级入口命令，用来把需求带入同一套 SDD 流程。

## 子命令

| 命令 | 作用 |
|------|------|
| `/sdd start` | 从状态检测开始，自动路由到合适阶段 |
| `/sdd setup` | 检查本地依赖、仓库目录和模板配置 |
| `/sdd proposal` | 轻量收敛需求，生成 `proposal.md` |
| `/sdd brainstorming` | 深入讨论方案，适合需求模糊时 |
| `/sdd spec` | 生成 `design.md`、`tasks.md` 与 `specs/` |
| `/sdd build` | 按规格执行实现，强调验证与断点恢复 |
| `/sdd close` | 汇总验证结果并准备归档 |

## 路由原则

1. 如果用户明确指定阶段，优先执行该阶段。
2. 如果未指定，先检查 `.agents/sdd-state.json` 与 `openspec/changes/`。
3. 没有活跃变更时，优先进入 `proposal` 或 `brainstorming`。
4. 有活跃变更但缺规格时，进入 `spec`。
5. 规格齐全但未实现时，进入 `build`。
6. 实现完成后，进入 `close`。
