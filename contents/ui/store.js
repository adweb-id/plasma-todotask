.pragma library

// todo.md <-> document object, plus the shell commands that read and write it.
//
// doc = {
//   preamble:  [lines before the first section],
//   todayDate: "2026-10-06",
//   daily:     [task]   template, copied to the top of Today every work day
//   today:     [task], queue: [task],
//   groups:    ["SRSX", "Livechat"]   project groups of the Queue ("### SRSX"), in order;
//              queue tasks without a group come first
//   done:      [{ date: "2026-10-06", items: [task] }],   newest first
//   extra:     { daily: [], today: [], queue: [], done: [] }   lines between a
//              section heading and its first task, written back in that place
//   groupHead: { "SRSX": [lines between "### SRSX" and its first task] },
//   others:    [lines of any other "#"/"##" section, kept as they are]
// }
// task = { text, done, since, daily, waiting, group, notes: [], subs: [{ text, done, notes: [] }] }
// Tags after the task text, in one comment: <!-- since:2026-10-07 daily waiting group:"rw livechat" -->
// `waiting` marks a task that is on hold (waiting for someone or something).
// `daily` marks a copy made from the Daily template; `group` remembers the
// project of a task outside the Queue (inside it, the "###" heading says it).
//
// Nothing the widget does not understand is lost or moved away from its task:
// deeper indented lines, plain paragraphs and code blocks become `notes` of
// the task or subtask above them and are written back verbatim, right there.
// A bullet without a check box ("- text") counts as a task and gets "[ ]".

var MISSING = "__TODOTASK_MISSING__";

function emptyDoc(today) {
    return {
        preamble: ["# To-do"],
        todayDate: today,
        daily: [],
        today: [],
        queue: [],
        done: [],
        groups: [],
        groupHead: {},
        extra: { daily: [], today: [], queue: [], done: [] },
        others: []
    };
}

var TAG = '(?:since:\\d{4}-\\d{2}-\\d{2}|daily|waiting|group:"(?:[^"\\\\]|\\\\.)*")';
var TAGS = new RegExp("\\s*<!--\\s*(" + TAG + "(?:\\s+" + TAG + ")*)\\s*-->\\s*$");

function makeTask(rawText, done) {
    var since = "";
    var daily = false;
    var waiting = false;
    var group = "";
    var text = rawText;
    // A trailing comment made only of our tags; any other comment stays in the text
    var m = TAGS.exec(rawText);
    if (m) {
        text = rawText.slice(0, m.index);
        var tag;
        var each = new RegExp(TAG, "g");
        while ((tag = each.exec(m[1])) !== null) {
            if (tag[0] === "daily") {
                daily = true;
            } else if (tag[0] === "waiting") {
                waiting = true;
            } else if (tag[0].indexOf("since:") === 0) {
                since = tag[0].slice(6);
            } else {
                group = tag[0].slice(7, -1).replace(/\\(.)/g, "$1");
            }
        }
    }
    return { text: text.trim(), done: done, since: since, daily: daily, waiting: waiting, group: group, notes: [], subs: [] };
}

// Width of the leading white space; a tab counts as one list level (2)
function indentOf(line) {
    var width = 0;
    for (var i = 0; i < line.length; i++) {
        if (line.charAt(i) === " ") {
            width += 1;
        } else if (line.charAt(i) === "\t") {
            width += 2;
        } else {
            break;
        }
    }
    return width;
}

// "- [x] text", "* [ ] text" or a plain "- text": { done, text } or null
function bullet(line) {
    var m = /^\s*[-*+] \[([ xX])\] (.*)$/.exec(line);
    if (m) {
        return { done: m[1] !== " ", text: m[2], box: true };
    }
    m = /^\s*[-*+] (\S.*)$/.exec(line);
    if (m) {
        return { done: false, text: m[1], box: false };
    }
    return null;
}

function parse(text, today) {
    var doc = emptyDoc(today);
    doc.preamble = [];
    var section = "";
    var group = null;
    var task = null;     // the task new subtasks and notes belong to
    var groupName = "";  // the Queue group ("### SRSX") new tasks go to
    var blanks = 0;      // blank lines seen since the last kept line
    var fence = false;   // inside a ``` code block: every line is a note
    var lines = (text || "").split("\n");
    if (lines.length > 0 && lines[lines.length - 1] === "") {
        lines.pop();
    }

    function startSection(name) {
        section = name;
        group = null;
        groupName = "";
        task = null;
        blanks = 0;
        fence = false;
    }

    // A line that belongs to whatever came last: subtask, task or section head
    function note(line) {
        var target;
        if (task && task.subs.length > 0) {
            target = task.subs[task.subs.length - 1].notes;
        } else if (task) {
            target = task.notes;
        } else if (section === "queue" && groupName !== "") {
            target = doc.groupHead[groupName];
        } else {
            target = doc.extra[section];
        }
        // Blank lines inside a note block are kept; around tasks they are regenerated
        if (target.length > 0) {
            for (; blanks > 0; blanks--) {
                target.push("");
            }
        }
        blanks = 0;
        target.push(line);
    }

    for (var i = 0; i < lines.length; i++) {
        var line = lines[i].replace(/\r$/, "");
        var m;

        if (section === "other") {
            if (!/^##\s+(Today|Daily|Queue|Done)\b/i.test(line)) {
                doc.others.push(line);
                continue;
            }
        }

        if (fence || /^\s*(```|~~~)/.test(line)) {
            if (/^\s*(```|~~~)/.test(line)) {
                fence = !fence;
            }
            if (section) {
                note(line);
            } else {
                doc.preamble.push(line);
            }
            continue;
        }

        if ((m = /^##\s+Today\b(?:\s*\((\d{4}-\d{2}-\d{2})\))?\s*$/i.exec(line))) {
            startSection("today");
            doc.todayDate = m[1] || today;
            continue;
        }
        if (/^##\s+Daily\s*$/i.test(line)) {
            startSection("daily");
            continue;
        }
        if (/^##\s+Queue\s*$/i.test(line)) {
            startSection("queue");
            continue;
        }
        if (/^##\s+Done\s*$/i.test(line)) {
            startSection("done");
            continue;
        }
        // Any other top-level section is kept whole, never read as tasks
        if (section && /^#{1,2}\s/.test(line)) {
            startSection("other");
            doc.others.push(line);
            continue;
        }
        if (!section) {
            doc.preamble.push(line);
            continue;
        }

        if (line.trim() === "") {
            blanks++;
            continue;
        }

        if (section === "done" && (m = /^###\s+(\d{4}-\d{2}-\d{2})\s*$/.exec(line))) {
            group = { date: m[1], items: [] };
            doc.done.push(group);
            task = null;
            blanks = 0;
            continue;
        }

        if (section === "queue" && (m = /^###\s+(.*\S)\s*$/.exec(line))) {
            groupName = m[1];
            if (doc.groups.indexOf(groupName) === -1) {
                doc.groups.push(groupName);
                doc.groupHead[groupName] = [];
            }
            task = null;
            blanks = 0;
            continue;
        }

        var level = indentOf(line);
        var item = bullet(line);

        if (item && level === 0) {
            task = makeTask(item.text, item.done || (section === "done" && !item.box));
            if (section === "done") {
                if (!group) {
                    group = { date: today, items: [] };
                    doc.done.push(group);
                }
                group.items.push(task);
            } else {
                if (section === "queue") {
                    task.group = groupName;
                }
                doc[section].push(task);
            }
            blanks = 0;
            continue;
        }
        if (item && task && level < 4) {
            task.subs.push({ text: item.text.trim(), done: item.done, notes: [] });
            blanks = 0;
            continue;
        }
        note(line);
    }

    if (doc.preamble.length === 0) {
        doc.preamble = ["# To-do"];
    }
    while (doc.preamble.length > 1 && doc.preamble[doc.preamble.length - 1].trim() === "") {
        doc.preamble.pop();
    }
    return doc;
}

// withGroup: false inside the Queue, where the "###" heading names the group
function taskLines(task, withSince, withGroup) {
    var line = "- [" + (task.done ? "x" : " ") + "] " + task.text;
    var tags = [];
    if (withSince && task.since) {
        tags.push("since:" + task.since);
    }
    if (task.daily) {
        tags.push("daily");
    }
    if (task.waiting) {
        tags.push("waiting");
    }
    if (withGroup !== false && task.group) {
        tags.push('group:"' + task.group.replace(/(["\\])/g, "\\$1") + '"');
    }
    if (tags.length > 0) {
        line += " <!-- " + tags.join(" ") + " -->";
    }
    var out = [line].concat(task.notes || []);
    for (var i = 0; i < task.subs.length; i++) {
        out.push("  - [" + (task.subs[i].done ? "x" : " ") + "] " + task.subs[i].text);
        out = out.concat(task.subs[i].notes || []);
    }
    return out;
}

function serialize(doc) {
    var out = doc.preamble.slice();
    out.push("");

    function section(heading, head, tasks, withSince) {
        out.push(heading);
        out = out.concat(head);
        tasks.forEach(function (t) { out = out.concat(taskLines(t, withSince)); });
        out.push("");
    }

    section("## Daily", doc.extra.daily, doc.daily, false);
    section("## Today (" + doc.todayDate + ")", doc.extra.today, doc.today, true);

    // Queue: tasks without a group, then one "###" block per group
    out.push("## Queue");
    out = out.concat(doc.extra.queue);
    var groups = (doc.groups || []).slice();
    doc.queue.forEach(function (t) {
        if (t.group && groups.indexOf(t.group) === -1) {
            groups.push(t.group);
        }
    });
    doc.queue.forEach(function (t) {
        if (!t.group) {
            out = out.concat(taskLines(t, false, false));
        }
    });
    groups.forEach(function (name) {
        if (out[out.length - 1] !== "") {
            out.push("");
        }
        out.push("### " + name);
        out = out.concat((doc.groupHead || {})[name] || []);
        doc.queue.forEach(function (t) {
            if (t.group === name) {
                out = out.concat(taskLines(t, false, false));
            }
        });
    });
    out.push("");

    out.push("## Done");
    out = out.concat(doc.extra.done);
    doc.done.forEach(function (g) {
        if (g.items.length === 0) {
            return;
        }
        out.push("### " + g.date);
        g.items.forEach(function (t) { out = out.concat(taskLines(t, false)); });
    });

    var others = (doc.others || []).slice();
    while (others.length > 0 && others[others.length - 1].trim() === "") {
        others.pop();
    }
    if (others.length > 0) {
        out.push("");
        out = out.concat(others);
    }

    return out.join("\n") + "\n";
}

// ---- shell helpers -------------------------------------------------------

// Single-quote a value for the shell.
function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'";
}

function utf8Bytes(text) {
    var encoded = encodeURIComponent(text);
    var bytes = [];
    for (var i = 0; i < encoded.length; i++) {
        if (encoded.charAt(i) === "%") {
            bytes.push(parseInt(encoded.substr(i + 1, 2), 16));
            i += 2;
        } else {
            bytes.push(encoded.charCodeAt(i));
        }
    }
    return bytes;
}

// Base64 of the UTF-8 bytes, so task text can never be read as shell syntax.
function base64(text) {
    var table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var bytes = utf8Bytes(text);
    var out = "";
    for (var i = 0; i < bytes.length; i += 3) {
        var b0 = bytes[i];
        var b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
        var b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
        out += table.charAt(b0 >> 2);
        out += table.charAt(((b0 & 3) << 4) | (b1 >> 4));
        out += i + 1 < bytes.length ? table.charAt(((b1 & 15) << 2) | (b2 >> 6)) : "=";
        out += i + 2 < bytes.length ? table.charAt(b2 & 63) : "=";
    }
    return out;
}

// Prints the user's Documents folder, falling back to the home folder.
function folderCommand() {
    return "d=$(xdg-user-dir DOCUMENTS 2>/dev/null); [ -n \"$d\" ] && [ -d \"$d\" ] || d=\"$HOME\"; printf %s \"$d\"";
}

function readCommand(path) {
    var p = quote(path);
    return "if [ -f " + p + " ]; then cat " + p + "; else printf %s " + MISSING + "; fi";
}

var CHUNK = 60000; // characters of base64 per command, well under the kernel's per-argument limit

// Commands that write `text` to `path`, to be run one after another.
// The content travels as base64 in pieces, so there is no size limit, and it
// lands in a temp file first: todo.md is replaced by a rename, never half written.
// With `append` the decoded text is added to the end of `path` instead
// (used for archive files); `header` is written first if that file is new.
function writeCommands(path, text, append, header) {
    var encoded = base64(text);
    var b64 = quote(path + ".b64");
    var tmp = quote(path + ".tmp");
    var target = quote(path);
    var commands = [];
    for (var i = 0; i < encoded.length || i === 0; i += CHUNK) {
        commands.push("printf %s " + quote(encoded.substr(i, CHUNK)) + (i === 0 ? " > " : " >> ") + b64);
    }
    var finish;
    if (append) {
        finish = (header ? "{ [ -f " + target + " ] || printf '%s\\n\\n' " + quote(header) + " > " + target + "; } && " : "")
            + "base64 -d < " + b64 + " >> " + target;
    } else {
        finish = "base64 -d < " + b64 + " > " + tmp + " && mv " + tmp + " " + target;
    }
    commands[commands.length - 1] += " && " + finish + " && rm -f " + b64;
    return commands;
}

// todo.md + "2026-10" -> todo-archive-2026-10.md, next to the main file
function archivePath(path, month) {
    return path.replace(/\.md$/i, "") + "-archive-" + month + ".md";
}

// Text appended to an archive file: one "### date" block per day.
function archiveText(groups) {
    var out = [];
    groups.forEach(function (g) {
        out.push("### " + g.date);
        g.items.forEach(function (t) { out = out.concat(taskLines(t, false)); });
        out.push("");
    });
    return out.join("\n") + "\n";
}

function openCommand(path) {
    return "xdg-open " + quote(path);
}
