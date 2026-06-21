---
name: sdd/spec
description: 调用 OpenSpec 生成规格，用户确认后自动翻译为 plan-ready.md；轻量模式下生成单文件 spec.md。
---

# Spec: 生成规格并翻译

## 目标

生成完整的规格文档（`proposal.md`、`design.md`、`specs/`、`tasks.md`），用户确认后自动翻译成可执行的 `plan-ready.md`。在轻量模式下，生成单份 `spec.md`。

## 前置条件

- `openspec/changes/` 下存在活跃变更目录
- 变更目录下至少有 `proposal.md`

## 流程

### 步骤负一：档位检测

先读 `.agents/sdd-state.json` 的 `triage.mode` 字段：

```bash
cat .agents/sdd-state.json 2>/dev/null
```

| triage.mode | 走什么分支 |
|------------|-----------|
| `plan` | 轻量分支：生成单份 `spec.md`，再进入 build |
| `full` 或字段缺失 | 走完整流程 |
| `vibe` | 不应进入本命令；若进入，提示用户直接写代码即可 |

### plan 档位 spec 模板（技术方案格式）

> 写入路径：`openspec/changes/<变更名>/spec.md`

```markdown
# <变更名> 技术方案

> 档位：plan · PD：<X> · 复杂度：<低/中/高>

## 一、背景与目标
- 一句话目标
- 命名约定
- 影响范围

## 二、系统设计
- 2.1 数据流示意（ASCII / 文字）
- 2.2 关键交互流程

## 三、接口变动
- 3.1 接口列表
- 3.2 字段变动详情
- 3.3 方案选型

## 四、自测冒烟 case
- 4.1 正常路径
- 4.2 配置/权限/灰度表现
- 4.3 异常兜底
- 4.4 风险点

## 五、上线发布
- 5.1 上线前 Checklist
- 5.2 灰度策略
- 5.3 回滚预案
```

**plan 档位执行步骤**：
1. 读取 `proposal.md`，按模板生成 `spec.md`
2. 与用户确认
3. 用户确认后写入 `openspec/changes/<变更名>/spec.md`
4. 写入状态：`spec.mode=plan, spec.version=v2`
5. 同时生成最小 `plan-ready.md`，供后续 build/close 复用

### 步骤零：模式检测（入口分流）

在任何分析之前，先检测当前变更状态，分流到三种模式之一：

```bash
ls openspec/changes/<变更名称>/{proposal.md,design.md,tasks.md} 2>/dev/null
cat openspec/changes/<变更名称>/.sdd-state.json 2>/dev/null
```

| 状态 | mode | 行为 |
|------|------|------|
| `design.md` / `tasks.md` 缺失 | `create` | 首次生成 |
| 三份文件齐全，且 `.sdd-state.json.planReadyStale=true` | `resync` | 需求变更后的方案重对齐 |
| 三份文件齐全，proposal 未变 | `amend` | 方案增量调整 |

### 步骤零B：方案重对齐（mode=resync）

1. 读取 `proposal.md`，对比 `design.md` / `specs/` / `tasks.md`
2. 展示重对齐预览：

```text
检测到需求已更新，以下方案需要同步调整：

需求变更点                影响的方案位置
─────────────────────────────────────────
<变更点 1>                → design.md + tasks.md
<变更点 2>                → specs/xxx.md
<变更点 3>                → tasks.md

是否确认按以上方案重对齐？
  A. 确认
  B. 我想调整范围
  C. 取消
```

3. 用户确认后，自动更新对应文件，并清除 `planReadyStale`
4. 跳到步骤三（规范自审）→ 步骤五（重生成 `plan-ready.md`）

### 步骤零C：方案增量调整（mode=amend）

触发场景：需求没变，但用户想调整技术方案（架构、任务拆分、spec 行为定义等）。

1. 用一段话概括当前方案
2. 让用户用一句话描述要调整什么
3. 产出变更预览：

```text
我理解你想做以下调整：
  ① <变更点 1>  → 影响架构决策
  ② <变更点 2>  → 影响任务拆分
  ③ <变更点 3>  → 影响验收条件

将自动重新生成 plan-ready.md。

是否确认？
  A. 确认，开始调整
  B. 我想修正描述
  C. 取消
```

4. 用户选 A：
   - 按变更点更新对应文件
   - 在 `design.md` 末尾追加方案变更历史
   - 强制删除并重生成 `plan-ready.md`

### 步骤一：上下文分析与边界预判（仅 mode=create）

在首次生成规格时，先完成这些前置分析：

1. 术语解析：把 proposal 中的关键术语翻译成代码/模块语言
2. 知识库查询：读取 `vertical-knowledge/` 里的相关规则与模块知识
3. 代码定位与仓库识别：确定需求涉及哪些 repo、目录、页面、服务、状态、组件
4. 集成预判：判断是否涉及外部平台、第三方系统、配置平台、工作流引擎、自动化平台等
5. 组件改造识别：判断是否需要 `[comp-code]` 或 `[comp-integration]` 任务

如果存在外部集成链路，可额外执行三步认知流程：

- 第一步：入口识别
- 第二步：能力与字段盘点
- 第三步：边界认知，产出 `[integration]` / `[code]` / `[manual]` 分类单

必要时将边界认知结果写入：

```text
openspec/changes/<变更名>/boundary-draft.md
```

### 步骤二：确认活跃变更 + 生成功能点清单

检查 `openspec/changes/` 下是否有活跃变更。

如果没有，提示用户：
> 「还没有活跃变更。请先用 /sdd proposal 或 /sdd brainstorming 创建需求。」

确认变更后，读取 `proposal.md`，提取功能点清单，写入：

```text
openspec/changes/<变更名称>/prd-checklist.md
```

### 步骤三：生成规格与任务

优先使用 OpenSpec CLI 生成结构化文档；若 CLI 不可用，则手动创建以下文件：

- `design.md`
- `tasks.md`
- `specs/<capability>/spec.md`
- 必要时保留或读取 `boundary-draft.md`

任务标签建议：

- `[code]`：代码改动
- `[integration]`：外部平台或跨系统任务
- `[manual]`：人工处理
- `[comp-code]`：组件库代码任务
- `[comp-integration]`：组件库发布或平台同步任务

### 步骤四：规范自审

生成后，必须做一次自审：

1. PRD 覆盖率检查：`prd-checklist.md` 是否都被映射
2. 规格一致性检查：`design.md`、`specs/`、`tasks.md` 是否互相对齐
3. 任务完整性检查：`[code]` / `[integration]` / `[manual]` 是否拆分清楚
4. 组件任务完整性检查：如涉及组件链路，是否明确前置关系

### 步骤五：与用户确认规格

输出摘要并与用户确认：

```text
规格已生成：
  - design.md
  - tasks.md
  - specs/...

任务概览：
  [code] X 条 / [integration] Y 条 / [manual] Z 条

是否确认进入执行翻译？
  A. 确认
  B. 我想补充或修改
  C. 取消
```

### 步骤六：生成 plan-ready.md

用户确认后，生成 `plan-ready.md` 作为执行翻译层。

要求：
- 用业务语言总结目标与边界
- 列出涉及仓库与关键文件
- 明确执行顺序、依赖关系和验证方式
- 不重新定义需求，只做“可执行翻译”

## 注意

- spec 阶段可以改规格，但不要开始写业务代码
- 如果实现路径依赖外部平台，应在此阶段把边界说清
- full 模式要保留 `design.md` / `tasks.md` / `specs/` / `plan-ready.md` 四类产物
