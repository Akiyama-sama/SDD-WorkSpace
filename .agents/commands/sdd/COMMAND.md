---
name: sdd
description: "通用 SDD 工作流协调器。使用 /sdd start 启动全流程编排、/sdd setup 初始化环境、/sdd proposal 轻量提问、/sdd brainstorming 深度设计、/sdd spec 生成规格、/sdd build 执行实现、/sdd close 验证归档。"
---

# sdd - 工作流协调器

根据用户调用的子命令和项目当前状态，路由到对应阶段。

## 子命令

| 命令 | 阶段 | 说明 |
|------|------|------|
| `/sdd start` | start | 全流程编排，串联所有阶段，支持断点恢复 |
| `/sdd setup` | setup | 初始化 SDD 环境，检查依赖，准备仓库与状态文件 |
| `/sdd proposal` | proposal | 轻量提问，快速收敛需求 |
| `/sdd brainstorming` | brainstorming | 深度设计，多轮探索 |
| `/sdd spec` | spec | 生成规格、任务与翻译层 |
| `/sdd build` | build | 执行实现，支持组件前置链与多轨任务 |
| `/sdd close` | close | 验证一致性、归档并进入人工提交门控 |

## 状态检测

当用户调用 `/sdd` 不带子命令，或调用某个子命令需要确认前置条件时，执行以下状态检测：

### 第一优先级：环境就绪检查

检查 `.agents/sdd-state.json` 是否存在且 `setupDone` 为 `true`：

- 未初始化 → 自动路由到 setup 阶段，完成后再继续

### 第二优先级：变更状态检查

| 检查项 | 怎么查 | 结果 |
|--------|--------|------|
| 有活跃变更？ | `openspec/changes/` 下是否有非 `archive` 子目录 | 有 → 继续 |
| 有翻译层？ | 变更目录下是否有 `plan-ready.md` | 有 → 看实现状态 |
| 轻量规格模式？ | 变更目录下是否有 `spec.md` 且无 `plan-ready.md` | 有 → 看实现状态 |
| 实现已开始？ | 变更目录下是否有 `impl-plan.md` 或其他计划文件 | 有 → 看是否完成 |
| 实现已完成？ | 计划文件全部 checkbox 已勾选 | 是 → close 阶段 |

判定结果：

- 无活跃变更 → proposal 阶段
- 有提案但无规格 → spec 阶段
- 有规格/翻译层但实现未开始 → build 阶段
- 实现进行中 → 继续 build 阶段（断点恢复）
- 实现已完成 → close 阶段

## 路由

根据子命令或状态检测结果，读取对应阶段文件并执行：

1. 如果用户指定了子命令（如 `/sdd build`），优先按指定阶段执行，但检查前置条件
2. 如果用户只输入 `/sdd`，执行状态检测，自动路由到对应阶段
3. 读取阶段文件：`${COMMAND_DIR}/<阶段>.md`
4. 按阶段文件中的流程执行

### 前置条件检查

| 阶段 | 前置条件 | 不满足时提示 |
|------|----------|-------------|
| setup | 无 | — |
| proposal | 环境已初始化 | 自动触发 setup |
| brainstorming | 环境已初始化 | 自动触发 setup |
| spec | 需要有活跃变更目录或有用户需求 | 「请先用 /sdd proposal 或 /sdd brainstorming 描述需求」 |
| build | 需要存在 `plan-ready.md` 或轻量 `spec.md` | 「请先完成 /sdd spec 生成规格」 |
| close | 需要实现已完成 | 「实现尚未完成，请先用 /sdd build 执行」 |
