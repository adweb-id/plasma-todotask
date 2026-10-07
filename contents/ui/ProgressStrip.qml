import QtQuick
import org.kde.kirigami as Kirigami

// Today's progress as a thin bar the width of the popup. It eases to its new
// length; `shown` follows the animation, so a number bound to it counts along.
Item {
    id: strip

    property real value: 0  // 0 .. 1
    property real shown: value

    implicitHeight: Math.max(3, Math.round(Kirigami.Units.smallSpacing))

    Behavior on shown {
        NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
    }

    Rectangle {
        width: Math.round(parent.width * strip.shown)
        height: parent.height
        radius: height / 2
        visible: width > 0
        // Turns green when everything for today is done
        color: strip.value >= 1 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.highlightColor

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.longDuration }
        }
    }
}
