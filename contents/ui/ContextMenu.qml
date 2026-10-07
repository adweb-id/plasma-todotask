import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Our own menu, so it uses the widget's icons and grows out of the row.
// Put MenuEntry and MenuLine items inside (a Repeater of them works too);
// an entry closes the menu when clicked.
QQC2.Popup {
    id: menu

    default property alias entries: column.data

    // Opens with its top-right corner at `point` (in `item` coordinates)
    function openAt(item, point) {
        parent = item;
        x = Math.max(0, point.x - implicitWidth);
        y = point.y;
        open();
    }

    padding: Kirigami.Units.smallSpacing
    margins: Kirigami.Units.smallSpacing
    implicitWidth: Math.max(Kirigami.Units.gridUnit * 12, column.implicitWidth + leftPadding + rightPadding)
    closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
    focus: true
    transformOrigin: QQC2.Popup.TopRight

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.shortDuration }
            NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration }
    }

    background: Kirigami.ShadowedRectangle {
        radius: Kirigami.Units.cornerRadius * 2
        color: Qt.tint(Kirigami.Theme.backgroundColor,
                       Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07))
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
        shadow.size: Kirigami.Units.gridUnit
        shadow.yOffset: 3
        shadow.color: Qt.rgba(0, 0, 0, 0.35)
    }

    contentItem: ColumnLayout {
        id: column

        // Lets entries find the menu they are in
        readonly property var popup: menu

        spacing: 0
    }
}
