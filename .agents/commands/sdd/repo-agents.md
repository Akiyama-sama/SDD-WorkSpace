---
name: sdd/repo-agents
description: 为 `repos/` 下已完整准备好的子仓库生成或更新各自的 `AGENTS.md`，并重写顶层 `AGENTS.md` 为索引入口。
---

# Repo Agents: 多仓库 AGENTS 索引与入门文档

## 目标

在 `repos/` 下的聚合仓库全部就绪后，基于 `codebase-onboarding` 的侦察与归纳方式，为每个子仓库生成或更新一份 `AGENTS.md`，内容聚焦：

- 技术栈
- 目录 / 项目结构
- 关键入口与常用命令（可识别时）

随后重写工作区根目录的 `AGENTS.md`，使其成为多仓库索引入口，指导 Agent 先进入目标子仓库并阅读对应的 `AGENTS.md`。

## 前置条件

- `repos/` 目录存在
- `config.toml` 中声明的仓库已全部 clone 完成，或 `clone-repos.sh` 报告 `ALL_REPOS_ALREADY_PRESENT`

若不满足前置条件，则本流程直接跳过，不生成任何子仓库 `AGENTS.md`。

## 执行原则

- **只在仓库全部就绪后执行**
- **尊重子仓库已有 `AGENTS.md`**
- **该流程默认由主 Agent 派发的 subAgent 执行**
- 若子仓库已存在 `AGENTS.md`，必须先阅读并保留其项目特有约束，再在此基础上增强，而不是粗暴覆盖
- 顶层 `AGENTS.md` 允许重写，不保留旧内容；目标是让 Agent 明确“先看哪个子仓库的 `AGENTS.md`”
- 不扫描无关大目录；优先使用侦察式读取，而不是通读全仓

## 流程

### 步骤 1/4：确认仓库是否全部就绪

执行：

```bash
bash .agents/tools/clone-repos.sh
```

只在以下两种结果下继续：

- `STATUS=OK`
- `STATUS=SKIPPED` 且 `REASON=ALL_REPOS_ALREADY_PRESENT`

以下情况必须跳过本流程：

- `REASON=NO_REPOS_CONFIGURED`
- `STATUS=PARTIAL`
- 任一配置仓库目录缺失

若主 Agent 已经完成前置检查并确认仓库全部就绪，subAgent 可直接从步骤 2 开始执行。

### 步骤 2/4：由 subAgent 逐仓库生成或增强 `AGENTS.md`

主 Agent 应将本流程完整要求打包给一个专门的 subAgent。该 subAgent 对 `repos/` 下每个已配置且存在的子仓库，按 `codebase-onboarding` 思路执行，但输出文件改为 `AGENTS.md`：

#### 2.1 侦察

并行收集以下信号：

- 包管理 / 构建清单：`package.json`、`go.mod`、`pyproject.toml`、`Cargo.toml` 等
- 框架指纹：`next.config.*`、`vite.config.*`、`electron.vite.config.*`、`Dockerfile`、`docker-compose*.yml` 等
- 入口线索：`main.*`、`app.*`、`server.*`、`cmd/`、`src/main/`
- 目录快照：仅看前两层，忽略 `.git`、`node_modules`、`dist`、`build`、`.next`、`vendor`
- 测试结构：`tests/`、`test/`、`__tests__/`、`*_test.go`、`*.test.ts`
- 工具配置：lint / format / CI / tsconfig / Makefile / workflow

#### 2.2 内容组织

每个子仓库的 `AGENTS.md` 至少应包含：

```markdown
# <Repo Name> Agent Guide

## Overview
- 这个仓库是什么

## Tech Stack
- 语言 / 运行时
- 框架 / 核心库
- 构建 / 测试 / lint 工具
- 数据库 / 中间件（可识别时）

## Project Structure
- 顶层目录与职责
- 关键子目录与入口

## Common Commands
- dev / build / test / lint（可识别时）

## Working Notes
- 命名或测试约定（仅在可识别时）
- 未能确认的项明确写 Unknown
```

#### 2.3 已有 `AGENTS.md` 的处理规则

若子仓库已有 `AGENTS.md`：

- 先完整阅读
- 保留其中项目特有约束、禁令、工作流说明
- 将新生成的技术栈 / 结构化内容与原内容合并
- 如新旧内容冲突，以“代码和当前仓库结构可验证出的事实”为准
- 不删除明显仍有效的人工规则

### 步骤 3/4：由 subAgent 重写顶层 `AGENTS.md`

在所有子仓库 `AGENTS.md` 写好后，重写工作区根目录 `AGENTS.md`，使其成为路由入口。内容目标：

- 说明这是一个 SDD workspace 聚合仓库
- 列出 `repos/` 下的子仓库与各自的 `AGENTS.md` 路径
- 明确要求 Agent 在处理某个子仓库任务前，先阅读对应子仓库的 `AGENTS.md`
- 仅保留少量 workspace 级说明，例如：
  - `.agents/` 是 SDD 工作流源
  - `.claude/` 是兼容层
  - 涉及具体业务代码时，以目标子仓库的 `AGENTS.md` 为准

建议结构：

```markdown
# Workspace Agent Guide

## Workspace Role
- 这是一个 SDD 聚合工作区，不是单一业务仓库

## Repo Index
- `repos/<repo-a>/AGENTS.md`
- `repos/<repo-b>/AGENTS.md`

## Routing Rules
- 处理某个子仓库前，先读对应 `AGENTS.md`
- 工作流资产看 `.agents/`
- `.claude/` 仅为兼容层
```

### 步骤 4/4：主 Agent 验证

subAgent 完成后，主 Agent 至少确认以下事项：

- 每个已配置且存在的子仓库都有 `AGENTS.md`
- 顶层 `AGENTS.md` 已改为索引入口
- 顶层 `AGENTS.md` 中列出的路径全部存在
- 若仓库存在兼容层 `CLAUDE.md`，确保其不与新的路由说明冲突

## 跳过条件

出现以下任一情况时，直接跳过并说明原因：

- `repos` 未配置
- `repos/` 不存在
- 任一配置仓库未 clone 完成
- 子仓库目录存在但不是 git 仓库

## 输出结果

成功时应明确汇报：

- 已处理的子仓库列表
- 新建 / 更新了哪些 `AGENTS.md`
- 顶层 `AGENTS.md` 已切换为索引入口

若跳过，应明确说明是哪个前置条件未满足。
