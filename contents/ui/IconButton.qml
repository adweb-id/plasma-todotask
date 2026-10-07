import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// A small button with one of our icons and/or a text.
// tone: "flat" (default), "accent" (tinted) or "danger" (red, for Delete).
QQC2.AbstractButton {
    id: button

    property string iconName
    property string tone: "flat"
    property string tip: ""

    readonly property color ink: tone === "danger" ? "white" : Kirigami.Theme.textColor

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    hoverEnabled: true
    padding: Kirigami.Units.smallSpacing
    leftPadding: text !== "" ? Kirigami.Units.largeSpacing : padding
    rightPadding: text !== "" ? Kirigami.Units.largeSpacing : padding
    implicitWidth: Math.max(implicitHeight, contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.6)

    Accessible.name: tip !== "" ? tip : text

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Glyph {
            Layout.alignment: Qt.AlignVCenter
            visible: button.iconName !== ""
            name: button.iconName
            color: button.ink
            opacity: button.enabled ? (button.hovered || button.tone !== "flat" ? 1 : 0.75) : 0.35
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignVCenter
            visible: button.text !== ""
            text: button.text
            color: button.ink
            opacity: button.enabled ? 1 : 0.4
        }
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        border.width: button.visualFocus ? 2 : 0
        border.color: Kirigami.Theme.focusColor
        color: {
            if (button.tone === "danger") {
                return button.pressed ? Qt.darker(Kirigami.Theme.negativeTextColor, 1.15)
                     : button.hovered ? Qt.lighter(Kirigami.Theme.negativeTextColor, 1.1)
                     : Kirigami.Theme.negativeTextColor;
            }
            const base = button.tone === "accent" ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor;
            const rest = button.tone === "accent" ? 0.22 : 0;
            return button.alpha(base, button.pressed ? rest + 0.16 : button.hovered ? rest + 0.1 : rest);
        }

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration }
        }
    }

    QQC2.ToolTip.text: tip
    QQC2.ToolTip.visible: tip !== "" && text === "" && hovered
    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
}
