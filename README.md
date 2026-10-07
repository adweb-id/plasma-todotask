# Todo Task

A KDE Plasma 6 widget for today's tasks and a queue of what comes next, right in
the panel. Unfinished tasks carry over to the next day by themselves, and
everything is stored in one plain Markdown file you can also edit by hand.

- Pure QML + JavaScript, nothing to compile
- Follows your Plasma theme (light and dark, Wayland and X11)
- No account, no server: one `todo.md` in your Documents folder

## Features

- **Panel icon with a badge** showing how many tasks are left today, or `!` when the file cannot be read or written.
- **Two lists**: Today on top, Queue below, each with its count. Click the Queue heading to fold it away; the widget remembers.
- **Project groups** in the Queue (`### SRSX` in the file): fold each group, add to it with ＋, rename or reorder groups; a task moved to Today shows its group and goes back to it.
- **Quick add**: Enter adds to the Queue, Shift+Enter to Today (can be swapped in the settings).
- **Tick to finish**: the task moves to "Done today", where unticking brings it back.
- **Carry-over**: on a new day unfinished tasks stay in Today, marked "yesterday".
- **Waiting**: mark tasks that are on hold; they dim, sink to the bottom and are skipped by *Pull next* and the counts.
- **Daily routine**: tasks in the Daily list are added to the top of Today every work day.
- **Subtasks**, one level deep, with progress such as `1/3` on the parent.
- **Bold and italic**: `**bold**` and `*italic*` are shown formatted.
- **Drag to reorder**, or right-click → *Move to top / bottom*.
- **Undo** for 5 seconds after ticking or deleting.
- **Daily archive**: finished tasks are kept per date, and days older than a week move to a monthly archive file.
- **"All done for today"** with a button that pulls the next task from the queue.

## Requirements

- KDE Plasma 6.0 or newer
- `base64`, `xdg-open` and `xdg-user-dir`, present on common Linux desktops

## Install

**From the KDE Store**: right-click the panel, choose *Add Widgets…*, then
*Get New Widgets…* → *Download New Plasma Widgets*, and search for "Todo Task".

**From a release file**: download `todotask-<version>.plasmoid`, then

    kpackagetool6 -t Plasma/Applet -i todotask-<version>.plasmoid

**From source**:

    git clone https://github.com/adweb-id/plasma-todotask.git
    cd plasma-todotask
    kpackagetool6 -t Plasma/Applet -i .

Installing only makes the widget available. To show it, right-click the panel,
choose *Add Widgets…* and drag **Todo Task** onto the panel, or turn it on in
*System Tray Settings → Entries*.

Update or remove:

    kpackagetool6 -t Plasma/Applet -u .
    kpackagetool6 -t Plasma/Applet -r com.adweb.todotask

After an update, restart Plasma to load the new code:

    kquitapp6 plasmashell && kstart plasmashell

## Using the widget

### Panel icon

| Badge | Meaning |
| --- | --- |
| Number | Tasks left in Today (subtasks are not counted). Hidden at zero. |
| `!` | `todo.md` cannot be read or written. Hover for the reason. |

Hover the icon for a summary such as "3 left today, 4 in queue".
Right-click the icon for:

- **Open todo.md**: opens the file in your default editor.
- **About Todo Task**: version, author, license, and buttons for the source code and bug reports.

### Adding tasks

| Key in the input field | Adds to |
| --- | --- |
| Enter | Queue (or Today, see *Settings*) |
| Shift+Enter | The other list |

A small toast floating over the bottom of the list says where the task went, for 5 seconds, with
**Undo**, and **Show** when the Queue is folded away.

### The task row

A row shows only the checkbox (Today), the text, the subtask progress and the
"yesterday" label. Resting the pointer on it shows three buttons over the end of
the text, without moving anything:

| Button | Does |
| --- | --- |
| ⋮⋮ | Drag to reorder within the list |
| ↑ / ↓ | Move to Today / to the Queue |
| ⋯ | Opens the same menu as a right-click |

Ticking plays a short animation (the box pops, the text is struck through) before
the task slides out to *Done today*. Rows slide in and out, folded lists ease
open, and the bar in the header fills as the day's tasks are done. All motion
follows Plasma's animation speed and stops when animations are turned off.
All icons are the widget's own and take the theme's text colour.

Double-click the text to edit it: Enter saves, Esc cancels.

### Right-click menu

| On | Items |
| --- | --- |
| A task | Move to Today / Queue, Move to top, Move to bottom, Edit, Add subtask, Repeat every work day (or Stop repeating), Delete |
| A Daily task | Move to top, Move to bottom, Edit, Add subtask, Delete |
| A subtask | Edit, Delete |

*Delete* asks first, under the row: "Delete this task?" with **Delete** and
**Cancel**; it gives up after 6 seconds. Deleting a task also deletes its subtasks. Ticking a parent finishes all its
subtasks; ticking every subtask does not finish the parent.

### Project groups

The Queue can be split into groups, one per project. In the file a group is a
`### Name` heading under `## Queue`; tasks above the first heading have no group.

- Click a group heading to fold it; the widget remembers which are folded.
- ＋ on a heading puts the cursor in the input with the group shown as a chip:
  everything you add goes to that group until you press Esc or click ✕.
- ⋯ or a right-click on a heading: Add task here, Rename, Move group up/down,
  Remove group (its tasks stay, without a group).
- Right-click a task → **Move to group…** to pick a group, choose *No group*,
  or type a new group name.
- Dragging reorders within a group. A task moved to Today shows its group as a
  small label and returns to the same group when moved back.

### Waiting tasks

Right-click a task → **Mark as waiting** for work that is on hold (waiting for a
server, a colleague, a decision). It stays in its list but steps back:

- dimmed, with a ⏸ *waiting* label, and moved below the tasks you can work on;
- skipped by *Pull next*;
- not counted in the panel badge, "x left" or the progress bar
  (the header says e.g. "3 left · 1 waiting").

Right-click → **Not waiting anymore** brings it back. In the file it is the
`waiting` tag: `- [ ] deploy widget <!-- waiting -->`.

### Daily tasks

Routine work goes in the **Daily** list, at the bottom of the popup (folded by
default). On every work day a copy of each Daily task is added to the top of
Today, marked with 🔁, and ticked like any other task.

- Right-click a task → **Repeat every work day** to make it daily; right-click a copy → **Stop repeating**.
- An unfinished copy from yesterday is replaced by today's, never doubled, and never marked "yesterday".
- Work days are Monday to Friday by default; change them in the settings.

### A new day

Checked when the widget loads and once a minute:

1. The Today heading in the file gets today's date.
2. On a work day, fresh copies of the Daily tasks go to the top of Today.
3. Unfinished tasks stay in Today and show "yesterday". With *carry-over* off they go back to the top of the Queue instead.
4. The Queue does not change.

## The todo.md file

Plain Markdown, readable and editable in any editor:

```markdown
# To-do

## Daily
- [ ] Check the backup report at 09.00

## Today (2026-10-06)
- [ ] Check the backup report at 09.00 <!-- since:2026-10-06 daily -->
- [ ] Fix **checkout bug** on the payment page <!-- since:2026-10-05 -->
  - [x] Reproduce on staging
  - [ ] Fix coupon validation
- [ ] Review the sign-up form PR <!-- since:2026-10-06 -->

## Queue
- [ ] Update the API docs

## Done
### 2026-10-06
- [x] Set up SSL for the client domain
```

- Tasks are `- [ ]` / `- [x]` lines; subtasks are indented two spaces under their parent.
- The `since` comment records when a task entered Today and drives the "yesterday" label.
- Nothing is lost or moved away from its task: deeper indented lines, paragraphs and code blocks are kept as notes of the task or subtask above them, exactly where they were. Code blocks are never read as tasks.
- A bullet without a box (`- text`) counts as a task and is written back as `- [ ] text`.
- Any other `#`/`##` section is kept whole (it moves below Done) and never read as tasks.
- Edits made in another editor are picked up when the popup opens.

Finished days older than *Archive after* move to a monthly file next to it,
for example `todo-archive-2026-10.md`. A day is removed from `todo.md` only
after it has been written to the archive, so nothing is ever lost.

## Settings

Right-click the widget → *Configure Todo Task…*

| Setting | Default | Notes |
| --- | --- | --- |
| Enter adds a task to | Queue | Shift+Enter always adds to the other list |
| Popup width (pixels) | 380 | 300 to 800 |
| New day: keep unfinished tasks in Today | on | Off sends them back to the Queue |
| Daily tasks on | Mon–Fri | Work days the Daily tasks are added to Today |
| Archive finished tasks after (days) | 7 | 0 keeps everything in `todo.md` |

## How it works

- `store.js` parses and writes `todo.md`; `tasks.js` holds every operation.
- Writes go through a temp file and `mv`, so `todo.md` is never half written.
- The content travels to the shell as base64 in pieces, so task text can never
  be read as a command and the file size is not limited.
- Nothing runs in the background except the once-a-minute date check.

## Troubleshooting

- **The widget is not in the panel after installing.** Installing only registers it; add it with *Add Widgets…* or in the system tray entries.
- **Changes do not show after updating.** Restart Plasma: `kquitapp6 plasmashell && kstart plasmashell`.
- **The badge shows `!`.** Hover it for the error; check that `~/Documents/todo.md` is writable, then use *Try again* in the popup.

## Development

    contents/ui/main.qml                  document, file access, models, undo, panel menu
    contents/ui/store.js                  todo.md parser/writer, shell commands
    contents/ui/tasks.js                  task operations
    contents/ui/CompactRepresentation.qml panel icon + badge
    contents/ui/FullRepresentation.qml    popup
    contents/ui/TaskDelegate.qml          one task row, its subtasks and right-click menus
    contents/ui/AboutView.qml             About page (name, version and links from metadata.json)
    contents/ui/Glyph.qml                 one of the widget's own icons, in the theme's colour
    contents/ui/IconButton.qml            small flat / accent / danger button
    contents/ui/TaskCheck.qml             animated check box
    contents/ui/ContextMenu.qml           right-click menu (MenuEntry.qml, MenuLine.qml)
    contents/ui/ProgressStrip.qml         today's progress bar in the header
    contents/ui/GroupHeading.qml          heading of a Queue group (fold, add, rename, move)
    contents/icons/tt-*.svg               the widget's icon set (16 px, one colour)
    contents/ui/configGeneral.qml         settings page
    contents/config/main.xml              settings schema
    contents/icons/todotask-symbolic.svg  panel icon (one colour, follows the theme)
    contents/icons/todotask-logo.svg      colour logo for the About page
    store-icon.svg                        colour logo for the store listing (not part of the package)

`store.js` and `tasks.js` have no QML dependencies, so they can be tested with plain Node.js.

Build a release file:

    zip -r todotask-<version>.plasmoid metadata.json contents

Before a release, raise `Version` in `metadata.json`.

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/adweb-id/plasma-todotask/issues>.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
