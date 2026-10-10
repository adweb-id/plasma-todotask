import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support

import "store.js" as Store
import "tasks.js" as Tasks

PlasmoidItem {
    id: root

    // The whole todo.md as an object (see store.js). Changed only through change().
    property var doc: null
    property string filePath: ""
    // From the shell at start: the home and Documents folders, and the default task file
    property string homeFolder: ""
    property string documentsFolder: ""
    property string defaultPath: ""
    property bool pathsReady: false
    readonly property string displayPath: Store.displayPath(filePath, homeFolder)

    // Workspaces from the settings; without any there is one unnamed workspace on filePath
    readonly property var workspaceList: {
        try {
            const list = JSON.parse(Plasmoid.configuration.workspaces || "[]");
            return Array.isArray(list) ? list.filter(w => w && w.name) : [];
        } catch (e) {
            return [];
        }
    }
    // What is offered: [{ name, path }] with the path to open (a file or a folder)
    readonly property var workspaces: workspaceList.length > 0
        ? workspaceList.map(w => ({ name: w.name, path: Store.resolvePath(w.path, homeFolder, documentsFolder, defaultPath) }))
        : [{ name: "", path: Store.resolvePath(Plasmoid.configuration.filePath, homeFolder, documentsFolder, defaultPath) }]
    readonly property int activeIndex: Math.max(0, workspaces.findIndex(w => w.name === Plasmoid.configuration.activeWorkspace))
    readonly property string activeName: workspaces[activeIndex].name
    // The configured path of the active workspace; load() turns a folder into the file inside it
    readonly property string targetPath: pathsReady ? workspaces[activeIndex].path : ""
    property string openedTarget: ""
    onTargetPathChanged: openTarget()

    // Fold state: the first workspace uses the plain settings, the others their own entry
    readonly property var workspaceFolds: {
        try {
            return JSON.parse(Plasmoid.configuration.workspaceFolds || "{}") || {};
        } catch (e) {
            return {};
        }
    }
    readonly property var ownFolds: activeIndex === 0 ? null : (workspaceFolds[activeName] || {})
    readonly property bool queueCollapsed: ownFolds ? ownFolds.queue === true : Plasmoid.configuration.queueCollapsed
    readonly property bool dailyCollapsed: ownFolds ? ownFolds.daily !== false : Plasmoid.configuration.dailyCollapsed
    property bool loaded: false
    property string errorText: ""

    property int todayCount: 0
    property int queueCount: 0
    property int dailyCount: 0
    // todayCount and queueCount leave out waiting tasks; these count them too
    property int todayTotal: 0
    property int todayWaiting: 0
    property int queueTotal: 0

    // Queue groups ("### SRSX"): names in order, task counts, and the folded ones
    property var groupNames: []
    property var groupCounts: ({})
    readonly property var foldedGroups: {
        if (ownFolds) {
            return ownFolds.groups || [];
        }
        try {
            return JSON.parse(Plasmoid.configuration.foldedGroups || "[]");
        } catch (e) {
            return [];
        }
    }
    // While set, the input adds tasks to this Queue group
    property string addGroup: ""

    // Asks the popup to put the cursor in the input
    signal inputRequested()
    property int doneCount: 0

    property bool writing: false
    property bool writeQueued: false
    property bool archiving: false

    // Undo: the file content from before the last add, tick or delete, kept for 5 seconds
    property string undoSnapshot: ""

    // What the toast says about that change; noticeList is the list it went to
    property string noticeText: ""
    property string noticeList: ""

    // A short confirmation that changes nothing (e.g. "Copied …"). It is shown
    // over the notice for 2 seconds and leaves a pending Undo alone.
    property string flashText: ""

    property int nextUid: 1

    // The popup shows the About page instead of the lists (from the panel icon's menu)
    property bool showAbout: false
    // Set by "Switch workspace…": the popup opens its workspace menu
    property bool workspaceMenuWanted: false

    readonly property alias todayModel: todayModel
    readonly property alias queueModel: queueModel
    readonly property alias dailyModel: dailyModel
    readonly property alias doneModel: doneModel
    readonly property int popupWidth: Plasmoid.configuration.popupWidth
    readonly property url iconSource: Qt.resolvedUrl("../icons/todotask-symbolic.svg")

    Plasmoid.icon: iconSource
    toolTipMainText: i18n("Todo Task")
    toolTipSubText: errorText !== "" ? errorText
                                      : i18n("%1 left today, %2 in queue", todayCount, queueCount)

    // Plasma's own menu: theme icons, like its other entries
    Plasmoid.contextualActions: [openAction, switchAction, aboutAction]

    // One line whatever the number of workspaces: with two it switches to
    // the other one, with more it opens the popup with the workspace menu
    PlasmaCore.Action {
        id: switchAction
        readonly property int other: root.activeIndex === 0 ? 1 : 0
        text: root.workspaces.length === 2 ? i18n("Switch to %1", root.workspaces[other].name)
                                           : i18n("Switch workspace…")
        icon.name: "exchange-positions"
        visible: root.workspaces.length > 1
        onTriggered: {
            if (root.workspaces.length === 2) {
                root.switchWorkspace(other);
            } else {
                root.showAbout = false;
                root.workspaceMenuWanted = true;
                root.expanded = true;
            }
        }
    }

    PlasmaCore.Action {
        id: openAction
        text: root.filePath !== "" ? i18n("Open %1", root.filePath.split("/").pop()) : i18n("Open task file")
        icon.name: "document-open"
        enabled: root.filePath !== ""
        onTriggered: root.openFile()
    }

    PlasmaCore.Action {
        id: aboutAction
        text: i18n("About Todo Task")
        icon.name: "help-about"
        onTriggered: {
            root.showAbout = true;
            root.expanded = true;
        }
    }

    compactRepresentation: CompactRepresentation { widget: root }
    fullRepresentation: FullRepresentation { widget: root }

    ListModel { id: todayModel }
    ListModel { id: queueModel }
    ListModel { id: dailyModel }
    ListModel { id: doneModel }

    // Work days for the Daily tasks, as Date.getDay() numbers
    function dailyDays() {
        return String(Plasmoid.configuration.dailyDays).split(",")
            .filter(day => day.trim() !== "").map(day => Number(day));
    }

    function today() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    // ---- shell ---------------------------------------------------------

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        property var callbacks: ({})

        onNewData: (sourceName, data) => {
            const callback = callbacks[sourceName];
            delete callbacks[sourceName];
            disconnectSource(sourceName);
            if (callback) {
                callback(data["stdout"] || "", data["stderr"] || "", data["exit code"]);
            }
        }
    }

    function exec(command, callback) {
        if (executable.callbacks[command]) {
            return false;
        }
        executable.callbacks[command] = callback;
        executable.connectSource(command);
        return true;
    }

    // ---- file ----------------------------------------------------------

    // announce: say in the toast that the file was read again (Reload button)
    function load(announce) {
        if (filePath === "" || writing) {
            return;
        }
        const asked = filePath;
        exec(Store.readCommand(asked), (output, stderr, exitCode) => {
            if (filePath !== asked) {
                // Another workspace was opened while this one was being read
                return;
            }
            const cut = output.indexOf("\n");
            if (exitCode !== 0 || cut === -1) {
                // Never continue with an empty list here: the next save would wipe the file.
                errorText = stderr.trim() || i18n("Could not read %1", filePath);
                return;
            }
            errorText = "";
            // The first line is the file in use: a folder setting becomes todo.md in it
            filePath = output.slice(0, cut);
            const stdout = output.slice(cut + 1);
            const missing = stdout === Store.MISSING;
            const fresh = missing ? Store.emptyDoc(today()) : Store.parse(stdout, today());
            adoptUids(doc, fresh);
            doc = fresh;
            loaded = true;
            const changed = Tasks.normalize(doc, today(), Plasmoid.configuration.carryOver, dailyDays());
            Tasks.tidy(doc);
            refresh();
            if (missing || changed) {
                save();
            }
            archiveOld();
            if (announce === true) {
                undoSnapshot = "";
                noticeList = "";
                noticeText = i18n("Reloaded from %1", filePath.split("/").pop());
                undoTimer.restart();
            }
        });
    }

    function save() {
        if (!doc || filePath === "") {
            return;
        }
        if (writing) {
            writeQueued = true;
            return;
        }
        writing = true;
        runAll(Store.writeCommands(filePath, Store.serialize(doc), false, ""), (ok, message) => {
            writing = false;
            errorText = ok ? "" : (message || i18n("Could not write %1", filePath));
            if (writeQueued) {
                writeQueued = false;
                save();
            }
            // A switch to another file waited for this write to end
            if (!doc && !loaded) {
                load();
            }
        });
    }

    // Runs shell commands one after another; stops at the first failure.
    function runAll(commands, done) {
        let i = 0;
        const next = () => {
            if (i >= commands.length) {
                done(true, "");
                return;
            }
            const started = exec(commands[i], (stdout, stderr, exitCode) => {
                if (exitCode !== 0) {
                    done(false, stderr.trim());
                    return;
                }
                i++;
                next();
            });
            if (!started) {
                done(false, "");
            }
        };
        next();
    }

    // Moves finished days older than the configured age into monthly archive
    // files (todo-archive-2026-10.md). A day is removed from todo.md only after
    // it has been appended to its archive, so an interruption can at worst
    // leave it in both files, never in neither.
    function archiveOld() {
        const days = Plasmoid.configuration.archiveDays;
        if (!doc || archiving || undoSnapshot !== "" || days <= 0) {
            return;
        }
        const months = Tasks.oldDone(doc, today(), days);
        if (months.length === 0) {
            return;
        }
        archiving = true;
        let m = 0;
        const nextMonth = () => {
            if (m >= months.length) {
                archiving = false;
                return;
            }
            const batch = months[m];
            const path = Store.archivePath(filePath, batch.month);
            const header = "# To-do archive " + batch.month;
            runAll(Store.writeCommands(path, Store.archiveText(batch.groups), true, header), (ok) => {
                if (!ok) {
                    archiving = false; // leave everything in todo.md and try again next time
                    return;
                }
                Tasks.dropDone(doc, batch.groups.map(g => g.date));
                save();
                m++;
                nextMonth();
            });
        };
        nextMonth();
    }

    function openFile() {
        exec(Store.openCommand(filePath), () => {});
    }

    // ---- models --------------------------------------------------------

    function refresh() {
        const now = today();
        todayTotal = doc.today.length;
        todayCount = Tasks.activeCount(doc.today);
        todayWaiting = todayTotal - todayCount;
        queueTotal = doc.queue.length;
        queueCount = Tasks.activeCount(doc.queue);
        dailyCount = doc.daily.length;
        groupNames = doc.groups.slice();
        groupCounts = Tasks.groupCounts(doc);
        if (addGroup !== "" && doc.groups.indexOf(addGroup) === -1) {
            addGroup = "";
        }
        sync(todayModel, doc.today, task => ({
            uid: uidOf(task),
            taskText: task.text,
            carried: !task.daily && task.since !== "" && task.since < now,
            daily: !!task.daily,
            waiting: !!task.waiting,
            group: task.group || "",
            subsJson: JSON.stringify(task.subs),
            subDone: Tasks.subDone(task),
            subTotal: task.subs.length
        }));
        const plainRow = task => ({
            uid: uidOf(task),
            taskText: task.text,
            carried: false,
            daily: false,
            waiting: !!task.waiting,
            group: task.group || "",
            subsJson: JSON.stringify(task.subs),
            subDone: Tasks.subDone(task),
            subTotal: task.subs.length
        });
        sync(queueModel, doc.queue, plainRow);
        sync(dailyModel, doc.daily, plainRow);
        const done = Tasks.doneToday(doc, now);
        doneCount = done.length;
        sync(doneModel, done, task => ({ uid: uidOf(task), taskText: task.text }));
    }

    // Runtime-only id, so a dragged row can be matched back to its task.
    function uidOf(task) {
        if (!task.uid) {
            task.uid = nextUid++;
        }
        return task.uid;
    }

    // Brings a ListModel in line with a list, row by row (matched by uid), so the
    // views animate exactly the rows that were added, removed or moved.
    function sync(model, list, toRow) {
        const wanted = {};
        list.forEach(task => { wanted[uidOf(task)] = true; });
        for (let i = model.count - 1; i >= 0; i--) {
            if (!wanted[model.get(i).uid]) {
                model.remove(i);
            }
        }
        for (let i = 0; i < list.length; i++) {
            const row = toRow(list[i]);
            let at = -1;
            for (let j = i; j < model.count; j++) {
                if (model.get(j).uid === row.uid) {
                    at = j;
                    break;
                }
            }
            if (at !== -1 && row.group !== undefined && model.get(at).group !== row.group) {
                // Changed group: take the row out and put it back, so the list
                // redraws the group headings around it
                model.remove(at);
                at = -1;
            }
            if (at === -1) {
                model.insert(i, row);
            } else {
                if (at !== i) {
                    model.move(at, i, 1);
                }
                model.set(i, row);
            }
        }
    }

    // A re-read or undo gives new task objects; those with the same text in the
    // same list keep their uid, so their rows stay put instead of re-animating.
    function adoptUids(oldDoc, newDoc) {
        if (!oldDoc) {
            return;
        }
        const now = today();
        const pairs = [[oldDoc.today, newDoc.today], [oldDoc.queue, newDoc.queue], [oldDoc.daily, newDoc.daily],
                       [Tasks.doneToday(oldDoc, now), Tasks.doneToday(newDoc, now)]];
        pairs.forEach(pair => {
            const pool = pair[0].filter(task => task.uid);
            pair[1].forEach(task => {
                const i = pool.findIndex(old => old.text === task.text);
                if (i !== -1) {
                    task.uid = pool[i].uid;
                    pool.splice(i, 1);
                }
            });
        });
    }

    // ---- clipboard -----------------------------------------------------

    Clipboard {
        id: clipboard
    }

    Timer {
        id: flashTimer
        interval: 2000
        onTriggered: root.flashText = ""
    }

    function toClipboard(text, flash) {
        if (text === "") {
            return;
        }
        clipboard.put(text);
        flashText = flash;
        flashTimer.restart();
    }

    function copyTask(listName, index) {
        const task = doc ? doc[listName][index] : null;
        if (task) {
            toClipboard(Store.copyText(task), i18n("Copied: %1", task.text));
        }
    }

    function copySub(listName, index, subIndex) {
        const task = doc ? doc[listName][index] : null;
        const sub = task ? task.subs[subIndex] : null;
        if (sub) {
            toClipboard(sub.text, i18n("Copied: %1", sub.text));
        }
    }

    function copyAll(listName) {
        const list = doc ? doc[listName] : [];
        if (list.length > 0) {
            toClipboard(Store.copyList(list), i18np("Copied %1 task", "Copied %1 tasks", list.length));
        }
    }

    // ---- changes -------------------------------------------------------

    // Every edit goes through here: mutate, redraw, write.
    // With a notice the change can be undone from the toast for 5 seconds.
    function change(mutate, notice, noticeTarget) {
        if (!doc) {
            return;
        }
        const before = notice ? Store.serialize(doc) : "";
        mutate(doc);
        Tasks.tidy(doc);
        if (notice) {
            undoSnapshot = before;
            noticeText = notice;
            noticeList = noticeTarget || "";
            undoTimer.restart();
        }
        refresh();
        save();
    }

    function undo() {
        if (undoSnapshot === "") {
            return;
        }
        const restored = Store.parse(undoSnapshot, today());
        adoptUids(doc, restored);
        doc = restored;
        undoSnapshot = "";
        noticeText = "";
        undoTimer.stop();
        refresh();
        save();
    }

    Timer {
        id: undoTimer
        interval: 5000
        onTriggered: {
            root.undoSnapshot = "";
            root.noticeText = "";
        }
    }

    // Enter adds to the configured list, Shift+Enter to the other one.
    function addTask(text, toOtherList) {
        let target = Plasmoid.configuration.newTaskTarget === "today" ? "today" : "queue";
        if (toOtherList) {
            target = Tasks.otherList(target);
        }
        const name = (text || "").trim();
        if (!doc || name === "") {
            return;
        }
        if (addGroup !== "") {
            const group = addGroup;
            change(d => Tasks.add(d, "queue", name, today(), group), i18n("Added to %1: %2", group, name), "queue");
            return;
        }
        change(d => Tasks.add(d, target, name, today()),
               target === "today" ? i18n("Added to Today: %1", name) : i18n("Added to Queue: %1", name),
               target);
    }

    function completeTask(index) {
        const name = doc.today[index] ? doc.today[index].text : "";
        change(d => Tasks.complete(d, index, today()), i18n("Completed: %1", name));
    }

    function uncompleteTask(index) {
        change(d => Tasks.uncomplete(d, index, today()));
    }

    function moveTask(listName, index) {
        change(d => Tasks.move(d, listName, index, today()));
    }

    function makeDaily(listName, index) {
        const name = doc[listName][index] ? doc[listName][index].text : "";
        change(d => Tasks.makeDaily(d, listName, index, today()), i18n("Repeats every work day: %1", name));
    }

    function stopDaily(index) {
        const name = doc.today[index] ? doc.today[index].text : "";
        change(d => Tasks.stopDaily(d, index), i18n("Stopped repeating: %1", name));
    }

    // ---- Queue groups

    function setGroup(listName, index, group) {
        const name = doc[listName][index] ? doc[listName][index].text : "";
        change(d => Tasks.setGroup(d, listName, index, group),
               group ? i18n("Moved to %1: %2", group, name) : i18n("Removed from group: %1", name), "queue");
    }

    // The renamed group opens, so its tasks are in view right away
    function renameGroup(from, to) {
        change(d => Tasks.renameGroup(d, from, to));
        setFolded(foldedGroups.filter(n => n !== from && n !== to.trim()));
    }

    function removeGroup(name) {
        change(d => Tasks.removeGroup(d, name), i18n("Removed group %1", name));
    }

    function moveGroup(name, delta) {
        change(d => Tasks.moveGroup(d, name, delta));
    }

    // The input adds to this group until Esc or the popup closes
    function startAddToGroup(name) {
        addGroup = name;
        foldGroup(name, false);
        if (queueCollapsed) {
            setQueueCollapsed(false);
        }
        inputRequested();
    }

    function groupFolded(name) {
        return foldedGroups.indexOf(name) !== -1;
    }

    function foldGroup(name, folded) {
        const list = foldedGroups.filter(n => n !== name);
        if (folded) {
            list.push(name);
        }
        setFolded(list);
    }

    function setWaiting(listName, index, on) {
        const name = doc[listName][index] ? doc[listName][index].text : "";
        change(d => Tasks.setWaiting(d, listName, index, on),
               on ? i18n("Waiting: %1", name) : i18n("Back to work: %1", name));
    }

    function moveToEdge(listName, index, toTop) {
        change(d => Tasks.moveToEdge(d, listName, index, toTop));
    }

    function removeTask(listName, index) {
        const name = doc[listName][index] ? doc[listName][index].text : "";
        change(d => Tasks.remove(d, listName, index), i18n("Deleted: %1", name));
    }

    function editTask(listName, index, text) {
        change(d => Tasks.edit(d, listName, index, text));
    }

    function pullNext() {
        change(d => Tasks.pullNext(d, today()));
    }

    function addSub(listName, index, text) {
        change(d => Tasks.addSub(d, listName, index, text));
    }

    function toggleSub(listName, index, subIndex) {
        change(d => Tasks.toggleSub(d, listName, index, subIndex));
    }

    function editSub(listName, index, subIndex, text) {
        change(d => Tasks.editSub(d, listName, index, subIndex, text));
    }

    function promoteSub(listName, index, subIndex) {
        const sub = doc[listName][index] ? doc[listName][index].subs[subIndex] : null;
        change(d => Tasks.promoteSub(d, listName, index, subIndex, today()),
               i18n("Made a task: %1", sub ? sub.text : ""));
    }

    function moveSub(listName, index, subIndex, delta) {
        change(d => Tasks.moveSub(d, listName, index, subIndex, delta));
    }

    function removeSub(listName, index, subIndex) {
        const sub = doc[listName][index] ? doc[listName][index].subs[subIndex] : null;
        change(d => Tasks.removeSub(d, listName, index, subIndex),
               i18n("Deleted: %1", sub ? sub.text : ""));
    }

    // Called after a drag: the ListModel already has the new order, copy it to the doc.
    function commitOrder(listName) {
        const model = { today: todayModel, queue: queueModel, daily: dailyModel }[listName];
        const byUid = {};
        doc[listName].forEach(task => { byUid[task.uid] = task; });
        const ordered = [];
        for (let i = 0; i < model.count; i++) {
            const task = byUid[model.get(i).uid];
            if (task) {
                ordered.push(task);
            }
        }
        if (ordered.length === doc[listName].length) {
            doc[listName] = ordered;
            // Same rules as every other change (waiting tasks stay last), so
            // the list shows the order that is saved
            Tasks.tidy(doc);
            refresh();
            save();
        } else {
            refresh();
        }
    }

    // ---- lifecycle -----------------------------------------------------

    Component.onCompleted: {
        exec(Store.folderCommand(), (stdout) => {
            const lines = stdout.split("\n");
            homeFolder = lines[0].trim();
            documentsFolder = (lines[1] || lines[0]).trim();
            defaultPath = (lines[2] || "").trim();
            pathsReady = true;
        });
    }

    // Another workspace or path was chosen: drop everything that belongs to
    // the old file first, so none of it can be written to the new one, then
    // read the new one. A write still running to the old file finishes first
    // (save() loads the new file when it is done).
    function openTarget() {
        if (targetPath === "" || targetPath === openedTarget) {
            return;
        }
        openedTarget = targetPath;
        doc = null;
        loaded = false;
        errorText = "";
        undoSnapshot = "";
        noticeText = "";
        addGroup = "";
        flashText = "";
        writeQueued = false;
        [todayModel, queueModel, dailyModel, doneModel].forEach(model => model.clear());
        todayCount = todayTotal = todayWaiting = 0;
        queueCount = queueTotal = dailyCount = doneCount = 0;
        filePath = targetPath;
        load();
    }

    function switchWorkspace(index) {
        if (index >= 0 && index < workspaces.length && index !== activeIndex) {
            Plasmoid.configuration.activeWorkspace = workspaces[index].name;
        }
    }

    // Fold state of the active workspace. One write per change, and only
    // names of groups that still exist
    function setFolded(list) {
        const names = doc ? doc.groups : groupNames;
        list = list.filter(n => names.indexOf(n) !== -1);
        if (activeIndex === 0) {
            Plasmoid.configuration.foldedGroups = JSON.stringify(list);
            return;
        }
        const all = Object.assign({}, workspaceFolds);
        all[activeName] = Object.assign({}, all[activeName], { groups: list });
        Plasmoid.configuration.workspaceFolds = JSON.stringify(all);
    }

    function setQueueCollapsed(collapsed) {
        if (activeIndex === 0) {
            Plasmoid.configuration.queueCollapsed = collapsed;
            return;
        }
        const all = Object.assign({}, workspaceFolds);
        all[activeName] = Object.assign({}, all[activeName], { queue: collapsed });
        Plasmoid.configuration.workspaceFolds = JSON.stringify(all);
    }

    function setDailyCollapsed(collapsed) {
        if (activeIndex === 0) {
            Plasmoid.configuration.dailyCollapsed = collapsed;
            return;
        }
        const all = Object.assign({}, workspaceFolds);
        all[activeName] = Object.assign({}, all[activeName], { daily: collapsed });
        Plasmoid.configuration.workspaceFolds = JSON.stringify(all);
    }

    // Picks up edits made in another editor. While a folder setting is being
    // looked up (the first read), a click must not read it as a file.
    onExpandedChanged: {
        if (root.expanded) {
            if (loaded) {
                load();
            }
        } else {
            showAbout = false;
            workspaceMenuWanted = false;
            addGroup = "";
        }
    }

    // New day check
    Timer {
        interval: 60000
        running: root.loaded
        repeat: true
        onTriggered: {
            if (root.doc && Tasks.normalize(root.doc, root.today(), Plasmoid.configuration.carryOver, root.dailyDays())) {
                root.refresh();
                root.save();
                root.archiveOld();
            }
        }
    }
}
