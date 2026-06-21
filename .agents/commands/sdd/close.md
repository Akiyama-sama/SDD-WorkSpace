---
name: sdd/close
description: 代码规范自检、验证实现一致性、归档，人工门控等待 commit
---

# Close: 验证归档

## 目标

代码规范自检 → 验证代码实现与设计文档一致 → 确认规格变更全部体现 → 归档 → 人工门控等待 commit。

## 前置条件

- 对应实现计划中的任务已全部完成并勾选
- `openspec/changes/<变更名>/plan-ready.md` 存在，或
- `openspec/changes/<变更名>/spec.md` 存在（plan 模式）

如工作区使用其他执行计划载体，也应确保其状态已更新完成，例如：
- `openspec/changes/<变更名>/impl-plan.md`
- `docs/.../plans/*.md`

---

## 流程

### 步骤零：确定变更名

在执行任何步骤之前，先确定本次变更名称：

1. 检查 `openspec/changes/` 目录，列出所有非 `archive` 子目录
2. 若只有一个，直接使用；若有多个，列出让用户确认：
   > 「检测到以下进行中的变更：[列表]，请确认本次 close 的目标变更名。」
3. 将确认后的变更名作为后续所有步骤的 `<变更名>`

### 步骤一：确认实现状态

**1.1 检查计划 checkbox**

检查本次变更对应的执行计划，确认所有 checkbox 已勾选。

如果有未完成的 task：
> 「还有 N 个任务未完成。请先用 /sdd build 完成实现。」

如果有跳过标记的任务，提示用户先处理后再进入本阶段。

**1.2 检查未暂存的文件变更**

执行：
```bash
git status --short
```

若存在未暂存的修改文件（`M`、`??` 等标记），提示用户：
> 「检测到以下文件有未暂存的变更：[文件列表]。请先执行 `git add` 将相关变更暂存后再继续。」

强制等待用户处理完毕后再进入步骤二。

### 步骤二：代码规范自检

**2.1 自动跑一遍 verify.sh**

> 原则：AI 不能自说“我做完了”，必须由独立脚本跑出绿灯。

执行：
```bash
bash .agents/tools/verify.sh
```

脚本应至少覆盖这些检查：

| # | 检查内容 |
|---|---------|
| ① | lint：如 `npm run lint` |
| ② | typecheck：如 `npm run typecheck` / `type-check` / `tsc` |
| ③ | unit test：如 `npm test` |
| ④ | 任务状态：是否还有未完成任务 |
| ⑤ | 其他项目级验证（按仓库实际脚本扩展） |

任一项失败 → 立即停止后续步骤，进入修复循环：
- AI 读取失败输出 → 修复 → 重跑 `verify.sh`
- 修复重试上限：3 次
- 超过 3 次仍失败 → 停止自修复，转人工处理

全部通过（或带合理的跳过项）后才进入 2.2。

**2.2 LLM 补充检查（工具无法覆盖的部分）**

对本次变更涉及的所有代码文件进行额外检查：

| 检查项 | 说明 |
|--------|------|
| 禁止写法 | 是否存在项目已知反模式 |
| 跨仓库契约 | 若涉及接口或共享数据结构，是否同步更新相关契约文档 |
| 任务契约 | 实现是否仍与 `tasks.md` / `plan-ready.md` / `spec.md` 的约定一致 |

输出问题列表，按级别分类：

```text
代码规范检查结果：

lint/typecheck/test：✅ 通过 / ❌ 失败（见工具输出）

[阻塞] 问题（必须修复后才能归档）：
  - [问题描述] 位于 [文件路径:行号]

[建议] 问题（可选处理）：
  - [问题描述] 位于 [文件路径:行号]
```

- 存在阻塞级问题 → 等待用户修复，修复后重新执行步骤二
- 仅有建议级问题 → 提示用户，由用户决定是否处理，确认后进入步骤三
- 无问题 → 直接进入步骤三

### 步骤三：验证设计一致性

读取 `openspec/changes/<变更名>/design.md`，逐项检查代码实现：

- `design.md` 中的技术决策是否在代码中体现？
- 标记的架构选择是否与代码结构一致？

对每一项，给出判定：✅ 一致 / ❌ 不一致（附具体差异）

#### 步骤三·补强：双锚点终态校验（强制）

close 阶段必须做最后一次双锚点核验，避免改动后仍有死代码、漏改或环境状态误判：

1. 对本次涉及的改动文件做一次最终入口/依赖复扫，对比 `design.md` 中登记的影响面
2. 若本项目依赖 feature flag、灰度、白名单、平台配置等外部状态，查询其最终状态
3. 核验项：

| 核验维度 | 期望 | 异常处理 |
|---|---|---|
| 改动文件实际影响面 | 与 `design.md` 中登记的影响面一致 | 出现新入口/新模块 → [阻塞] 回到 spec amend |
| 已启用的外部配置 | 必须有对应实现与任务记录 | 否则 [阻塞] 存在死代码或漏改风险 |
| 已关闭的外部配置 | `tasks.md` 中应说明为何暂不处理 | 否则 [记录] 存在额外改动或资源浪费 |
| 部分灰度状态 | 需要同时具备配置侧和代码侧收尾 | 缺一 → [阻塞] 存在灰度风险 |
| 未知状态 | 必须有人工核实笔记 | 否则 [记录] 保留存疑收尾 |

### 步骤四：验证规格完整性

读取 `openspec/changes/<变更名>/specs/` 目录，检查每个规格变更：

- 标记为“新增”的功能是否已实现？
- 标记为“修改”的行为是否已更新？
- 标记为“删除”的旧逻辑是否已移除？

对每一项，给出判定：✅ 已体现 / ❌ 未体现（附具体缺失）

### 步骤五：处理不一致

将不一致项按严重程度分级处理：

**[阻塞] spec 未实现**
- 标记为新增、修改、删除但代码未体现
- 强制拦截，不进入归档
- 提示用户：
  > 「发现 N 处 spec 未实现，必须先用 /sdd build 补全后再 close。」

**[记录] design 与代码存在差异**
- 记录到 `openspec/changes/<变更名>/close-issues.md`
- 提示用户：
  > 「发现 N 处 design 与实现存在差异，已记录到 `close-issues.md`。是否需要开启新的变更来修复？」
  - 用户选择“是” → 记录后继续归档
  - 用户选择“否” → 继续归档

### 步骤六：归档

全部一致（或用户接受记录级不一致项）后，执行归档：

**6.1 检查归档目标是否已存在（幂等保护）**

```bash
ls openspec/changes/archive/ 2>/dev/null | grep "<变更名>"
```

- 若已存在同名目录 → 提示用户：
  > 「归档目录 `openspec/changes/archive/<变更名>` 已存在，将使用带时间戳的目录名：`<变更名>-$(date +%Y%m%d%H%M%S)`，请确认。」
- 用户确认后继续

**6.2 执行归档**

优先使用 OpenSpec CLI：
```bash
openspec archive <变更名>
```

若 CLI 不可用，手动归档：
```bash
ARCHIVE_NAME="$(date +%Y-%m-%d)-<变更名>"
mkdir -p openspec/changes/archive
mv openspec/changes/<变更名> openspec/changes/archive/$ARCHIVE_NAME/
```

在归档目录下追加 `archive-meta.md`：

```text
归档时间：[时间戳]
最终状态：已完成
close-issues：[无 / 见 close-issues.md]
```

归档后确认：
- 规格增量已合并到主规格库（如适用）
- 变更记录已移到 `archive` 目录

### 步骤七：输出 SDD 流程完整摘要

执行以下命令获取实际暂存变更信息：
```bash
git diff --cached --stat
git status --short
```

基于命令真实输出，生成摘要：

```text
SDD 流程完成

变更名称：[变更名称]
需求描述：[需求简述]

关键产出：
  spec 阶段：openspec/changes/archive/[变更名称]/ （已归档）
  build 阶段：原子执行计划（[N] 个任务）
  全码变更：[git diff --cached --stat 的真实统计]
  close 阶段：代码规范检查通过，变更已归档

待提交变更清单（来自 git status）：
  - [实际文件列表]
```

### 步骤八：人工 Review 门控（强制等待）

> ⛔ 本步骤是 SDD 全流程唯一允许执行 `git commit` / `git push` 的位置。
> 在用户明确返回“执行提交”或“仅提交不 push”之前，绝对禁止调用任何包含 `git commit`、`git push`、`git -C ... commit`、`git -C ... push` 的命令。
> 不得以“流程连贯”为由跳过用户确认，也不得替用户预设答案。

#### 8.1 强制展示真实 diff（commit 前最后一道人眼检查）

执行并将输出回显给用户：

```bash
git diff --cached --stat
git diff --cached

for REPO_DIR in workspace-repos/*/ repo/*/; do
  [ -d "$REPO_DIR/.git" ] || continue
  if ! git -C "$REPO_DIR" diff --cached --quiet 2>/dev/null; then
    echo "===== $(basename "$REPO_DIR") ====="
    git -C "$REPO_DIR" diff --cached --stat
    git -C "$REPO_DIR" diff --cached
  fi
done
```

若 diff 体量过大（>500 行），先输出 `--stat`，再询问用户是否需要展开完整 diff，再决定是否补打。不要静默跳过。

#### 8.2 询问用户选择

向用户明确询问：
> 「以上变更已暂存。请 review 后选择操作：」
>
> 选项：
> - 暂不提交，稍后手动处理（推荐）
> - 仅提交不 push（`git commit`）
> - 执行提交并推送（`git commit + push`）

只有在拿到用户真实回复后，才可进入 8.3。

#### 8.3 用户选择“暂不提交”

直接进入步骤九，不执行任何 git 操作。提示：
> 「变更已保留在暂存区，未 commit。可使用 `git diff --cached` 自行 review 后手动提交。」

#### 8.4 用户选择“提交”或“提交并推送”时的预检

在执行任何 `git commit` 前，先做分支验证：

```bash
CURRENT_SDD_BRANCH=$(git -C . branch --show-current)
if [ "$CURRENT_SDD_BRANCH" = "master" ] || [ "$CURRENT_SDD_BRANCH" = "main" ]; then
  echo "⚠️ 当前 SDD 仓库在受保护主分支，禁止直接提交！"
fi

for REPO_DIR in workspace-repos/*/ repo/*/; do
  [ -d "$REPO_DIR/.git" ] || continue
  REPO_BRANCH=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null)
  if [ "$REPO_BRANCH" = "master" ] || [ "$REPO_BRANCH" = "main" ]; then
    echo "⚠️ $(basename "$REPO_DIR") 仓库当前在受保护主分支！"
  fi
done
```

- 任一仓库在受保护主分支 → 强制中止，回退到 8.2 让用户重选“暂不提交”或先切换分支后重跑 close
- 所有仓库都在开发分支 → 进入 8.5

#### 8.5 执行 commit / push（仅在用户明确选择后）

```bash
git commit -m "feat: [统一 commit message]"

# 仅当用户选择“提交并推送”才执行：
git push origin "$(git branch --show-current)"

for REPO_DIR in workspace-repos/*/ repo/*/; do
  [ -d "$REPO_DIR/.git" ] || continue
  if ! git -C "$REPO_DIR" diff --cached --quiet 2>/dev/null; then
    REPO_BRANCH=$(git -C "$REPO_DIR" branch --show-current)
    git -C "$REPO_DIR" commit -m "feat: [变更名] 对应改动"
    # 仅当用户选择“提交并推送”才执行：
    git -C "$REPO_DIR" push origin "$REPO_BRANCH"
  fi
done
```

提交完成后提示：
> 「变更 '<变更名>' 已提交至 `<分支名>` 开发分支。请前往代码托管平台创建合并请求。可以开始下一个变更了。」

#### 8.6 自检清单（执行 bash 前在脑内过一遍）

- [ ] 我已拿到用户的真实回复，而不是替用户选项？
- [ ] 用户选的是“提交”或“提交并推送”，而不是“暂不提交”？
- [ ] 我已在 8.1 把真实 diff 回显给用户？
- [ ] 所有相关仓库都不在受保护主分支？

四项全 ✅ 才能执行包含 `git commit` 的命令；任一 ❌ → 立刻停手。

### 步骤九：知识库增量更新

将本次变更涉及的代码改动同步更新到 `vertical-knowledge/` 知识库中。

如果项目已有专门的知识更新 skill 或脚本，应在本步骤调用；如果没有，至少完成以下动作：
- 判断哪些长期知识需要更新
- 将稳定结论写回 `rules/` 或 `wiki/`
- 避免把一次性实现细节写成长期知识

---

## 关键原则

- close 阶段不做新的需求扩展，只做验证、记录和归档
- 流程开始前必须先确定变更名，避免操作错误目标
- 工具输出优先于 LLM 判断，作为客观阻塞依据
- spec 未实现属于阻塞级，强制拦截；design 差异属于记录级，由用户决策
- 归档前检查目标目录是否已存在，避免覆盖
- 摘要中的变更统计来自真实 git 命令输出，禁止 LLM 估算填写
- 严禁自行 commit/push，人工门控是最后一道保障
- 防止边写代码边改需求的恶性循环
