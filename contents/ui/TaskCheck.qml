import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Round-cornered check box that pops when it is ticked.
QQC2.AbstractButton {
    id: box

    property bool on: false

    hoverEnabled: true
    implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.05)
    implicitHeight: implicitWidth

    Accessible.role: Accessible.CheckBox
    Accessible.checked: on

    background: Rectangle {
        radius: Math.round(box.width * 0.28)
        color: box.on ? Kirigami.Theme.highlightColor : "transparent"
        border.width: box.on ? 0 : 1.5
        border.color: box.hovered || box.visualFocus ? Kirigami.Theme.highlightColor
                                                     : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                                               Kirigami.Theme.textColor.b, 0.45)

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
        Behavior on border.color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    contentItem: Item {
        Glyph {
            anchors.centerIn: parent
            width: Math.round(box.width * 0.7)
            height: width
            name: "tick"
            color: Kirigami.Theme.highlightedTextColor
            opacity: box.on ? 1 : 0
            scale: box.on ? 1 : 0.4

            Behavior on opacity {
                NumberAnimation { duration: Kirigami.Units.shortDuration }
            }
            Behavior on scale {
                NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack }
            }
        }
    }

    onOnChanged: {
        if (on) {
            pop.restart();
        }
    }

    SequentialAnimation {
        id: pop
        NumberAnimation { target: box; property: "scale"; to: 1.15; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
        NumberAnimation { target: box; property: "scale"; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack }
    }
}
