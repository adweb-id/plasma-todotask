# KDE Store listing

Text and files for the product page on store.kde.org. Copy each field as is.

Published at https://www.opendesktop.org/p/2377548/

## Basics

| Field | Value |
| --- | --- |
| Title | Todo Task |
| Category | Plasma 6 Widgets |
| License | GPL-3.0-or-later |
| Source / Homepage | https://github.com/adweb-id/plasma-todotask |
| Tags | todo, tasks, productivity, markdown, planner, plasma6, widget, plasmoid |
| Logo | `docs/store/logo-512.png` |
| File | `todotask-<version>.plasmoid` from the GitHub release |

## Screenshots (in this order)

1. `docs/screenshots/overview.png`
2. `docs/screenshots/menu.png`
3. `docs/screenshots/groups.png`
4. `docs/screenshots/toast.png`
5. `docs/screenshots/overview-light.png`
6. `docs/screenshots/about.png`

## Summary (one line)

Today's tasks and a queue in your Plasma panel, carried over by themselves and kept in one Markdown file.

## Description

Todo Task keeps the day's work in the Plasma panel: what is left for today, and a queue of what comes next. Unfinished tasks carry over to tomorrow by themselves, routine work shows up every work day, and everything lives in one plain Markdown file you can also edit by hand. No account, no server.

Features
- Panel or system tray icon with the number of tasks left today
- Today and Queue lists; Enter adds to the Queue, Shift+Enter to Today (can be swapped)
- Tick a task: it pops, is struck through and moves to "Done today"; untick to bring it back
- Unfinished tasks stay in Today on a new day, marked "yesterday"
- Daily routine: tasks in the Daily list are added to the top of Today every work day
- Project groups in the Queue: fold them, add straight to a group, rename and reorder
- Waiting status for work on hold: dimmed, kept at the bottom, skipped by "Pull next" and the counts
- Subtasks with progress (1/3), **bold** and *italic* text, drag to reorder
- Right-click menu: move, edit, add subtask, repeat daily, group, waiting, delete with confirmation
- Undo for 5 seconds after adding, ticking or deleting
- Progress bar for the day in the header
- Finished days are kept per date and moved to monthly archive files after a week
- Choose where the file lives, e.g. a synced folder; reload it with one click
- Smooth, quiet animations that follow Plasma's animation speed; light and dark themes

The file is ordinary Markdown:

    ## Today (2026-10-07)
    - [ ] Fix coupon validation <!-- since:2026-10-06 group:"Webshop" -->
      - [x] Reproduce on staging

    ## Queue
    ### API
    - [ ] Add rate limiting

Lines the widget does not know (notes, code blocks, other sections) are kept exactly where they are.

Requirements
- Plasma 6.0 or newer
- base64, xdg-open and xdg-user-dir (present on common Linux desktops)

Pure QML and JavaScript: nothing to compile, no background service. Writes go through a temporary file and a rename, so the task file is never half written, and task text never reaches the shell as a command.

After installing, right-click the panel, choose "Add Widgets…" and drag Todo Task onto the panel, or turn it on in System Tray Settings → Entries.

Bugs and ideas: https://github.com/adweb-id/plasma-todotask/issues

## Changelog for 0.1.0

First release.
