import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.notification

import "tasks.js" as Tasks

// A notification at set times while tasks are left
KCM.SimpleKCM {
    property alias cfg_remindersOn: remindCheck.checked
    property alias cfg_reminderTimes: remindField.text

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: remindCheck
            Kirigami.FormData.label: i18n("Reminders:")
            text: i18n("Remind me to check the list")
        }

        RowLayout {
            enabled: remindCheck.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.TextField {
                id: remindField
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                placeholderText: i18n("11:00, 15:00, 16:45")
            }

            // Shows what a reminder looks like, and that notifications get through
            QQC2.Button {
                icon.source: Qt.resolvedUrl("../icons/tt-bell.svg")
                icon.color: Kirigami.Theme.textColor
                text: i18n("Test")
                onClicked: testComponent.createObject(parent).sendEvent()
            }
        }

        // What the field is read as, so a time that is not understood shows at once
        QQC2.Label {
            readonly property var parts: Tasks.timeParts(remindField.text)
            readonly property bool problem: remindCheck.checked && (parts.times.length === 0 || parts.unknown.length > 0)
            visible: remindCheck.checked
            text: {
                const lines = [];
                if (parts.times.length > 0) {
                    lines.push(i18n("Reminders at %1.", parts.times.join(", ")));
                } else {
                    lines.push(i18n("No time found. Write times like 11:00 or 16.45, separated by commas."));
                }
                if (parts.unknown.length > 0) {
                    lines.push(i18n("Not understood: %1", parts.unknown.join(", ")));
                }
                return lines.join("\n");
            }
            color: problem ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.textColor
            font: Kirigami.Theme.smallFont
            opacity: problem ? 1 : 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        }

        QQC2.Label {
            text: i18n("On the work days of the Daily tasks, a notification shows how many tasks are left, only while some are. Plasma's Do Not Disturb holds it back.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        }

        Component {
            id: testComponent

            Notification {
                componentName: "todotask"
                eventId: "reminder"
                iconName: decodeURIComponent(String(Qt.resolvedUrl("../icons/todotask-logo.svg")).replace(/^file:\/\//, ""))
                hints: ({ "x-kde-display-appname": i18n("Todo Task") })
                title: i18n("3 tasks left today")
                text: i18n("• This is how a reminder looks")
            }
        }
    }
}
