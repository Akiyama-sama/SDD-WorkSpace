# sdd-workspace

一个可复用的 **SDD（Spec-Driven Development）工作区模板**。它的目标不是绑定某个公司、业务线或技术平台，而是提供一套通用骨架，让你能把“需求理解 → 规格沉淀 → 执行实现 → 验证归档”这条链路稳定地落到本地文件系统中。

这个仓库主要提供三类东西：

- 一套按阶段组织的命令说明，方便你在 AI 编程工具里复用同样的工作流。
- 一套 `openspec/` 与知识库目录结构，帮助你把需求、决策、任务和长期知识沉淀为普通 Markdown。
- 一些可选脚本与看板页面，用来做环境检查、验证和浏览变更产物。

## Agent 兼容性

这个模板目前兼容三类入口约定：

- `AGENTS.md`
  用作通用 Agent 规范入口，也是 Codex 官方推荐的项目级持久指导文件。
- `.agents/skills`
  用作 Codex 可发现的 repo 级 skills 目录。对于 SDD 工作流，Codex 通过 skills 使用这些流程。
- `.claude/`
  用作 Claude 兼容层，其中 `commands`、`skills`、`mcp` 都是指向 `.agents/` 的软链接。

注意：

- `.agents/` 是唯一真源。
- `.claude/` 只是兼容层，不要在那里单独改内容。
- 对 Codex 来说，项目内 `.agents/commands` 不是原生命令注册目录，所以仓库额外提供了对应的 repo skills 包装层。

## 设计原则

- 文件即状态：流程进度写入文件，不依赖长会话上下文。
- 模板优先：仓库只保留通用流程，不内置任何特定公司、平台或业务知识。
- 渐进约束：小需求可以轻量执行，大需求再进入完整 SDD 流程。
- 验证优先：是否“完成”由检查结果决定，而不是由 AI 自述决定。

## 目录结构

```text
sdd-workspace/
├── .agents/
│   ├── commands/
│   │   ├── opsx/                # OpenSpec 相关命令说明
│   │   └── sdd/                 # SDD 四阶段工作流命令说明
│   ├── skills/                  # 本仓自带技能说明
│   └── tools/                   # 可选脚本：依赖检查、配置读取、仓库拉取、验证
├── openspec/
│   ├── changes/                 # 活跃变更与归档示例
│   └── specs/                   # 稳定规格沉淀
├── vertical-knowledge/
│   ├── rules/                   # 通用工程规则
│   └── wiki/                    # 领域知识索引骨架
├── dashboard/                   # 本地浏览变更的示例看板
├── config.toml                  # 主干分支与聚合仓库清单
├── repo/                        # 实际放置代码仓库的目录
├── CHANGELOG.md
└── README.md
```

## 推荐工作流

### 1. 初始化

- 补齐你的本地工具链，例如 `openspec`、测试命令、AI 插件或技能。
- 运行 `/sdd setup` 时，按提示设置你的主干分支（如 `main`、`master`、`develop`）。
- 按需编辑根目录 `config.toml` 中的 `repos` 列表，维护你的聚合仓库清单。
- 在 `vertical-knowledge/rules/` 中写入项目真实约束。

### 2. 需求理解

- 用 `/sdd proposal` 快速收敛清晰需求。
- 用 `/sdd brainstorming` 处理模糊需求、方案比较或架构探索。
- 将结论落到 `openspec/changes/<change>/proposal.md`。

### 3. 技术规约

- 用 `/sdd spec` 把需求转成设计、任务与验收场景。
- 需要长期积累的能力规范，沉淀到 `openspec/specs/`。

### 4. 执行实现

- 用 `/sdd build` 从规格进入实现。
- 优先让任务、验证命令、风险说明都写入文件，便于断点恢复。

### 5. 验证归档

- 用 `/sdd close` 运行检查、补齐结果、归档变更。
- 将稳定结论回写到知识库或主规格。

## 模板内置的样例

仓库保留了一个中性示例变更，用来展示：

- `proposal.md` 如何写背景、目标、边界。
- `design.md` 如何写关键方案和验证方法。
- `tasks.md` 如何按可执行粒度拆任务。
- `specs/` 如何写面向场景的验收规格。

这些样例只是结构参考，不代表任何特定业务。

## 自定义建议

- 把 `vertical-knowledge/rules/project-context.md` 改成你的真实技术栈。
- 把 `.agents/tools/verify.sh` 中的检查命令改成你的项目脚本。
- 把 `.agents/commands/sdd/*.md` 里的流程门槛改成你的团队习惯。
- 把 `dashboard/` 看板标题、字段和筛选项改成你的变更元数据格式。

## 配置项

`config.toml`配置自定义工作区的主分支，以及多个仓库远程配置

## 看板

本地预览：

```bash
cd dashboard
npm install
npm run dev
```

它会直接读取上层 `openspec/changes/**/*.md` 内容，适合浏览提案、设计、任务和规格样例。

## 许可证

MIT
