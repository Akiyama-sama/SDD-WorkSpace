# Design: Add Export Center

## Overview

在现有应用中新增一个导出中心页面，展示用户最近的导出任务，并提供刷新和下载能力。

## Key Decisions

1. 使用独立页面，而不是塞进现有列表页弹窗。
2. 任务状态由后端接口返回，前端只负责映射展示。
3. 初版只提供手动刷新，不做自动轮询。

## Data Flow

```text
User opens export center
  -> frontend requests export task list
  -> backend returns task items with status
  -> frontend renders status and optional download link
```

## Risks

- 如果后端状态字段命名不稳定，前端展示逻辑容易漂移。
- 如果失败原因过长，需要额外处理换行或截断。

## Validation

- 手动验证三种状态展示。
- 验证成功任务可下载。
- 验证空列表态和接口失败态。
