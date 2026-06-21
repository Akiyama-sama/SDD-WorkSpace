---
name: sdd/setup
description: SDD 环境依赖检查与安装。首次使用 /sdd 时自动触发，也可手动执行 /sdd setup 重新初始化。
---

# Setup: SDD 环境准备

## 目标

一次性、尽量少交互地完成 SDD 所有环境准备：依赖检查与安装、用户标识录入、状态落盘、工作仓库拉取。流程中持续打印进度；只有当脚本无法自动修复时，最终汇总提示手动操作。

## 触发条件

- 用户执行 `/sdd setup`
- `COMMAND.md` 检测到 `sdd-state.json` 不存在或 `setupDone` 为 `false` 时自动调用

## 执行原则

- 仅在用户标识确认环节向用户提问一次
- 持续输出进度
- 单个依赖失败不阻断后续步骤，所有失败项汇总到最终报告中

## 流程

### ▶ 步骤 1/5：检查并安装依赖

打印：`▶ 步骤 1/5：检查 OpenSpec / Superpowers / Git / Node ...`

执行：
```bash
bash .agents/tools/check-deps.sh
```

解析输出的 `SDD_ENV_REPORT` 块，记录关键状态。任意失败项暂存到失败列表，不在此步打断。

### ▶ 步骤 2/5：录入用户标识

打印：`▶ 步骤 2/5：录入用户标识 ...`

按以下顺序获取，最终向用户确认：

1. 读取项目 `AGENTS.md`，若已存在 `USER_CODE=xxx` → 直接复用并跳过提问
2. 否则尝试 `git config user.email`，取 `@` 前缀作为候选值
3. 否则尝试 `whoami` 作为候选值
4. 将候选值展示给用户确认；若不正确，则让用户输入正确值

成功获取后，可追加到 `AGENTS.md` 或其他团队约定文件：

```text
## 用户标识

USER_CODE=<值>
```

### ▶ 步骤 3/5：写入 sdd-state.json

打印：`▶ 步骤 3/5：写入状态文件 ...`

```bash
mkdir -p .agents && cat > .agents/sdd-state.json << EOF
{
  "setupDone": true,
  "setupAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

### ▶ 步骤 4/5：拉取工作仓库

打印：`▶ 步骤 4/5：拉取工作仓库（首次较慢，请稍候）...`

```bash
bash .agents/tools/clone-repos.sh
```

解析 `CLONE_REPORT`，把 `FAILED=xxx` 中的仓库加入失败列表。

如果 `.agents/repos.txt` 为空或不存在，允许本步骤跳过，但需要在最终报告中说明“未配置聚合仓库清单”。

### ▶ 步骤 5/5：汇总报告

打印：`▶ 步骤 5/5：汇总环境状态 ...`

输出最终报告（全绿示例）：

```text
SDD 环境就绪

  [✓] OpenSpec CLI        v1.x.x
  [✓] Superpowers Skill   已可用
  [✓] 用户标识            USER_CODE=<值>
  [✓] 工作仓库            已准备

可以开始 SDD 流程：/sdd proposal 或 /sdd brainstorming
```

如有失败项，对应行用 `[✗]`，并在报告底部列出修复建议。

## 异常处理

| 异常情况 | 处理方式 |
|----------|----------|
| openspec 安装失败 | 提示手动执行 `npm install -g @fission-ai/openspec@latest` |
| Superpowers 缺失 | 提示这是可选增强能力，不阻断主流程 |
| USER_CODE 无法自动获取 | 向用户询问并手动写入 |
| git clone 失败 | 提示检查网络、仓库地址和访问权限 |
| 仓库清单未配置 | 允许继续，但说明不会自动聚合工作仓库 |
