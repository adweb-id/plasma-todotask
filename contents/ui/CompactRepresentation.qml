import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

MouseArea {
    id: compact

    required property var widget

    hoverEnabled: true
    onClicked: widget.expanded = !widget.expanded

    Kirigami.Icon {
        anchors.fill: parent
        source: compact.widget.iconSource
        isMask: true
        color: Kirigami.Theme.textColor
        active: compact.containsMouse
    }

    // Tasks left today, or "!" when the file cannot be read or written
    Rectangle {
        id: badge

        readonly property bool problem: compact.widget.errorText !== ""

        visible: problem || compact.widget.todayCount > 0
        anchors.top: parent.top
        anchors.right: parent.right
        height: Math.max(Math.round(parent.height * 0.45), badgeLabel.implicitHeight)
        width: Math.max(height, badgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2)
        radius: height / 2
        color: problem ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.highlightColor

        PlasmaComponents3.Label {
            id: badgeLabel
            anchors.centerIn: parent
            text: parent.problem ? "!" : compact.widget.todayCount
            color: Kirigami.Theme.highlightedTextColor
            font.pixelSize: Math.max(Kirigami.Theme.smallFont.pixelSize, Math.round(compact.height * 0.32))
            font.bold: true
        }
    }

    // The badge bumps when the number of tasks left changes
    Connections {
        target: compact.widget
        function onTodayCountChanged() {
            bump.restart();
        }
    }

    SequentialAnimation {
        id: bump
        NumberAnimation { target: badge; property: "scale"; to: 1.3; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
        NumberAnimation { target: badge; property: "scale"; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack }
    }
}
