import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// One line of a ContextMenu
QQC2.AbstractButton {
    id: entry

    property string iconName
    property bool danger: false

    readonly property color ink: danger ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor

    Layout.fillWidth: true
    hoverEnabled: true
    padding: Kirigami.Units.smallSpacing
    leftPadding: Kirigami.Units.largeSpacing
    rightPadding: Kirigami.Units.largeSpacing * 2
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.7)

    Accessible.role: Accessible.MenuItem

    // Close the menu this entry is in
    Connections {
        target: entry
        function onClicked() {
            let item = entry.parent;
            while (item && !item.popup) {
                item = item.parent;
            }
            if (item) {
                item.popup.close();
            }
        }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Glyph {
            name: entry.iconName
            color: entry.ink
            opacity: entry.enabled ? 1 : 0.35
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: entry.text
            color: entry.ink
            opacity: entry.enabled ? 1 : 0.4
        }
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: (entry.hovered || entry.visualFocus) && entry.enabled
               ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b,
                         entry.pressed ? 0.35 : 0.22)
               : "transparent"

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }
}
