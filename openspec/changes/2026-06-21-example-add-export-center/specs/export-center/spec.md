# Spec: Export Center

## Scenario 1: View task list

```text
GIVEN user opens the export center
WHEN the task list request succeeds
THEN the page shows recent export tasks in descending time order
```

## Scenario 2: Show success state

```text
GIVEN a task is completed successfully
WHEN the task row is rendered
THEN the row shows a downloadable file action
```

## Scenario 3: Show failure reason

```text
GIVEN a task has failed
WHEN the task row is rendered
THEN the row shows a readable failure reason
```

## Scenario 4: Handle empty state

```text
GIVEN the request succeeds with no tasks
WHEN the page is rendered
THEN the page shows an empty state instead of a blank table
```
