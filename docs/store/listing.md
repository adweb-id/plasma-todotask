# KDE Store listing

Text and files for the product page on store.kde.org. Copy each field as is.

Published at https://www.opendesktop.org/p/2377548/

## Basics

| Field | Value |
| --- | --- |
| Title | Todo Task |
| Category | Plasma 6 Widgets |
| License | GPLv3 (the store has no "or later" entry; the code itself is GPL-3.0-or-later, see LICENSE) |
| Source / Homepage | https://github.com/adweb-id/plasma-todotask |
| Tags | todo, tasks, productivity, markdown, planner, plasma6, widget, plasmoid |
| Logo | `docs/store/logo-512.png` |
| File | `todotask-<version>.plasmoid` from the GitHub release |

## Screenshots (in this order)

The store takes at most 5 images, so `take.sh` makes exactly these five.

1. `docs/screenshots/overview.png`
2. `docs/screenshots/menu.png`
3. `docs/screenshots/groups.png`
4. `docs/screenshots/toast.png`
5. `docs/screenshots/overview-light.png`

## Summary (one line)

Today's tasks and a queue in your Plasma panel, carried over by themselves and kept in one Markdown file.

## Description

Copy everything inside the block. Every list has an empty line above it; the
store needs that to show it as bullets instead of one run-on paragraph.

```text
Todo Task keeps the day's work in the Plasma panel: what is left for today, and a queue of what comes next.

Unfinished tasks carry over to tomorrow by themselves, routine work shows up every work day, and everything lives in one plain Markdown file you can also edit by hand. No account, no server.

EVERY DAY

- Panel or system tray icon with the number of tasks left today
- Today and Queue lists: Enter adds to the Queue, Shift+Enter to Today (can be swapped)
- Tick a task: it is struck through and moves to "Done today"; untick to bring it back
- Unfinished tasks stay in Today on a new day, marked with how long they have been there ("yesterday", "5 days"), stronger the older they get
- Daily routine: tasks in the Daily list are added to the top of Today every work day
- Date variables in Daily tasks: {date}, {date-1} or {date:dd/MM/yyyy} become the date of the day, handy for a daily query or report

ORGANISE

- Project groups in the Queue: fold them, add straight to a group, rename and reorder
- Urgent mark for work that comes first: red label, kept at the top, taken first by "Pull next"
- In review (optional): a tick in Today moves a task to In review until it has been checked, a second tick finishes it
- Reminders (optional): a notification at the times you choose, on work days, while tasks are left
- Waiting status for work on hold: dimmed, kept at the bottom, skipped by "Pull next"
- Subtasks with progress (1/3): add one with the + button, reorder them, or make one a task of its own
- Copy a task, a subtask or the whole Today list to the clipboard (right-click)
- Copy report: what was done on the last day and today, what is in review and what is planned, ready for a stand-up
- Drag a task to reorder it
- Bold and italic text: put two asterisks around words for bold, one for italic
- Undo for 5 seconds after adding, ticking or deleting

YOUR FILE

- Ordinary Markdown, stored where you choose (a file or a folder), e.g. a synced folder
- Workspaces: separate lists such as Work and Personal, each in its own file, switched from the popup
- Finished days are kept per date and moved to monthly archive files after a week
- Lines the widget does not know (notes, code blocks, other sections) are kept exactly where they are
- Edits made elsewhere (another editor, a sync tool) show up by themselves, and the widget never writes over them
- Settings for work days, archive age, popup width and which list Enter adds to

The file looks like this:

    ## Today (2026-10-07)
    - [ ] Fix coupon validation <!-- since:2026-10-06 group:"Webshop" -->
      - [x] Reproduce on staging

    ## Queue
    ### API
    - [ ] Add rate limiting

REQUIREMENTS

- Plasma 6.0 or newer
- base64, xdg-open and xdg-user-dir (present on common Linux desktops)

Pure QML and JavaScript: nothing to compile and no background service. Follows your Plasma theme, light or dark, and Plasma's animation speed.

After installing, right-click the panel, choose "Add Widgets…" and drag Todo Task onto the panel, or turn it on in System Tray Settings → Entries.

Bugs and ideas: https://github.com/adweb-id/plasma-todotask/issues
```

## Changelog for 0.4.0

- In review (optional): with Settings, Tasks, "Send it to In review first", a tick in Today moves a task to a new In review section until it has been checked, and a second tick finishes it. Right-click, Back to Today sends it back for more work. Shift+click on the box, or right-click, Done, skip review, finishes a task at once.
- Reminders (optional): a notification at the times you choose, on work days, while tasks are left in Today or In review. It says how many are left and names the first three, and clicking it opens the popup. The settings show which times they read and which they did not understand, and a Test button shows a reminder at once.
- Notifications now come from Todo Task with its own name and logo, and can be set up in System Settings, Notifications
- The settings are split into three pages: General, Tasks and Reminders, with the widget's own icons
- Help button in the About page, leading to a new FAQ in the README

## Changelog for 0.3.0

- Urgent mark: right-click a task, Mark as urgent. It gets a red label, moves to the top of its list or group, and Pull next takes it first. Finishing the task removes the mark.
- Date variables in Daily tasks: {date}, {date-1}, {date+7} or {date:dd/MM/yyyy} in a Daily task, its subtasks or its notes become the date of the day in the copy added to Today. Handy for a daily query or report.
- On a new day the Daily copies no longer stay half transparent, and the header shows the new date without restarting Plasma

## Changelog for 0.2.2

- Bold and italic without typing asterisks: select text while adding or editing a task and click B or I in the small bar above it, or press Ctrl+B / Ctrl+I; click again to remove the formatting
- Only one task or subtask is edited at a time: opening another one saves the one that was open

## Changelog for 0.2.1

- The widget's right-click menu can switch workspace, as announced for 0.2.0: "Switch to …" with two workspaces, "Switch workspace…" (opens the list in the popup) with more

## Changelog for 0.2.0

- Workspaces: keep separate lists (e.g. Work and Personal), each in its own file; switch from the chip in the popup header or the widget's right-click menu
- The task path can be a folder as well as a Markdown file: the file is then todo.md in that folder
- New installs keep their tasks in Documents/todotask/todo.md; an existing Documents/todo.md stays in use
- Settings warn when two workspaces point at the same file, and ask before a workspace is removed (its file is always kept)

## Changelog for 0.1.2

- Copy text: right-click a task or subtask to copy it to the clipboard; a task with subtasks is copied as a Markdown list
- Copy all: right-click the Today heading to copy the whole Today list, e.g. for a daily report
- A short "Copied …" toast confirms it, without getting in the way of a pending Undo

## Changelog for 0.1.1

- Hover a task to add a subtask with one click (＋ next to ↑↓ and ⋯)
- Subtasks can be moved up and down within their task, or made into a task of their own (right-click)
- Dragging a task to the bottom of Today works again
- Text pasted with line breaks stays on one line instead of being cut after the first line

## Changelog for 0.1.0

First release.
