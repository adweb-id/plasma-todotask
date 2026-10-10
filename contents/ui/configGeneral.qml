import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import QtQuick.Dialogs as Dialogs
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_filePath
    property string cfg_workspaces
    property string cfg_newTaskTarget
    property alias cfg_popupWidth: widthSpin.value
    property alias cfg_carryOver: carryCheck.checked
    property alias cfg_archiveDays: archiveSpin.value
    property string cfg_dailyDays
    // The workspace rows being edited. One row is stored the old way, as
    // cfg_filePath; two or more are stored as a JSON list in cfg_workspaces.
    ListModel {
        id: wsModel
    }
    property bool wsReady: false

    Component.onCompleted: {
        let list = [];
        try {
            list = JSON.parse(cfg_workspaces || "[]");
        } catch (e) {
            list = [];
        }
        if (!Array.isArray(list) || list.length === 0) {
            list = [{ name: "", path: cfg_filePath }];
        }
        list.forEach(w => wsModel.append({ name: String(w.name || ""), path: String(w.path || "") }));
        wsReady = true;
        wsCheck();
    }

    // Per row: the name of an earlier workspace that uses the same file, or "".
    // Paths are compared the way the widget reads them: "~/Sync", "~/Sync/"
    // and "~/Sync/todo.md" are one file, and so are "kerja.md" and
    // "~/Documents/kerja.md" (taking Documents at its usual place).
    property var wsClash: []

    function wsFileKey(path) {
        let p = path.trim().replace(/^file:\/\//, "");
        if (p === "") {
            return "";
        }
        if (p !== "~" && p.indexOf("~/") !== 0 && p.charAt(0) !== "/") {
            p = "~/Documents/" + p;
        }
        p = p.replace(/\/{2,}/g, "/");
        const isDir = p.length > 1 && p.charAt(p.length - 1) === "/";
        if (isDir) {
            p = p.slice(0, -1);
        }
        const last = p.slice(p.lastIndexOf("/") + 1);
        return isDir || last.lastIndexOf(".") <= 0 ? p + "/todo.md" : p;
    }

    function wsCheck() {
        const seen = {};
        const clash = [];
        for (let i = 0; i < wsModel.count; i++) {
            const key = wsFileKey(wsModel.get(i).path);
            const name = wsModel.get(i).name.trim() || i18n("Workspace %1", i + 1);
            clash.push(seen[key] !== undefined ? seen[key] : "");
            if (seen[key] === undefined) {
                seen[key] = name;
            }
        }
        wsClash = clash;
    }

    function wsCommit() {
        if (!wsReady) {
            return;
        }
        wsCheck();
        const rows = [];
        for (let i = 0; i < wsModel.count; i++) {
            rows.push({ name: wsModel.get(i).name.trim(), path: wsModel.get(i).path.trim() });
        }
        if (rows.length <= 1) {
            cfg_filePath = rows.length === 1 ? rows[0].path : "";
            cfg_workspaces = "[]";
            return;
        }
        const used = {};
        rows.forEach((r, i) => {
            let name = r.name !== "" ? r.name : i18n("Workspace %1", i + 1);
            while (used[name]) {
                name += " 2";
            }
            used[name] = true;
            r.name = name;
        });
        cfg_filePath = rows[0].path;
        cfg_workspaces = JSON.stringify(rows);
    }

    function localPath(url) {
        return decodeURIComponent(url.toString().replace(/^file:\/\//, ""));
    }

    Kirigami.FormLayout {
        // Where the tasks are kept. Each row is a workspace; with one row the name is not needed.
        ColumnLayout {
            Kirigami.FormData.label: wsModel.count > 1 ? i18n("Workspaces:") : i18n("Task file:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: wsModel

                ColumnLayout {
                    id: wsRow

                    required property int index
                    required property string name
                    required property string path
                    readonly property string clash: wsClash[index] || ""

                    Layout.fillWidth: true
                    spacing: 0

                RowLayout {

                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TextField {
                        visible: wsModel.count > 1
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                        placeholderText: i18n("Name")
                        text: wsRow.name
                        onTextEdited: {
                            wsModel.setProperty(wsRow.index, "name", text);
                            wsCommit();
                        }
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
                        placeholderText: i18n("~/Documents/todotask/todo.md")
                        text: wsRow.path
                        onTextEdited: {
                            wsModel.setProperty(wsRow.index, "path", text);
                            wsCommit();
                        }
                    }

                    QQC2.Button {
                        icon.name: "text-markdown"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Choose a file…")
                        onClicked: {
                            fileDialog.row = wsRow.index;
                            fileDialog.open();
                        }
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.Button {
                        icon.name: "folder-open"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Choose a folder…")
                        onClicked: {
                            folderDialog.row = wsRow.index;
                            folderDialog.open();
                        }
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    QQC2.Button {
                        visible: wsModel.count > 1
                        icon.name: "list-remove"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Remove this workspace")
                        onClicked: {
                            removeDialog.row = wsRow.index;
                            removeDialog.name = wsRow.name.trim() || i18n("Workspace %1", wsRow.index + 1);
                            removeDialog.open();
                        }
                        QQC2.ToolTip.text: i18n("Remove this workspace (its file is kept)")
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }

                    QQC2.Label {
                        visible: wsRow.clash !== ""
                        text: i18n("Same file as %1: both show the same tasks", wsRow.clash)
                        color: Kirigami.Theme.neutralTextColor
                        font: Kirigami.Theme.smallFont
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            QQC2.Button {
                icon.name: "list-add"
                text: i18n("Add workspace")
                onClicked: {
                    wsModel.append({ name: "", path: "" });
                    wsCommit();
                }
            }
        }

        QQC2.Label {
            text: i18n("A path is a Markdown file, or a folder (the file is then todo.md in it). Empty means Documents/todotask/todo.md, or Documents/todo.md if that file was already there. Files and folders are created when needed; nothing is moved or deleted when you change this.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        }

        Kirigami.PromptDialog {
            id: removeDialog
            property int row: -1
            property string name: ""
            title: i18n("Remove workspace?")
            subtitle: i18n("\"%1\" is taken off the list. Its file and tasks are kept on disk.", name)
            standardButtons: Kirigami.Dialog.Cancel
            customFooterActions: [
                Kirigami.Action {
                    text: i18n("Remove")
                    icon.name: "list-remove"
                    onTriggered: {
                        if (removeDialog.row >= 0 && removeDialog.row < wsModel.count) {
                            wsModel.remove(removeDialog.row);
                            wsCommit();
                        }
                        removeDialog.close();
                    }
                }
            ]
        }

        Dialogs.FileDialog {
            id: fileDialog
            property int row: 0
            title: i18n("Choose the task file")
            fileMode: Dialogs.FileDialog.SaveFile
            options: Dialogs.FileDialog.DontConfirmOverwrite
            nameFilters: [i18n("Markdown files (*.md)"), i18n("All files (*)")]
            defaultSuffix: "md"
            onAccepted: {
                wsModel.setProperty(row, "path", localPath(selectedFile));
                wsCommit();
            }
        }

        Dialogs.FolderDialog {
            id: folderDialog
            property int row: 0
            title: i18n("Choose the folder for todo.md")
            onAccepted: {
                wsModel.setProperty(row, "path", localPath(selectedFolder));
                wsCommit();
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: targetCombo
            Kirigami.FormData.label: i18n("Enter adds a task to:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Queue (Shift+Enter adds to Today)"), value: "queue" },
                { text: i18n("Today (Shift+Enter adds to Queue)"), value: "today" }
            ]
            onActivated: cfg_newTaskTarget = currentValue
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_newTaskTarget))
        }

        QQC2.SpinBox {
            id: widthSpin
            Kirigami.FormData.label: i18n("Popup width (pixels):")
            from: 300
            to: 800
            stepSize: 20
        }

        QQC2.CheckBox {
            id: carryCheck
            Kirigami.FormData.label: i18n("New day:")
            text: i18n("Keep unfinished tasks in Today")
        }

        // Work days for the Daily tasks, Monday first; stored as Date.getDay() numbers
        RowLayout {
            Kirigami.FormData.label: i18n("Daily tasks on:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [1, 2, 3, 4, 5, 6, 0]

                QQC2.CheckBox {
                    required property int modelData
                    text: Qt.locale().dayName(modelData, Locale.ShortFormat)
                    checked: cfg_dailyDays.split(",").indexOf(String(modelData)) !== -1
                    onToggled: {
                        const days = cfg_dailyDays.split(",").filter(d => d !== "" && d !== String(modelData));
                        if (checked) {
                            days.push(String(modelData));
                        }
                        cfg_dailyDays = days.sort().join(",");
                    }
                }
            }
        }

        QQC2.SpinBox {
            id: archiveSpin
            Kirigami.FormData.label: i18n("Archive finished tasks after (days):")
            from: 0
            to: 365
        }

        QQC2.Label {
            text: i18n("Older finished tasks move to a monthly archive file next to the task file (todo-archive-YYYY-MM.md). 0 keeps everything in the task file.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
