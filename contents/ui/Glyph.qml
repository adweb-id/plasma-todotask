import QtQuick
import org.kde.kirigami as Kirigami

// One of the widget's own icons (contents/icons/tt-<name>.svg), painted in a
// single colour so it follows the Plasma theme like the text does.
Kirigami.Icon {
    property string name

    implicitWidth: Kirigami.Units.iconSizes.small
    implicitHeight: Kirigami.Units.iconSizes.small
    source: name !== "" ? Qt.resolvedUrl("../icons/tt-" + name + ".svg") : ""
    isMask: true
    color: Kirigami.Theme.textColor
}
