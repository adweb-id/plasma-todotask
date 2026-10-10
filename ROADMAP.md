# Roadmap

What Todo Task has shipped and what is planned next. The order of the planned
items can change; suggestions are welcome in the
[issues](https://github.com/adweb-id/plasma-todotask/issues).

## Released

| Version | Highlights |
| --- | --- |
| 0.1.0 | Today and Queue lists with a panel badge, add / edit / delete / reorder / undo, carry-over to the next day, subtasks, bold and italic text, daily archive of finished tasks, task file stored as plain Markdown |
| 0.1.1 | Daily routine tasks, added to Today every work day; subtasks no longer show a check box in the Queue and Daily list; drag a task to the bottom of Today |
| 0.1.2 | Waiting status; copy a task, a subtask or the whole Today list to the clipboard; project groups in the Queue; hover button for adding a subtask; reorder subtasks and turn one into a task; reload button; choose where the task file lives |

## Planned

### 0.2

- **Auto-reload**: pick up changes made to `todo.md` in another editor right
  away, without reopening the popup or pressing reload.
- **Safe saving**: check the file before writing, so two widgets (panel and
  system tray) or an outside edit never overwrite each other.
- **Task notes in the popup**: show the notes kept under a task or subtask
  (steps, a query, a link). They are already preserved in the file.

### 0.3

- **Copy report**: copy "done yesterday" plus today's plan in one click, for a
  daily report.
- **Waiting overview**: see every waiting task across all groups in one place.
- **Stale marker**: show how long an unfinished task has been carried over
  ("3 days") instead of only "yesterday".

### 0.4

- **Search**: filter tasks in all lists as you type.
- **Keyboard**: a shortcut to open the popup with the input focused, arrow
  keys to move between tasks, Space to tick.

## Later

- Clickable links in task text
- Show the task being worked on in the panel
- Daily tasks on specific weekdays only
- Indonesian translation
- Archive viewer inside the widget
- "Open in window" from the panel menu

## Not planned

To keep the widget small and simple: due dates and reminders, priorities,
multiple lists or projects, time tracking, and accounts or online services.
The file stays a single plain Markdown file on your own disk.
