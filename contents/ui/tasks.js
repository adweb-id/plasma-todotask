.pragma library

// Every change the user can make, as plain functions on the document object
// from store.js. No file access and no QML types in here.

function otherList(name) {
    return name === "today" ? "queue" : "today";
}

function doneGroup(doc, date) {
    for (var i = 0; i < doc.done.length; i++) {
        if (doc.done[i].date === date) {
            return doc.done[i];
        }
    }
    var group = { date: date, items: [] };
    doc.done.unshift(group); // newest first
    return group;
}

function doneToday(doc, today) {
    for (var i = 0; i < doc.done.length; i++) {
        if (doc.done[i].date === today) {
            return doc.done[i].items;
        }
    }
    return [];
}

// 0 = Sunday ... 6 = Saturday, like Date.getDay()
function weekday(date) {
    return new Date(Date.parse(date + "T00:00:00Z")).getUTCDay();
}

// A fresh Today copy of a Daily template task
function dailyCopy(template, today) {
    return {
        text: template.text,
        done: false,
        since: today,
        daily: true,
        notes: (template.notes || []).slice(),
        subs: template.subs.map(function (s) { return { text: s.text, done: false, notes: (s.notes || []).slice() }; })
    };
}

// Run when the file is loaded and once a minute. Returns true if it changed anything.
//  - a task ticked by hand in the file moves to the archive
//  - on a new day the Today heading gets the new date; unfinished tasks stay
//    (or go back to the top of the queue when carry-over is off)
//  - on a new work day (dailyDays, getDay() numbers) yesterday's unfinished
//    daily copies are replaced by fresh ones at the top of Today
function normalize(doc, today, carryOver, dailyDays) {
    var changed = false;

    var open = [];
    for (var i = 0; i < doc.today.length; i++) {
        var task = doc.today[i];
        if (task.done) {
            doneGroup(doc, doc.todayDate).items.push(task);
            changed = true;
        } else {
            if (!task.since) {
                task.since = doc.todayDate;
                changed = true;
            }
            open.push(task);
        }
    }
    doc.today = open;

    if (doc.todayDate !== today) {
        doc.today = doc.today.filter(function (t) { return !t.daily; });
        if (!carryOver) {
            doc.today.forEach(function (t) { t.since = ""; });
            doc.queue = doc.today.concat(doc.queue);
            doc.today = [];
        }
        if ((dailyDays || []).indexOf(weekday(today)) !== -1) {
            doc.today = doc.daily.map(function (t) { return dailyCopy(t, today); }).concat(doc.today);
        }
        doc.todayDate = today;
        changed = true;
    }
    return changed;
}

// A task line holds one line of text: pasted line breaks become spaces,
// otherwise the rest would land in the file as lines under the task.
function oneLine(text) {
    return String(text || "").replace(/\s*[\r\n]+\s*/g, " ").trim();
}

function add(doc, listName, text, today, group) {
    text = oneLine(text);
    if (!text) {
        return false;
    }
    doc[listName].push({ text: text, done: false, since: listName === "today" ? today : "",
                         group: group || "", notes: [], subs: [] });
    return true;
}

// ---- Queue groups ("### SRSX" in the file) ------------------------------

// Keeps the Queue in file order: tasks without a group first, then group by
// group, each keeping its own order, waiting tasks at the end of their group
// (and of Today). Every change runs it, so the list views
// can rely on the tasks of one group being next to each other.
function tidy(doc) {
    var buckets = { "": [] };
    doc.groups.forEach(function (name) { buckets[name] = []; });
    doc.queue.forEach(function (t) {
        var name = t.group || "";
        if (!buckets[name]) {
            doc.groups.push(name);
            buckets[name] = [];
        }
        buckets[name].push(t);
    });
    var ordered = activeFirst(buckets[""]);
    doc.groups.forEach(function (name) { ordered = ordered.concat(activeFirst(buckets[name])); });
    doc.queue = ordered;
    doc.today = activeFirst(doc.today);
}

// Moves a task to another group ("" = none), at the end of that group
function setGroup(doc, listName, index, group) {
    var task = doc[listName][index];
    if (!task) {
        return;
    }
    group = oneLine(group);
    if (group && doc.groups.indexOf(group) === -1) {
        doc.groups.push(group);
        doc.groupHead[group] = [];
    }
    task.group = group;
    if (listName === "queue") {
        doc.queue.splice(index, 1);
        doc.queue.push(task);
    }
}

function eachTask(doc, fn) {
    doc.today.forEach(fn);
    doc.queue.forEach(fn);
    doc.done.forEach(function (g) { g.items.forEach(fn); });
}

// Renaming onto an existing group merges the two
function renameGroup(doc, from, to) {
    to = oneLine(to);
    var at = doc.groups.indexOf(from);
    if (!to || at === -1 || to === from) {
        return;
    }
    if (doc.groups.indexOf(to) === -1) {
        doc.groups[at] = to;
        doc.groupHead[to] = doc.groupHead[from] || [];
    } else {
        doc.groups.splice(at, 1);
        doc.groupHead[to] = (doc.groupHead[to] || []).concat(doc.groupHead[from] || []);
    }
    delete doc.groupHead[from];
    eachTask(doc, function (t) {
        if (t.group === from) {
            t.group = to;
        }
    });
}

// The group goes; its tasks stay, without a group
function removeGroup(doc, name) {
    var at = doc.groups.indexOf(name);
    if (at === -1) {
        return;
    }
    doc.groups.splice(at, 1);
    var head = doc.groupHead[name] || [];
    delete doc.groupHead[name];
    doc.extra.queue = doc.extra.queue.concat(head);
    eachTask(doc, function (t) {
        if (t.group === name) {
            t.group = "";
        }
    });
}

function moveGroup(doc, name, delta) {
    var at = doc.groups.indexOf(name);
    var to = at + delta;
    if (at === -1 || to < 0 || to >= doc.groups.length) {
        return;
    }
    doc.groups.splice(at, 1);
    doc.groups.splice(to, 0, name);
}

// Task counts per group of the Queue: { "SRSX": 4 }
function groupCounts(doc) {
    var counts = {};
    doc.queue.forEach(function (t) {
        if (t.group) {
            counts[t.group] = (counts[t.group] || 0) + 1;
        }
    });
    return counts;
}

function complete(doc, index, today) {
    var task = doc.today.splice(index, 1)[0];
    if (!task) {
        return;
    }
    task.done = true;
    task.waiting = false;
    task.subs.forEach(function (s) { s.done = true; });
    doneGroup(doc, today).items.unshift(task);
}

function uncomplete(doc, index, today) {
    var task = doneToday(doc, today).splice(index, 1)[0];
    if (!task) {
        return;
    }
    task.done = false;
    task.since = today;
    doc.today.push(task);
}

// Queue -> end of Today, Today -> top of Queue
function move(doc, listName, index, today) {
    var task = doc[listName].splice(index, 1)[0];
    if (!task) {
        return;
    }
    if (listName === "queue") {
        task.since = today;
        doc.today.push(task);
    } else {
        task.since = "";
        task.daily = false;
        doc.queue.unshift(task);
    }
}

// Repeat a Today or Queue task every work day. It becomes today's copy
// (a Queue task moves to the end of Today), and the template goes to Daily.
function makeDaily(doc, listName, index, today) {
    var task = doc[listName][index];
    if (!task || task.daily) {
        return;
    }
    doc.daily.push({
        text: task.text,
        done: false,
        since: "",
        daily: false,
        notes: (task.notes || []).slice(),
        subs: task.subs.map(function (s) { return { text: s.text, done: false, notes: (s.notes || []).slice() }; })
    });
    if (listName === "queue") {
        doc.queue.splice(index, 1);
        task.since = today;
        doc.today.push(task);
    }
    task.daily = true;
}

// A Today copy stops repeating: it stays as a normal task and its template goes.
function stopDaily(doc, index) {
    var task = doc.today[index];
    if (!task || !task.daily) {
        return;
    }
    task.daily = false;
    for (var i = 0; i < doc.daily.length; i++) {
        if (doc.daily[i].text === task.text) {
            doc.daily.splice(i, 1);
            return;
        }
    }
}

// Within one list, to the first or last place
function moveToEdge(doc, listName, index, toTop) {
    var task = doc[listName].splice(index, 1)[0];
    if (!task) {
        return;
    }
    if (toTop) {
        doc[listName].unshift(task);
    } else {
        doc[listName].push(task);
    }
}

// The first Queue task that is not waiting
function pullNext(doc, today) {
    for (var i = 0; i < doc.queue.length; i++) {
        if (!doc.queue[i].waiting) {
            move(doc, "queue", i, today);
            return;
        }
    }
}

// ---- waiting (on hold) ---------------------------------------------------

function setWaiting(doc, listName, index, on) {
    var task = doc[listName][index];
    if (task) {
        task.waiting = !!on;
    }
}

// Tasks that can be worked on first, waiting ones after, each keeping its order
function activeFirst(list) {
    return list.filter(function (t) { return !t.waiting; })
               .concat(list.filter(function (t) { return t.waiting; }));
}

function activeCount(list) {
    return list.filter(function (t) { return !t.waiting; }).length;
}

function remove(doc, listName, index) {
    doc[listName].splice(index, 1);
}

function edit(doc, listName, index, text) {
    text = oneLine(text);
    if (text && doc[listName][index]) {
        doc[listName][index].text = text;
    }
}

function addSub(doc, listName, index, text) {
    text = oneLine(text);
    if (text && doc[listName][index]) {
        doc[listName][index].subs.push({ text: text, done: false });
    }
}

function toggleSub(doc, listName, index, subIndex) {
    var sub = doc[listName][index] && doc[listName][index].subs[subIndex];
    if (sub) {
        sub.done = !sub.done;
    }
}

function editSub(doc, listName, index, subIndex, text) {
    text = oneLine(text);
    var sub = doc[listName][index] && doc[listName][index].subs[subIndex];
    if (text && sub) {
        sub.text = text;
    }
}

function removeSub(doc, listName, index, subIndex) {
    if (doc[listName][index]) {
        doc[listName][index].subs.splice(subIndex, 1);
    }
}

// A subtask becomes a task of its own, right below its parent, in the
// parent's list and group. Its notes go with it.
function promoteSub(doc, listName, index, subIndex, today) {
    var parent = doc[listName][index];
    var sub = parent && parent.subs[subIndex];
    if (!sub) {
        return;
    }
    parent.subs.splice(subIndex, 1);
    doc[listName].splice(index + 1, 0, {
        text: sub.text,
        done: false,
        since: listName === "today" ? today : "",
        daily: false,
        waiting: false,
        group: parent.group || "",
        notes: (sub.notes || []).slice(),
        subs: []
    });
}

// Moves a subtask up (delta -1) or down (+1) within its parent
function moveSub(doc, listName, index, subIndex, delta) {
    var parent = doc[listName][index];
    var to = subIndex + delta;
    if (!parent || subIndex < 0 || subIndex >= parent.subs.length || to < 0 || to >= parent.subs.length) {
        return;
    }
    var sub = parent.subs.splice(subIndex, 1)[0];
    parent.subs.splice(to, 0, sub);
}

function subDone(task) {
    return task.subs.filter(function (s) { return s.done; }).length;
}

// **bold** and *italic* only. Everything else, HTML included, shows as typed.
function styled(text) {
    var safe = String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
    return safe
        .replace(/\*\*([^*\s](?:[^*]*[^*\s])?)\*\*/g, "<b>$1</b>")
        .replace(/\*([^*\s](?:[^*]*[^*\s])?)\*/g, "<i>$1</i>");
}

// "2026-10-06" minus 7 days -> "2026-09-29"
function daysBefore(date, days) {
    var time = Date.parse(date + "T00:00:00Z") - days * 86400000;
    return new Date(time).toISOString().slice(0, 10);
}

// Finished days older than `days`, oldest first, grouped by month:
// [{ month: "2026-09", groups: [{ date, items }] }]
function oldDone(doc, today, days) {
    if (days <= 0) {
        return [];
    }
    var cutoff = daysBefore(today, days);
    var old = doc.done.filter(function (g) { return g.date < cutoff && g.items.length > 0; });
    old.sort(function (a, b) { return a.date < b.date ? -1 : a.date > b.date ? 1 : 0; });
    var months = [];
    old.forEach(function (g) {
        var month = g.date.slice(0, 7);
        var last = months[months.length - 1];
        if (!last || last.month !== month) {
            last = { month: month, groups: [] };
            months.push(last);
        }
        last.groups.push(g);
    });
    return months;
}

// Remove archived days from the document, by date.
function dropDone(doc, dates) {
    doc.done = doc.done.filter(function (g) { return dates.indexOf(g.date) === -1; });
}
