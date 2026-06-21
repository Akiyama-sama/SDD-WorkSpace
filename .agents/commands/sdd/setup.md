---
name: sdd/setup
description: SDD 环境依赖检查与安装。首次使用 /sdd 时自动触发，也可手动执行 /sdd setup 重新初始化。
---

# Setup: SDD 环境准备

## 目标

一次性、尽量少交互地完成 SDD 所有环境准备：依赖检查与安装、主干分支配置、状态落盘、工作仓库拉取，以及在仓库全部就绪后生成多仓库 `AGENTS.md` 索引。流程中持续打印进度；只有当脚本无法自动修复时，最终汇总提示手动操作。

统一配置写入仓库根目录的 `config.toml`，其中至少维护两项：

```toml
base_branch = "main"
repos = [
  # "git@github.com:your-org/your-repo.git",
]
```

## 触发条件

- 用户执行 `/sdd setup`
- `COMMAND.md` 检测到 `sdd-state.json` 不存在或 `setupDone` 为 `false` 时自动调用

## 执行原则

- 持续输出进度
- 单个依赖失败不阻断后续步骤，所有失败项汇总到最终报告中

## 流程

### ▶ 步骤 1/6：检查并安装依赖

打印：`▶ 步骤 1/6：检查 OpenSpec / Superpowers / Git / Node ...`

执行：
```bash
bash .agents/tools/check-deps.sh
```

解析输出的 `SDD_ENV_REPORT` 块，记录关键状态。任意失败项暂存到失败列表，不在此步打断。

### ▶ 步骤 2/6：配置主干分支

打印：`▶ 步骤 2/6：配置主干分支 ...`

执行：
```bash
bash .agents/tools/configure-base-branch.sh
```

解析输出的 `SDD_BASE_BRANCH_REPORT` 块，记录 `BASE_BRANCH=<分支名>`。

### ▶ 步骤 3/6：写入 sdd-state.json

打印：`▶ 步骤 3/6：写入状态文件 ...`

```bash
# shellcheck source=/dev/null
source .agents/tools/sdd-config.sh
BASE_BRANCH="$(sdd_config_get_base_branch)"
mkdir -p .agents && cat > .agents/sdd-state.json << EOF
{
  "setupDone": true,
  "setupAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "defaultBaseBranch": "$BASE_BRANCH"
}
EOF
```

### ▶ 步骤 4/6：拉取工作仓库

打印：`▶ 步骤 4/6：拉取工作仓库（首次较慢，请稍候）...`

```bash
bash .agents/tools/clone-repos.sh
```

解析 `CLONE_REPORT`，把 `FAILED=xxx` 中的仓库加入失败列表。

如果 `config.toml` 中 `repos` 为空，允许本步骤跳过，但需要在最终报告中说明“未配置聚合仓库清单”。

### ▶ 步骤 5/6：生成多仓库 AGENTS 索引

打印：`▶ 步骤 5/6：生成子仓库 AGENTS.md 与顶层索引 ...`

仅在以下条件全部满足时继续：

- `CLONE_REPORT` 为 `STATUS=OK`
- 或 `CLONE_REPORT` 为 `STATUS=SKIPPED` 且 `REASON=ALL_REPOS_ALREADY_PRESENT`

满足条件时：

- **主 Agent 不直接读取或整理各子仓库内容**
- 主 Agent 必须启动一个 fresh subAgent，专门执行“子仓库 `AGENTS.md` 生成 / 更新 + 顶层 `AGENTS.md` 索引重写”
- 主 Agent 只负责：
  - 判断前置条件是否满足
  - 向 subAgent 提供仓库列表、输出目标和约束
  - 在 subAgent 完成后做结果校验与最终汇总

以下情况跳过本步骤，并在最终报告中说明原因：

- `repos` 未配置
- clone 结果为 `PARTIAL`
- 任一配置仓库未完整就绪

本步骤的执行细则如下：

#### 5.0 subAgent 执行约束

主 Agent 派发 subAgent 时，必须明确以下要求：

- 任务范围：处理 `repos/` 下所有已配置且已存在的子仓库
- 输出目标：
  - 为每个子仓库生成或更新该仓库根目录下的 `AGENTS.md`
  - 在全部子仓库完成后，重写 workspace 根目录的 `AGENTS.md`
- 保留规则：
  - 若子仓库已有 `AGENTS.md`，必须先读再增强，不得直接覆盖
  - 顶层 `AGENTS.md` 允许重写为索引入口
- 内容重点：
  - 技术栈
  - 目录 / 项目结构
  - 关键入口与常用命令（可识别时）
- 事实优先：
  - 只能写从仓库中可靠检测到的内容
  - 不确定项要显式标注，不能猜

subAgent 完成后，主 Agent 至少验证：

- 每个目标子仓库都存在 `AGENTS.md`
- 顶层 `AGENTS.md` 已改为索引入口
- 顶层索引里列出的路径都真实存在

#### 5.1 侦察范围

优先通过快速信号收集，不要求通读全仓：

- 包管理/语言清单：`package.json`、`go.mod`、`pyproject.toml`、`Cargo.toml`、`pom.xml`、`build.gradle*` 等
- 框架/构建指纹：`vite.config.*`、`next.config.*`、`electron.vite.config.*`、`Dockerfile`、`docker-compose*`、`.github/workflows/`
- 入口与主目录：`main.*`、`app.*`、`server.*`、`cmd/`、`src/`、`internal/`
- 目录快照：最多读取前两层目录，忽略 `node_modules`、`vendor`、`.git`、`dist`、`build`、`.next`、`__pycache__`
- 测试信号：`tests/`、`test/`、`__tests__/`、`*_test.go`、`*.spec.ts`、`*.test.ts`

#### 5.2 每个子仓库 `AGENTS.md` 的写法

- 若仓库**已存在 `AGENTS.md`**：
  - 必须先读取并理解原内容
  - 在保留原有项目特定约束、禁令、约定的前提下增强内容
  - 不得直接覆盖已有指令
- 若仓库**不存在 `AGENTS.md`**：
  - 直接新建

生成/更新后的每个子仓库 `AGENTS.md` 至少包含以下内容：

- 项目用途的一句话概览（若无法可靠判断，可写“需结合 README 进一步确认”）
- 技术栈摘要
  - 语言/版本
  - 主要框架或运行时
  - 测试工具
  - 构建/启动工具
- 目录/项目结构映射
  - 顶层关键目录 → 职责
  - 必要时补充一层核心子目录
- 关键入口
  - 例如桌面主进程/渲染进程、后端 `cmd/`、HTTP 入口、配置入口
- 常用命令
  - 开发、测试、构建、lint/typecheck（仅在能可靠检测时写入）
- 代码约定
  - 文件命名、测试命名、错误处理或架构模式（仅写能从仓库中确认的内容）

内容约束：

- 重点放在“技术栈”和“目录/项目结构”，这是必填项
- 信息不确定时明确标注“未可靠检测到”，不要猜
- 保持简洁、可扫描，避免把 README 原样搬运进来

#### 5.3 更新顶层 `AGENTS.md`

在所有子仓库 `AGENTS.md` 都成功写好后，重写当前 SDD workspace 根目录的 `AGENTS.md`，使其承担“多仓库索引入口”职责：

- 明确说明本仓库是 SDD workspace，不是业务代码主仓
- 列出 `repos/` 下每个已纳入聚合的子仓库
- 为每个子仓库提供：
  - 仓库路径
  - 一句话定位
  - 指向其 `AGENTS.md` 的查看指引
- 告诉 Agent：涉及具体业务实现时，应先进入对应子仓库并优先阅读该仓库自己的 `AGENTS.md`
- 同时保留本 workspace 自身必要的 SDD 路由说明，避免把工作流入口信息全部丢失

### ▶ 步骤 6/6：汇总报告

打印：`▶ 步骤 6/6：汇总环境状态 ...`

输出最终报告（全绿示例）：

```text
SDD 环境就绪

  [✓] OpenSpec CLI        v1.x.x
  [✓] Superpowers Skill   已可用
  [✓] 主干分支            已配置为 <base-branch>
  [✓] 工作仓库            已准备
  [✓] Repo AGENTS         已生成并建立索引

可以开始 SDD 流程：/sdd proposal 或 /sdd brainstorming
```

如有失败项，对应行用 `[✗]`，并在报告底部列出修复建议。

## 异常处理

| 异常情况 | 处理方式 |
|----------|----------|
| openspec 安装失败 | 提示手动执行 `npm install -g @fission-ai/openspec@latest` |
| Superpowers 缺失 | 提示这是可选增强能力，不阻断主流程 |
| 主干分支未输入 | 回退到已有配置；首次无配置时默认使用 `main` |
| git clone 失败 | 提示检查网络、仓库地址和访问权限 |
| `repos` 未配置 | 允许继续，但说明不会自动聚合工作仓库 |
| 子仓库未全部就绪 | 跳过 Repo AGENTS 生成步骤，并说明需在 clone 完成后重跑该步骤 |
| subAgent 执行失败 | 主 Agent 不替代执行子仓库分析；记录失败原因并提示重试该步骤 |
