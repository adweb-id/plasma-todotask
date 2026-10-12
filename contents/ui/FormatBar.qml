import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

import "tasks.js" as Tasks

// Bold and italic for a text field: put it inside the field. While text is
// selected a small bar with B and I shows above it; Ctrl+B and Ctrl+I do the
// same. The field keeps showing plain text: the marks (**bold**, *italic*)
// are put around the selection, or taken away when they are already there.
Item {
    id: bar

    property Item field: parent

    // The lists the field scrolls in. A popup is not cut off by them, so the
    // bar has to go away itself when the field scrolls out of sight.
    readonly property var scrollers: {
        const found = [];
        for (let p = field.parent; p; p = p.parent) {
            if (p instanceof Flickable) {
                found.push(p);
            }
        }
        return found;
    }
    readonly property bool inView: {
        for (let i = 0; i < scrollers.length; i++) {
            const view = scrollers[i];
            // Read so that scrolling and resizing are followed
            view.contentY;
            view.contentHeight;
            const top = field.mapToItem(view, 0, 0).y;
            if (top < 0 || top + field.height > view.height) {
                return false;
            }
        }
        return true;
    }

    function toggle(mark) {
        const r = Tasks.toggleMark(field.text, field.selectionStart, field.selectionEnd, mark);
        field.remove(0, field.length);
        field.insert(0, r.text);
        if (r.start === r.end) {
            field.cursorPosition = r.start;
        } else {
            field.select(r.start, r.end);
        }
    }

    // Only the field being typed in has the shortcuts and the bar
    Loader {
        active: bar.field.activeFocus
        sourceComponent: Item {
            Shortcut {
                sequence: "Ctrl+B"
                onActivated: bar.toggle("**")
            }
            Shortcut {
                sequence: "Ctrl+I"
                onActivated: bar.toggle("*")
            }

            QQC2.Popup {
                id: popup

                // Where the selection starts, in field coordinates
                readonly property rect at: bar.field.positionToRectangle(bar.field.selectionStart)

                parent: bar.field
                x: Math.max(0, Math.min(at.x, bar.field.width - width))
                y: -height - 2
                visible: bar.field.visible && bar.inView && bar.field.selectedText.trim() !== ""
                // The field keeps the keyboard and its selection
                focus: false
                closePolicy: QQC2.Popup.NoAutoClose
                padding: 2
                margins: 0

                enter: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Kirigami.Units.shortDuration }
                }
                exit: Transition {
                    NumberAnimation { property: "opacity"; to: 0; duration: Kirigami.Units.shortDuration }
                }

                background: Kirigami.ShadowedRectangle {
                    radius: Kirigami.Units.cornerRadius
                    color: Qt.tint(Kirigami.Theme.backgroundColor,
                                   Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.07))
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                    shadow.size: Kirigami.Units.gridUnit / 2
                    shadow.yOffset: 2
                    shadow.color: Qt.rgba(0, 0, 0, 0.3)
                }

                contentItem: RowLayout {
                    spacing: 0

                    MarkButton {
                        text: i18nc("button: bold", "B")
                        font.bold: true
                        tip: i18n("Bold (Ctrl+B)")
                        onClicked: bar.toggle("**")
                    }
                    MarkButton {
                        text: i18nc("button: italic", "I")
                        font.italic: true
                        tip: i18n("Italic (Ctrl+I)")
                        onClicked: bar.toggle("*")
                    }
                }
            }
        }
    }

    component MarkButton: QQC2.AbstractButton {
        id: mark

        property string tip: ""

        // A click must not take the keyboard from the field
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        implicitWidth: Kirigami.Units.gridUnit * 1.5
        implicitHeight: Kirigami.Units.gridUnit * 1.5
        Accessible.name: tip

        contentItem: PlasmaComponents3.Label {
            text: mark.text
            font: mark.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: Kirigami.Units.cornerRadius
            color: Kirigami.Theme.textColor
            opacity: mark.pressed ? 0.2 : mark.hovered ? 0.1 : 0
        }

        QQC2.ToolTip.text: tip
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
}
