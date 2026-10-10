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
- Unfinished tasks stay in Today on a new day, marked "yesterday"
- Daily routine: tasks in the Daily list are added to the top of Today every work day

ORGANISE

- Project groups in the Queue: fold them, add straight to a group, rename and reorder
- Waiting status for work on hold: dimmed, kept at the bottom, skipped by "Pull next"
- Subtasks with progress (1/3): add one with the + button, reorder them, or make one a task of its own
- Copy a task, a subtask or the whole Today list to the clipboard (right-click)
- Drag to reorder, bold and italic text
- Undo for 5 seconds after adding, ticking or deleting

YOUR FILE

- Ordinary Markdown, stored where you choose (a file or a folder), e.g. a synced folder
- Workspaces: separate lists such as Work and Personal, each in its own file, switched from the popup
- Finished days are kept per date and moved to monthly archive files after a week
- Lines the widget does not know (notes, code blocks, other sections) are kept exactly where they are
- Reload with one click after editing the file elsewhere
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
