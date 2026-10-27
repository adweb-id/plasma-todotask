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
| 0.2.0 | Workspaces: separate lists (e.g. Work and Personal), each in its own file; the task path can be a folder; new default location `Documents/todotask/todo.md` |
| 0.2.1 | Switch workspace from the widget's right-click menu |
| 0.2.2 | Bold and italic from a small bar over the selected text, or Ctrl+B / Ctrl+I; one editor open at a time |
| 0.3.0 | Urgent mark (red label, top of its list, taken first by Pull next); date variables in Daily tasks such as `{date}` and `{date:dd/MM/yyyy}` |
| 0.4.0 | In review (an optional second tick for work that has to be checked); reminders at set times; search with Ctrl+F; Copy report for a stand-up; age of carried-over tasks; outside edits picked up and never overwritten; settings on three pages; Help and FAQ |

## Planned

### 0.5

- **Task notes in the popup**: show the notes kept under a task or subtask
  (steps, a query, how a bug was fixed) and write them from the popup. They
  are already kept in the file.
- **Badge setting**: choose what the panel badge counts (Today, Today and
  Queue) or hide it when nothing is left.
- **Delete confirmation setting**: switch the confirmation off when Undo is
  enough for you.
- **Waiting overview**: see every waiting task across all groups in one place.

### 0.6

- **Keyboard**: a shortcut to open the popup with the input focused, arrow
  keys to move between tasks, Space to tick.

## Later

- Clickable links in task text
- Show the task being worked on in the panel
- Daily tasks on specific weekdays only
- Work days for Daily tasks per workspace
- Indonesian translation
- Archive viewer inside the widget
- "Open in window" from the panel menu

## Not planned

To keep the widget small and simple: due dates and reminders per task (the
only reminder is a daily one to check the list), priority levels (one
*urgent* mark is all there is), time tracking, and accounts or online services. Your tasks stay in plain
Markdown files on your own disk.
