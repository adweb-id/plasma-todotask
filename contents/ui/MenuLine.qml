import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Separator between groups of a ContextMenu
Rectangle {
    Layout.fillWidth: true
    Layout.margins: Kirigami.Units.smallSpacing
    implicitHeight: 1
    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
}
