import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Heading of a Queue group ("### SRSX" in the file), used as the Queue list's
// section delegate. Click folds the group; ＋ adds a task to it; ⋯ or a
// right-click opens rename / move / remove.
Item {
    id: heading

    required property string section
    required property var widget

    readonly property bool folded: widget.foldedGroups.indexOf(section) !== -1
    readonly property int position: widget.groupNames.indexOf(section)
    property bool renaming: false

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    function startRename() {
        renaming = true;
        renameField.text = section;
        renameField.forceActiveFocus();
        renameField.selectAll();
    }

    function finishRename() {
        if (renaming) {
            renaming = false;
            widget.renameGroup(section, renameField.text);
        }
    }

    width: ListView.view ? ListView.view.width : implicitWidth
    // Tasks without a group form a section too; it has no heading
    implicitHeight: section === "" ? 0 : line.implicitHeight + Kirigami.Units.smallSpacing * 2
    visible: section !== ""

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        radius: Kirigami.Units.cornerRadius * 2
        color: heading.alpha(Kirigami.Theme.textColor, hover.hovered || groupMenu.opened ? 0.05 : 0)

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    RowLayout {
        id: line
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        Glyph {
            implicitWidth: Math.round(Kirigami.Units.iconSizes.small * 0.75)
            implicitHeight: implicitWidth
            name: "chevron"
            opacity: 0.7
            rotation: heading.folded ? 0 : 90

            Behavior on rotation {
                NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
            }
        }

        PlasmaComponents3.Label {
            visible: !heading.renaming
            text: heading.section
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.maximumWidth: line.width - Kirigami.Units.gridUnit * 6
        }

        PlasmaComponents3.TextField {
            id: renameField
            Layout.fillWidth: true
            visible: heading.renaming
            onAccepted: heading.finishRename()
            onActiveFocusChanged: {
                if (!activeFocus) {
                    heading.finishRename();
                }
            }
            Keys.onEscapePressed: event => {
                heading.renaming = false;
                event.accepted = true;
            }
        }

        Rectangle {
            visible: !heading.renaming
            implicitWidth: Math.max(implicitHeight, countLabel.implicitWidth + Kirigami.Units.largeSpacing)
            implicitHeight: countLabel.implicitHeight + 2
            radius: height / 2
            color: heading.alpha(Kirigami.Theme.textColor, 0.09)

            PlasmaComponents3.Label {
                id: countLabel
                anchors.centerIn: parent
                text: heading.widget.groupCounts[heading.section] || 0
                font: Kirigami.Theme.smallFont
            }
        }

        Item {
            Layout.fillWidth: true
            visible: !heading.renaming
        }

        RowLayout {
            spacing: 0
            opacity: (hover.hovered || groupMenu.opened) && !heading.renaming ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }

            IconButton {
                iconName: "plus"
                tip: i18n("Add a task to %1", heading.section)
                onClicked: heading.widget.startAddToGroup(heading.section)
            }

            IconButton {
                id: moreButton
                iconName: "more"
                tip: i18n("More")
                onClicked: groupMenu.openAt(heading, moreButton.mapToItem(heading, moreButton.width, moreButton.height))
            }
        }
    }

    TapHandler {
        enabled: !heading.renaming
        onTapped: heading.widget.foldGroup(heading.section, !heading.folded)
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: eventPoint => groupMenu.openAt(heading, eventPoint.position)
    }

    Accessible.role: Accessible.Button
    Accessible.name: heading.folded ? i18n("Show group %1", heading.section) : i18n("Hide group %1", heading.section)

    ContextMenu {
        id: groupMenu

        MenuEntry {
            iconName: "plus"
            text: i18n("Add task here")
            onClicked: heading.widget.startAddToGroup(heading.section)
        }
        MenuEntry {
            iconName: "edit"
            text: i18n("Rename")
            onClicked: heading.startRename()
        }
        MenuLine {}
        MenuEntry {
            iconName: "up"
            text: i18n("Move group up")
            enabled: heading.position > 0
            onClicked: heading.widget.moveGroup(heading.section, -1)
        }
        MenuEntry {
            iconName: "down"
            text: i18n("Move group down")
            enabled: heading.position < heading.widget.groupNames.length - 1
            onClicked: heading.widget.moveGroup(heading.section, 1)
        }
        MenuLine {}
        MenuEntry {
            iconName: "trash"
            danger: true
            text: i18n("Remove group (keep tasks)")
            onClicked: heading.widget.removeGroup(heading.section)
        }
    }
}
