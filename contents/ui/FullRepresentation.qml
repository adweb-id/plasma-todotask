import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

import "tasks.js" as Tasks

PlasmaExtras.Representation {
    id: full

    required property var widget
    property bool showDone: false
    // The About page hides the input, the lists and the footer
    readonly property bool listing: !widget.showAbout
    readonly property int sideMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing

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

    Layout.minimumWidth: Kirigami.Units.gridUnit * 14
    Layout.minimumHeight: Kirigami.Units.gridUnit * 14
    Layout.preferredWidth: widget.popupWidth
    Layout.preferredHeight: Kirigami.Units.gridUnit * 28

    collapseMarginsHint: true

    // A list of tasks whose rows animate in, out and into place.
    component TaskList: ListView {
        id: list

        property var widget
        property string listName

        implicitHeight: contentHeight
        interactive: false
        boundsBehavior: Flickable.StopAtBounds

        delegate: TaskDelegate {
            widget: list.widget
            listName: list.listName
            listView: list
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.longDuration }
                NumberAnimation { property: "x"; to: Kirigami.Units.gridUnit; duration: Kirigami.Units.longDuration; easing.type: Easing.InCubic }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
            // An add or remove cut short must not leave a row faded or shrunk
            NumberAnimation { properties: "opacity,scale"; to: 1; duration: Kirigami.Units.shortDuration }
        }
        move: Transition {
            NumberAnimation { property: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }
        moveDisplaced: Transition {
            NumberAnimation { property: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }

        Behavior on implicitHeight {
            NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }
    }

    // "QUEUE  3" with a chevron when the list can be folded away
    component SectionHeading: QQC2.AbstractButton {
        id: heading

        property string title
        property int count: 0
        property bool foldable: false
        property bool open: true

        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.rightMargin: Kirigami.Units.largeSpacing
        Layout.topMargin: Kirigami.Units.largeSpacing
        hoverEnabled: foldable
        focusPolicy: foldable ? Qt.TabFocus : Qt.NoFocus
        padding: Kirigami.Units.smallSpacing
        opacity: foldable && hovered ? 1 : 0.75

        Accessible.role: foldable ? Accessible.Button : Accessible.Heading
        Accessible.name: title

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration }
        }

        // A hand and a light tint say the heading can be clicked
        HoverHandler {
            cursorShape: heading.foldable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        background: Rectangle {
            radius: Kirigami.Units.cornerRadius * 2
            color: full.alpha(Kirigami.Theme.textColor, heading.foldable && heading.hovered ? 0.05 : 0)
            border.width: heading.visualFocus ? 2 : 0
            border.color: Kirigami.Theme.focusColor

            Behavior on color {
                ColorAnimation { duration: Kirigami.Units.shortDuration }
            }
        }

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Glyph {
                visible: heading.foldable
                implicitWidth: Math.round(Kirigami.Units.iconSizes.small * 0.75)
                implicitHeight: implicitWidth
                name: "chevron"
                rotation: heading.open ? 90 : 0

                Behavior on rotation {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }
            }

            PlasmaComponents3.Label {
                text: heading.title
                font: full.smallFont({ weight: Font.DemiBold, capitalization: Font.AllUppercase, letterSpacing: 0.6 })
            }

            Rectangle {
                implicitWidth: Math.max(implicitHeight, countLabel.implicitWidth + Kirigami.Units.largeSpacing)
                implicitHeight: countLabel.implicitHeight + 2
                radius: height / 2
                color: full.alpha(Kirigami.Theme.textColor, 0.09)

                PlasmaComponents3.Label {
                    id: countLabel
                    anchors.centerIn: parent
                    text: heading.count
                    font: Kirigami.Theme.smallFont
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    header: PlasmaExtras.PlasmoidHeading {
        visible: full.listing
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            // Title and date on the left, workspace and done / total on the right, the bar below
            ColumnLayout {
                id: headerBox

                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                readonly property int total: full.widget.todayCount + full.widget.doneCount

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing

                    ColumnLayout {
                        spacing: 0

                        Kirigami.Heading {
                            level: 3
                            text: i18n("Today")
                        }

                        PlasmaComponents3.Label {
                            readonly property string date: Qt.formatDate(new Date(), "ddd d MMM")
                            text: {
                                const left = full.widget.todayCount > 0 ? i18n("%1 left", full.widget.todayCount) : i18n("all done");
                                return full.widget.todayWaiting > 0
                                       ? i18n("%1 · %2 · %3 waiting", date, left, full.widget.todayWaiting)
                                       : i18n("%1 · %2", date, left);
                            }
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Workspace on top, done / total below it
                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop
                        spacing: Kirigami.Units.smallSpacing

                        // Which workspace is shown; click to switch to another one
                        QQC2.AbstractButton {
                            id: workspaceChip

                            visible: full.widget.workspaces.length > 1
                            hoverEnabled: true
                            padding: 2
                            leftPadding: Kirigami.Units.smallSpacing * 2
                            rightPadding: Kirigami.Units.smallSpacing
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                            Accessible.name: i18n("Workspace: %1. Switch workspace", full.widget.activeName)
                            onClicked: workspaceMenu.openAt(workspaceChip, Qt.point(workspaceChip.width, workspaceChip.height + 2))

                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }

                            // "Switch workspace…" in the widget's own menu
                            Timer {
                                interval: Kirigami.Units.longDuration
                                running: full.widget.workspaceMenuWanted && full.widget.expanded && workspaceChip.visible
                                onTriggered: {
                                    full.widget.workspaceMenuWanted = false;
                                    workspaceChip.clicked();
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 2

                                PlasmaComponents3.Label {
                                    Layout.fillWidth: true
                                    text: full.widget.activeName
                                    font: Kirigami.Theme.smallFont
                                    elide: Text.ElideRight
                                }

                                Glyph {
                                    implicitWidth: Math.round(Kirigami.Units.iconSizes.small * 0.7)
                                    implicitHeight: implicitWidth
                                    name: "chevron"
                                    rotation: 90
                                    opacity: 0.7
                                }
                            }

                            background: Rectangle {
                                radius: height / 2
                                color: full.alpha(Kirigami.Theme.highlightColor, workspaceChip.hovered || workspaceMenu.opened ? 0.3 : 0.16)
                                border.width: workspaceChip.visualFocus ? 2 : 0
                                border.color: Kirigami.Theme.focusColor

                                Behavior on color {
                                    ColorAnimation { duration: Kirigami.Units.shortDuration }
                                }
                            }

                            ContextMenu {
                                id: workspaceMenu

                                Repeater {
                                    model: full.widget.workspaces

                                    MenuEntry {
                                        required property int index
                                        required property var modelData
                                        iconName: index === full.widget.activeIndex ? "tick" : ""
                                        text: modelData.name
                                        onClicked: full.widget.switchWorkspace(index)
                                    }
                                }
                            }
                        }

                        PlasmaComponents3.Label {
                            Layout.alignment: Qt.AlignRight
                            Layout.topMargin: workspaceChip.visible ? 0 : Kirigami.Units.smallSpacing
                            visible: headerBox.total > 0
                            text: i18nc("done of total · percent", "%1/%2 · %3%", full.widget.doneCount, headerBox.total,
                                        Math.round(progress.shown * 100))
                            font.weight: Font.DemiBold
                            font.features: { "tnum": 1 }
                            color: progress.value >= 1 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                            opacity: progress.value >= 1 ? 1 : 0.85
                            Accessible.name: i18n("%1 of %2 done today", full.widget.doneCount, headerBox.total)
                        }
                    }
                }

                ProgressStrip {
                    id: progress
                    Layout.fillWidth: true
                    value: headerBox.total > 0 ? full.widget.doneCount / headerBox.total : 0
                }
            }

            // Enter adds to the configured list, Shift+Enter to the other one;
            // after ＋ on a Queue group, everything goes to that group until Esc
            PlasmaComponents3.TextField {
                id: input
                Layout.fillWidth: true
                // Room for the group chip when it shows
                leftPadding: groupChip.visible ? groupChip.width + Kirigami.Units.smallSpacing * 2 : Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                placeholderText: full.widget.addGroup !== "" ? i18n("Add to %1 · Esc to stop", full.widget.addGroup)
                               : Plasmoid.configuration.newTaskTarget === "today"
                                 ? i18n("Add a task · Enter → Today, Shift+Enter → Queue")
                                 : i18n("Add a task · Enter → Queue, Shift+Enter → Today")
                enabled: full.widget.loaded

                function submit(event) {
                    full.widget.addTask(text, (event.modifiers & Qt.ShiftModifier) !== 0);
                    text = "";
                    event.accepted = true;
                }

                Keys.onReturnPressed: event => submit(event)
                Keys.onEnterPressed: event => submit(event)
                Keys.onEscapePressed: event => {
                    if (full.widget.addGroup !== "") {
                        full.widget.addGroup = "";
                        event.accepted = true;
                    } else {
                        event.accepted = false;
                    }
                }

                // Which group new tasks go to; ✕ stops
                Rectangle {
                    id: groupChip
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    visible: full.widget.addGroup !== ""
                    width: chipRow.implicitWidth + Kirigami.Units.smallSpacing * 2
                    height: parent.height - Kirigami.Units.smallSpacing * 2
                    radius: Kirigami.Units.cornerRadius
                    color: full.alpha(Kirigami.Theme.highlightColor, 0.25)

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 2

                        PlasmaComponents3.Label {
                            text: full.widget.addGroup
                            font: Kirigami.Theme.smallFont
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
                            elide: Text.ElideRight
                        }

                        IconButton {
                            implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.1)
                            iconName: "plus"
                            rotation: 45
                            tip: i18n("Stop adding to %1", full.widget.addGroup)
                            onClicked: full.widget.addGroup = ""
                        }
                    }
                }

                Connections {
                    target: full.widget
                    function onInputRequested() {
                        input.forceActiveFocus();
                    }
                }
            }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        visible: full.listing
        position: QQC2.ToolBar.Footer

        contentItem: RowLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                text: full.widget.displayPath
                font: Kirigami.Theme.smallFont
                opacity: 0.6
                elide: Text.ElideMiddle
            }

            IconButton {
                iconName: "retry"
                tip: i18n("Reload the file, e.g. after editing it elsewhere")
                onClicked: full.widget.load(true)
            }

            IconButton {
                iconName: "file"
                text: i18n("Open file")
                onClicked: full.widget.openFile()
            }
        }
    }

    PlasmaComponents3.ScrollView {
        id: scroll
        anchors.fill: parent
        visible: full.listing && full.widget.loaded && full.widget.errorText === ""
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0

            // ---- Today; right-click copies the whole list, e.g. for a daily report
            SectionHeading {
                id: todayHeading
                Layout.topMargin: Kirigami.Units.smallSpacing
                title: i18n("Today")
                count: full.widget.todayTotal

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: eventPoint => todayMenu.openAt(todayHeading, Qt.point(eventPoint.position.x + todayMenu.implicitWidth, eventPoint.position.y))
                }

                ContextMenu {
                    id: todayMenu

                    MenuEntry {
                        iconName: "copy"
                        text: i18n("Copy all")
                        enabled: full.widget.todayTotal > 0
                        onClicked: full.widget.copyAll("today")
                    }
                }
            }

            TaskList {
                Layout.fillWidth: true
                widget: full.widget
                listName: "today"
                model: full.widget.todayModel
            }

            // Today is empty: one compact line, so the queue below stays in view
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                visible: opacity > 0
                opacity: full.widget.todayTotal === 0 ? 1 : 0
                implicitHeight: emptyRow.implicitHeight + Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius * 2
                color: full.alpha(Kirigami.Theme.positiveTextColor, 0.12)

                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.longDuration }
                }

                RowLayout {
                    id: emptyRow
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.largeSpacing

                    readonly property bool allDone: full.widget.queueTotal + full.widget.doneCount > 0

                    Glyph {
                        name: emptyRow.allDone ? "tick" : "empty"
                        color: emptyRow.allDone ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: emptyRow.allDone ? i18n("All done for today") : i18n("Nothing to do yet")
                        wrapMode: Text.Wrap
                    }

                    IconButton {
                        visible: full.widget.queueCount > 0
                        tone: "accent"
                        iconName: "up"
                        text: i18n("Pull next")
                        onClicked: full.widget.pullNext()
                    }
                }
            }

            // ---- Done today (folded by default)
            SectionHeading {
                visible: full.widget.doneCount > 0
                title: i18n("Done today")
                count: full.widget.doneCount
                foldable: true
                open: full.showDone
                onClicked: full.showDone = !full.showDone
            }

            Item {
                property real openness: full.showDone ? 1 : 0

                Layout.fillWidth: true
                Layout.preferredHeight: doneList.implicitHeight * openness
                visible: full.widget.doneCount > 0 && openness > 0
                clip: true

                Behavior on openness {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }

                ListView {
                    id: doneList
                    width: parent.width
                    implicitHeight: contentHeight
                    interactive: false
                    model: full.widget.doneModel

                    delegate: Item {
                        id: doneRow

                        required property int index
                        required property string taskText

                        width: ListView.view.width
                        implicitHeight: doneLine.implicitHeight + Kirigami.Units.smallSpacing * 2

                        RowLayout {
                            id: doneLine
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: full.sideMargin
                            anchors.rightMargin: full.sideMargin
                            spacing: Kirigami.Units.largeSpacing

                            TaskCheck {
                                on: true
                                onClicked: full.widget.uncompleteTask(doneRow.index)
                                Accessible.name: i18n("Mark %1 as not done", doneRow.taskText)
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: Tasks.styled(doneRow.taskText)
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                opacity: 0.5
                                font.strikeout: true
                            }
                        }
                    }

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.longDuration }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "opacity"; to: 1; duration: Kirigami.Units.shortDuration }
                    }
                }
            }

            // ---- Queue, can be folded away; the choice is remembered
            SectionHeading {
                title: i18n("Queue")
                count: full.widget.queueTotal
                foldable: true
                open: !full.widget.queueCollapsed
                onClicked: full.widget.setQueueCollapsed(open)
            }

            Item {
                property real openness: full.widget.queueCollapsed ? 0 : 1

                Layout.fillWidth: true
                Layout.preferredHeight: queueList.implicitHeight * openness
                visible: openness > 0
                clip: openness < 1

                Behavior on openness {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }

                TaskList {
                    id: queueList
                    width: parent.width
                    widget: full.widget
                    listName: "queue"
                    model: full.widget.queueModel
                }
            }

            // ---- Daily: the template copied to the top of Today every work day.
            // Rarely needed, so it sits last and starts folded.
            SectionHeading {
                visible: full.widget.dailyCount > 0
                title: i18n("Daily")
                count: full.widget.dailyCount
                foldable: true
                open: !full.widget.dailyCollapsed
                onClicked: full.widget.setDailyCollapsed(open)
            }

            Item {
                property real openness: full.widget.dailyCollapsed ? 0 : 1

                Layout.fillWidth: true
                Layout.preferredHeight: dailyColumn.implicitHeight * openness
                visible: full.widget.dailyCount > 0 && openness > 0
                clip: openness < 1

                Behavior on openness {
                    NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: dailyColumn
                    width: parent.width
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: full.sideMargin
                        Layout.rightMargin: full.sideMargin
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                        text: i18n("Added to the top of Today every work day.")
                        font: Kirigami.Theme.smallFont
                        opacity: 0.6
                        wrapMode: Text.Wrap
                    }

                    TaskList {
                        Layout.fillWidth: true
                        widget: full.widget
                        listName: "daily"
                        model: full.widget.dailyModel
                    }
                }
            }

            // Room so the toast never covers the last row for good
            Item {
                implicitHeight: Kirigami.Units.gridUnit * 3
            }
        }
    }

    // State: reading the file for the first time
    PlasmaComponents3.BusyIndicator {
        anchors.centerIn: parent
        visible: full.listing && !full.widget.loaded && full.widget.errorText === ""
        running: visible
    }

    // State: the file cannot be read or written
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: full.listing && full.widget.errorText !== ""
        spacing: Kirigami.Units.largeSpacing

        Glyph {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.iconSizes.large
            implicitHeight: Kirigami.Units.iconSizes.large
            name: "warning"
            color: Kirigami.Theme.neutralTextColor
        }

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 3
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: i18n("Problem with the task file")
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            opacity: 0.7
            text: full.widget.errorText + "\n" + full.widget.displayPath
        }

        IconButton {
            Layout.alignment: Qt.AlignHCenter
            tone: "accent"
            iconName: "retry"
            text: i18n("Try again")
            onClicked: full.widget.load()
        }
    }

    // State: About page, opened from the panel icon's right-click menu
    AboutView {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: full.widget.showAbout
        widget: full.widget
    }

    // What just happened, with Undo, for 5 seconds. Floats over the bottom of
    // the list and rises in with a slight overshoot.
    Kirigami.ShadowedRectangle {
        id: toast

        // A flash (e.g. "Copied …") shows over the notice for a moment; the
        // notice and its Undo come back if they are still pending
        readonly property bool flashing: full.widget.flashText !== ""
        readonly property bool shown: full.listing && (flashing || full.widget.noticeText !== "")

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.bottomMargin: shown ? Kirigami.Units.largeSpacing : Kirigami.Units.largeSpacing - Kirigami.Units.gridUnit
        height: toastRow.implicitHeight + Kirigami.Units.smallSpacing * 2
        z: 10
        radius: Kirigami.Units.cornerRadius * 2
        color: Qt.tint(Kirigami.Theme.backgroundColor, full.alpha(Kirigami.Theme.textColor, 0.1))
        border.width: 1
        border.color: full.alpha(Kirigami.Theme.textColor, 0.12)
        shadow.size: Kirigami.Units.gridUnit
        shadow.yOffset: 3
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
        opacity: shown ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.longDuration }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Kirigami.Units.longDuration * 1.4
                easing.type: toast.shown ? Easing.OutBack : Easing.InQuad
            }
        }

        RowLayout {
            id: toastRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Glyph {
                name: toast.flashing ? "copy" : "tick"
                color: Kirigami.Theme.positiveTextColor
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: toast.flashing ? full.widget.flashText : full.widget.noticeText
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            IconButton {
                visible: !toast.flashing && full.widget.noticeList === "queue" && full.widget.queueCollapsed
                text: i18n("Show")
                onClicked: full.widget.setQueueCollapsed(false)
            }

            IconButton {
                visible: !toast.flashing && full.widget.undoSnapshot !== ""
                tone: "accent"
                iconName: "undo"
                text: i18n("Undo")
                onClicked: full.widget.undo()
            }
        }
    }
}
