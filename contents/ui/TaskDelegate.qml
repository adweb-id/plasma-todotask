import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "tasks.js" as Tasks

// One task with its subtasks. listName is "today", "queue" or "daily" (the template).
Item {
    id: row

    required property var widget
    required property string listName
    required property ListView listView

    // Roles from the ListModel (see refresh() in main.qml)
    required property int index
    required property string taskText
    required property bool carried
    required property bool daily
    required property string group
    required property bool waiting
    required property string subsJson
    required property int subDone
    required property int subTotal

    readonly property bool isToday: listName === "today"
    readonly property bool isTemplate: listName === "daily"
    readonly property var subs: JSON.parse(subsJson)

    property bool editing: false
    property int editingSub: -1
    property bool addingSub: false
    // Delete waiting for confirmation: -2 nothing, -1 the task, 0.. a subtask
    property int confirmDelete: -2
    property string confirmText: ""
    // Ticked: the tick and the strike play before the task leaves the list
    property bool completing: false
    property bool dragging: false
    property point groupPickerAt: Qt.point(0, 0)

    readonly property bool showTools: (hover.hovered || dragging || taskMenu.opened) && !editing && !completing
    readonly property color barColor: Qt.tint(Kirigami.Theme.backgroundColor, alpha(Kirigami.Theme.textColor, 0.06))
    readonly property int checkSize: Math.round(Kirigami.Units.gridUnit * 1.05)
    // A Queue row folds away with its group
    readonly property bool folded: listName === "queue" && group !== "" && widget.foldedGroups.indexOf(group) !== -1
    property real openness: folded ? 0 : 1

    Behavior on openness {
        NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // The theme's small font with some changes. Its size is copied as points
    // or pixels, whichever the theme uses (the other one is -1).
    function smallFont(changes) {
        const f = Kirigami.Theme.smallFont;
        const spec = Object.assign({ family: f.family }, changes);
        if (f.pointSize > 0) {
            spec.pointSize = f.pointSize;
        } else {
            spec.pixelSize = f.pixelSize;
        }
        return Qt.font(spec);
    }

    function startEdit() {
        editing = true;
        editField.text = taskText;
        editField.forceActiveFocus();
    }

    function startAddSub() {
        addingSub = true;
        subField.forceActiveFocus();
    }

    function askDelete(subIndex) {
        if (subIndex === -1) {
            confirmText = subTotal > 0 ? i18np("Delete this task and its subtask?", "Delete this task and its %1 subtasks?", subTotal)
                                       : i18n("Delete this task?");
        } else {
            confirmText = i18n("Delete this subtask?");
        }
        confirmDelete = subIndex;
        confirmTimer.restart();
    }

    function confirmedDelete() {
        const subIndex = confirmDelete;
        confirmDelete = -2;
        confirmTimer.stop();
        if (subIndex === -1) {
            widget.removeTask(listName, index);
        } else if (subIndex >= 0) {
            widget.removeSub(listName, index, subIndex);
        }
    }

    function complete() {
        if (!completing) {
            completing = true;
            completeTimer.start();
        }
    }

    // First row of its Queue group (re-checked whenever the rows change)
    readonly property bool groupStart: {
        if (listName !== "queue" || group === "" || widget.groupCounts === undefined) {
            return false;
        }
        // While a row is being removed the one above may already be gone
        const above = index > 0 && index - 1 < listView.model.count ? listView.model.get(index - 1) : null;
        return !above || above.group !== group;
    }

    width: ListView.view ? ListView.view.width : implicitWidth
    implicitHeight: (headingLoader.active ? headingLoader.height : 0) + body.height
    z: dragging ? 10 : 0

    // Gives up on its own, like an unanswered question
    Timer {
        id: confirmTimer
        interval: 6000
        onTriggered: row.confirmDelete = -2
    }

    // Lets the tick and the strike finish before the row leaves
    Timer {
        id: completeTimer
        interval: Kirigami.Units.longDuration * 2 + Kirigami.Units.shortDuration
        onTriggered: row.widget.completeTask(row.index)
    }

    // The first Queue row of a group carries the group's heading. (The list's
    // own section headings are not used: Qt reuses them for other groups
    // without updating the name, which showed a renamed group under its old name.)
    Loader {
        id: headingLoader
        width: parent.width
        active: row.groupStart
        visible: active
        sourceComponent: GroupHeading {
            section: row.group
            widget: row.widget
        }
    }

    // The task itself; folds away with its group, the heading stays
    Item {
        id: body
        y: headingLoader.active ? headingLoader.height : 0
        width: parent.width
        height: (column.implicitHeight + Kirigami.Units.smallSpacing * 2) * row.openness
        opacity: row.openness
        clip: row.openness < 1
        visible: height > 0

        HoverHandler {
            id: hover
        }

        // Rounded tint while hovered, lifted with a shadow while dragged
        Kirigami.ShadowedRectangle {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            radius: Kirigami.Units.cornerRadius * 2
            color: row.dragging ? Qt.tint(Kirigami.Theme.backgroundColor, row.alpha(Kirigami.Theme.textColor, 0.1))
                 : row.showTools ? row.barColor : row.alpha(row.barColor, 0)
            shadow.size: row.dragging ? Kirigami.Units.gridUnit : 0
            shadow.yOffset: 2
            shadow.color: Qt.rgba(0, 0, 0, 0.35)

            Behavior on color {
                ColorAnimation { duration: Kirigami.Units.shortDuration }
            }
        }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing * 2
            spacing: 0

            // ---- the task itself
            RowLayout {
                id: taskLine
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                TaskCheck {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: row.isToday
                    on: row.completing
                    onClicked: row.complete()
                    Accessible.name: i18n("Complete %1", row.taskText)
                }

                // Rows without a check box get a marker in the same column, so a
                // long text wraps under itself and never looks like a second task.
                Item {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: !row.isToday
                    implicitWidth: row.checkSize
                    implicitHeight: row.checkSize

                    Rectangle {
                        anchors.centerIn: parent
                        visible: !row.isTemplate
                        width: Math.round(row.checkSize * 0.32)
                        height: width
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: row.waiting ? 0.25 : 0.45
                    }

                    Glyph {
                        anchors.centerIn: parent
                        visible: row.isTemplate
                        implicitWidth: Math.round(row.checkSize * 0.8)
                        implicitHeight: implicitWidth
                        name: "repeat"
                        opacity: 0.5
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: taskLabel.implicitHeight
                    visible: !row.editing

                    FontMetrics {
                        id: metrics
                        font: taskLabel.font
                    }

                    PlasmaComponents3.Label {
                        id: taskLabel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        text: Tasks.styled(row.taskText)
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        // Waiting tasks step back so the ones to work on stand out
                        opacity: row.completing ? 0.5 : row.waiting ? 0.55 : 1

                        Behavior on opacity {
                            NumberAnimation { duration: Kirigami.Units.longDuration }
                        }

                        TapHandler {
                            onDoubleTapped: row.startEdit()
                        }
                    }

                    // Strikes through the first line, left to right, when ticked
                    Rectangle {
                        x: 0
                        y: Math.round(metrics.height / 2)
                        height: 1.5
                        width: row.completing ? Math.min(taskLabel.contentWidth, taskLabel.width) : 0
                        color: Kirigami.Theme.textColor
                        opacity: 0.7

                        Behavior on width {
                            NumberAnimation { duration: Kirigami.Units.longDuration * 1.3; easing.type: Easing.OutCubic }
                        }
                    }

                    // Hover-only tools float over the end of the text, so nothing moves.
                    Rectangle {
                        id: tools
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Math.round((metrics.height - height) / 2)
                        width: toolRow.implicitWidth
                        height: toolRow.implicitHeight
                        color: row.barColor
                        opacity: row.showTools ? 1 : 0
                        visible: opacity > 0

                        transform: Translate {
                            x: row.showTools ? 0 : Kirigami.Units.smallSpacing
                            Behavior on x {
                                NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: Kirigami.Units.shortDuration }
                        }

                        // Fades the text out under the buttons
                        Rectangle {
                            anchors.right: parent.left
                            width: Kirigami.Units.gridUnit
                            height: parent.height
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: row.alpha(row.barColor, 0) }
                                GradientStop { position: 1; color: row.barColor }
                            }
                        }

                        RowLayout {
                            id: toolRow
                            spacing: 0

                            // Drag to reorder within the list
                            MouseArea {
                                implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.3)
                                implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                preventStealing: true

                                Glyph {
                                    anchors.centerIn: parent
                                    name: "grip"
                                    opacity: 0.7
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed) {
                                        return;
                                    }
                                    row.dragging = true;
                                    const list = row.listView;
                                    const p = mapToItem(list.contentItem, mouse.x, mouse.y);
                                    let to = list.indexAt(list.width / 2, p.y);
                                    // Above the first row or below the last one: the ends of the list
                                    if (to < 0) {
                                        to = p.y < 0 ? 0 : list.count - 1;
                                    }
                                    // In the Queue a task stays in its group (↑ ↓ and the menu move
                                    // it elsewhere); in Today the group is only a label
                                    const sameGroup = row.listName !== "queue" || list.model.get(to).group === row.group;
                                    if (to !== row.index && sameGroup) {
                                        list.model.move(row.index, to, 1);
                                    }
                                }
                                onReleased: {
                                    if (row.dragging) {
                                        row.dragging = false;
                                        row.widget.commitOrder(row.listName);
                                    }
                                }
                                onCanceled: {
                                    if (row.dragging) {
                                        row.dragging = false;
                                        row.widget.commitOrder(row.listName);
                                    }
                                }

                                Accessible.name: i18n("Drag to reorder")
                            }

                            IconButton {
                                visible: !row.isTemplate
                                iconName: row.isToday ? "down" : "up"
                                tip: row.isToday ? i18n("Move to Queue") : i18n("Move to Today")
                                onClicked: row.widget.moveTask(row.listName, row.index)
                            }

                            // Used often enough to be one click away
                            IconButton {
                                iconName: "plus"
                                tip: i18n("Add subtask")
                                onClicked: row.startAddSub()
                            }

                            IconButton {
                                id: moreButton
                                iconName: "more"
                                tip: i18n("More")
                                onClicked: taskMenu.openAt(row, moreButton.mapToItem(row, moreButton.width, moreButton.height))
                            }
                        }
                    }
                }

                // Editing shows the raw text, markdown included
                PlasmaComponents3.TextField {
                    id: editField
                    Layout.fillWidth: true
                    visible: row.editing
                    onAccepted: {
                        row.editing = false;
                        row.widget.editTask(row.listName, row.index, text);
                    }
                    Keys.onEscapePressed: event => {
                        row.editing = false;
                        event.accepted = true;
                    }
                }

                // Subtask progress, e.g. 1/3
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: row.subTotal > 0
                    implicitWidth: progressLabel.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: progressLabel.implicitHeight + 2
                    radius: height / 2
                    color: row.subDone === row.subTotal ? row.alpha(Kirigami.Theme.positiveTextColor, 0.18)
                                                       : row.alpha(Kirigami.Theme.textColor, 0.08)

                    PlasmaComponents3.Label {
                        id: progressLabel
                        anchors.centerIn: parent
                        text: i18nc("finished subtasks / all subtasks", "%1/%2", row.subDone, row.subTotal)
                        font: Kirigami.Theme.smallFont
                        color: row.subDone === row.subTotal ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                        opacity: 0.85
                    }
                }

                // On hold
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: row.waiting
                    implicitWidth: waitingRow.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: waitingRow.implicitHeight + 2
                    radius: height / 2
                    color: row.alpha(Kirigami.Theme.neutralTextColor, 0.16)

                    RowLayout {
                        id: waitingRow
                        anchors.centerIn: parent
                        spacing: 3

                        Glyph {
                            implicitWidth: Math.round(Kirigami.Units.iconSizes.small * 0.75)
                            implicitHeight: implicitWidth
                            name: "pause"
                            color: Kirigami.Theme.neutralTextColor
                        }

                        PlasmaComponents3.Label {
                            text: i18n("waiting")
                            font: Kirigami.Theme.smallFont
                            color: Kirigami.Theme.neutralTextColor
                        }
                    }
                }

                // The Queue group this task came from
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    Layout.maximumWidth: Kirigami.Units.gridUnit * 6
                    visible: row.isToday && row.group !== ""
                    implicitWidth: groupLabel.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: groupLabel.implicitHeight + 2
                    radius: height / 2
                    color: row.alpha(Kirigami.Theme.highlightColor, 0.16)

                    PlasmaComponents3.Label {
                        id: groupLabel
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - Kirigami.Units.largeSpacing)
                        text: row.group
                        font: Kirigami.Theme.smallFont
                        elide: Text.ElideRight
                    }
                }

                // A copy of a Daily task
                Glyph {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: row.daily
                    name: "repeat"
                    opacity: 0.55

                    HoverHandler {
                        id: dailyHover
                    }
                    QQC2.ToolTip.text: i18n("Daily task, added every work day")
                    QQC2.ToolTip.visible: dailyHover.hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                }

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.max(0, (metrics.height - height) / 2)
                    visible: row.carried
                    implicitWidth: yesterdayLabel.implicitWidth + Kirigami.Units.largeSpacing
                    implicitHeight: yesterdayLabel.implicitHeight + 2
                    radius: height / 2
                    color: row.alpha(Kirigami.Theme.neutralTextColor, 0.18)

                    PlasmaComponents3.Label {
                        id: yesterdayLabel
                        anchors.centerIn: parent
                        text: i18n("yesterday")
                        font: Kirigami.Theme.smallFont
                        color: Kirigami.Theme.neutralTextColor
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: eventPoint => taskMenu.openAt(row, taskLine.mapToItem(row, eventPoint.position))
                }
            }

            ContextMenu {
                id: taskMenu

                // Where the group picker opens: where this menu was opened
                onAboutToShow: row.groupPickerAt = Qt.point(x + implicitWidth, y)

                MenuEntry {
                    visible: !row.isTemplate
                    iconName: row.isToday ? "down" : "up"
                    text: row.isToday ? i18n("Move to Queue") : i18n("Move to Today")
                    onClicked: row.widget.moveTask(row.listName, row.index)
                }
                MenuEntry {
                    iconName: "top"
                    text: i18n("Move to top")
                    enabled: row.index > 0
                    onClicked: row.widget.moveToEdge(row.listName, row.index, true)
                }
                MenuEntry {
                    iconName: "bottom"
                    text: i18n("Move to bottom")
                    enabled: row.index < row.listView.count - 1
                    onClicked: row.widget.moveToEdge(row.listName, row.index, false)
                }
                MenuLine {}
                MenuEntry {
                    iconName: "edit"
                    text: i18n("Edit")
                    onClicked: row.startEdit()
                }
                MenuEntry {
                    iconName: "copy"
                    text: i18n("Copy text")
                    onClicked: row.widget.copyTask(row.listName, row.index)
                }
                MenuEntry {
                    iconName: "plus"
                    text: i18n("Add subtask")
                    onClicked: row.startAddSub()
                }
                MenuEntry {
                    visible: !row.isTemplate
                    iconName: row.waiting ? "play" : "pause"
                    text: row.waiting ? i18n("Not waiting anymore") : i18n("Mark as waiting")
                    onClicked: row.widget.setWaiting(row.listName, row.index, !row.waiting)
                }
                MenuEntry {
                    visible: !row.isTemplate
                    iconName: "chevron"
                    text: row.group !== "" ? i18n("Group: %1…", row.group) : i18n("Move to group…")
                    onClicked: groupPicker.openAt(row, groupPickerAt)
                }
                MenuEntry {
                    visible: !row.isTemplate && !row.daily
                    iconName: "repeat"
                    text: i18n("Repeat every work day")
                    onClicked: row.widget.makeDaily(row.listName, row.index)
                }
                MenuEntry {
                    visible: row.daily
                    iconName: "norepeat"
                    text: i18n("Stop repeating")
                    onClicked: row.widget.stopDaily(row.index)
                }
                MenuLine {}
                MenuEntry {
                    iconName: "trash"
                    danger: true
                    text: i18n("Delete…")
                    onClicked: row.askDelete(-1)
                }
            }

            // Pick a Queue group, or type a new one
            ContextMenu {
                id: groupPicker

                Repeater {
                    model: row.widget.groupNames

                    MenuEntry {
                        required property string modelData
                        iconName: modelData === row.group ? "tick" : ""
                        text: modelData
                        onClicked: row.widget.setGroup(row.listName, row.index, modelData)
                    }
                }
                MenuEntry {
                    visible: row.group !== ""
                    iconName: "back"
                    text: i18n("No group")
                    onClicked: row.widget.setGroup(row.listName, row.index, "")
                }
                MenuLine {
                    visible: row.widget.groupNames.length > 0
                }
                PlasmaComponents3.TextField {
                    id: newGroupField
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    placeholderText: i18n("New group, press Enter")
                    onAccepted: {
                        const name = text.trim();
                        text = "";
                        groupPicker.close();
                        if (name !== "") {
                            row.widget.setGroup(row.listName, row.index, name);
                        }
                    }
                }

                onOpened: newGroupField.text = ""
            }

            // ---- subtasks, one level
            Repeater {
                model: row.subs

                RowLayout {
                    id: subRow

                    required property int index
                    required property var modelData

                    function startEdit() {
                        row.editingSub = subRow.index;
                        subEdit.text = subRow.modelData.text;
                        subEdit.forceActiveFocus();
                    }

                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.leftMargin: row.checkSize + Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing + 2

                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: eventPoint => subMenu.openAt(row, subRow.mapToItem(row, eventPoint.position))
                    }

                    ContextMenu {
                        id: subMenu

                        MenuEntry {
                            iconName: "up"
                            text: i18n("Move up")
                            enabled: subRow.index > 0
                            onClicked: row.widget.moveSub(row.listName, row.index, subRow.index, -1)
                        }
                        MenuEntry {
                            iconName: "down"
                            text: i18n("Move down")
                            enabled: subRow.index < row.subs.length - 1
                            onClicked: row.widget.moveSub(row.listName, row.index, subRow.index, 1)
                        }
                        MenuLine {}
                        MenuEntry {
                            iconName: "edit"
                            text: i18n("Edit")
                            onClicked: subRow.startEdit()
                        }
                        MenuEntry {
                            iconName: "copy"
                            text: i18n("Copy text")
                            onClicked: row.widget.copySub(row.listName, row.index, subRow.index)
                        }
                        // A step that grew into work of its own
                        MenuEntry {
                            iconName: "top"
                            text: i18n("Make it a task")
                            onClicked: row.widget.promoteSub(row.listName, row.index, subRow.index)
                        }
                        MenuLine {}
                        MenuEntry {
                            iconName: "trash"
                            danger: true
                            text: i18n("Delete…")
                            onClicked: row.askDelete(subRow.index)
                        }
                    }

                    // Subtasks are ticked in Today only; elsewhere a short dash
                    // marks them, one level below the task's dot
                    TaskCheck {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 1
                        implicitWidth: Math.round(row.checkSize * 0.85)
                        visible: row.isToday
                        on: subRow.modelData.done
                        onClicked: row.widget.toggleSub(row.listName, row.index, subRow.index)
                        Accessible.name: i18n("Complete %1", subRow.modelData.text)
                    }

                    Item {
                        Layout.alignment: Qt.AlignTop
                        visible: !row.isToday
                        implicitWidth: Math.round(row.checkSize * 0.85)
                        implicitHeight: subLabel.implicitHeight > 0 ? Math.min(subLabel.implicitHeight, implicitWidth * 1.4) : implicitWidth

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(parent.implicitWidth * 0.45)
                            height: 1.5
                            radius: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.45
                        }
                    }

                    PlasmaComponents3.Label {
                        id: subLabel
                        Layout.fillWidth: true
                        visible: row.editingSub !== subRow.index
                        text: Tasks.styled(subRow.modelData.text)
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        font: row.smallFont({ strikeout: subRow.modelData.done })
                        opacity: subRow.modelData.done ? 0.55 : 0.9

                        TapHandler {
                            onDoubleTapped: subRow.startEdit()
                        }
                    }

                    PlasmaComponents3.TextField {
                        id: subEdit
                        Layout.fillWidth: true
                        visible: row.editingSub === subRow.index
                        onAccepted: {
                            row.editingSub = -1;
                            row.widget.editSub(row.listName, row.index, subRow.index, text);
                        }
                        Keys.onEscapePressed: event => {
                            row.editingSub = -1;
                            event.accepted = true;
                        }
                    }
                }
            }

            // ---- new subtask
            PlasmaComponents3.TextField {
                id: subField
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: row.checkSize + Kirigami.Units.largeSpacing
                visible: row.addingSub
                placeholderText: i18n("Add subtask, press Enter")
                onAccepted: {
                    const value = text;
                    text = "";
                    row.addingSub = false;
                    row.widget.addSub(row.listName, row.index, value);
                }
                Keys.onEscapePressed: event => {
                    text = "";
                    row.addingSub = false;
                    event.accepted = true;
                }
            }

            // ---- delete confirmation, slides open under the row
            Item {
                id: confirmBox

                property real openness: row.confirmDelete !== -2 ? 1 : 0

                Layout.fillWidth: true
                Layout.preferredHeight: (confirmRow.implicitHeight + Kirigami.Units.smallSpacing * 3) * openness
                clip: true
                visible: openness > 0

                Behavior on openness {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    radius: Kirigami.Units.cornerRadius * 2
                    color: row.alpha(Kirigami.Theme.negativeTextColor, 0.14)
                    opacity: confirmBox.openness

                    RowLayout {
                        id: confirmRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Glyph {
                            name: "trash"
                            color: Kirigami.Theme.negativeTextColor
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            font: Kirigami.Theme.smallFont
                            text: row.confirmText
                        }

                        IconButton {
                            tone: "danger"
                            text: i18n("Delete")
                            onClicked: row.confirmedDelete()
                        }

                        IconButton {
                            text: i18n("Cancel")
                            onClicked: row.confirmDelete = -2
                        }
                    }
                }
            }
        }
    }
}
