---
name: sdd/setup
description: 初始化本地 SDD 环境，检查依赖并写入基础状态。
---

# Setup

## 目标

确认这个工作区已经具备运行 SDD 流程的最小条件。

## 建议动作

1. 执行 `.agents/tools/check-deps.sh`。
2. 确认 `openspec` 可用。
3. 如需聚合多个代码仓，准备 `.agents/repos.txt` 并按需执行 `.agents/tools/clone-repos.sh`。
4. 创建或更新 `.agents/sdd-state.json`，至少记录：
   - `setupDone`
   - `lastCheckedAt`
   - `workspaceReposRoot`
   - `defaultMode`

## 完成标准

- 依赖检查结果可读。
- 工作区目录结构齐全。
- 后续阶段可以不再重复问初始化问题。
