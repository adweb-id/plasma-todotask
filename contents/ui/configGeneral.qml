import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_newTaskTarget
    property alias cfg_popupWidth: widthSpin.value
    property alias cfg_carryOver: carryCheck.checked
    property alias cfg_archiveDays: archiveSpin.value
    property string cfg_dailyDays

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: targetCombo
            Kirigami.FormData.label: i18n("Enter adds a task to:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Queue (Shift+Enter adds to Today)"), value: "queue" },
                { text: i18n("Today (Shift+Enter adds to Queue)"), value: "today" }
            ]
            onActivated: cfg_newTaskTarget = currentValue
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_newTaskTarget))
        }

        QQC2.SpinBox {
            id: widthSpin
            Kirigami.FormData.label: i18n("Popup width (pixels):")
            from: 300
            to: 800
            stepSize: 20
        }

        QQC2.CheckBox {
            id: carryCheck
            Kirigami.FormData.label: i18n("New day:")
            text: i18n("Keep unfinished tasks in Today")
        }

        // Work days for the Daily tasks, Monday first; stored as Date.getDay() numbers
        RowLayout {
            Kirigami.FormData.label: i18n("Daily tasks on:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: [1, 2, 3, 4, 5, 6, 0]

                QQC2.CheckBox {
                    required property int modelData
                    text: Qt.locale().dayName(modelData, Locale.ShortFormat)
                    checked: cfg_dailyDays.split(",").indexOf(String(modelData)) !== -1
                    onToggled: {
                        const days = cfg_dailyDays.split(",").filter(d => d !== "" && d !== String(modelData));
                        if (checked) {
                            days.push(String(modelData));
                        }
                        cfg_dailyDays = days.sort().join(",");
                    }
                }
            }
        }

        QQC2.SpinBox {
            id: archiveSpin
            Kirigami.FormData.label: i18n("Archive finished tasks after (days):")
            from: 0
            to: 365
        }

        QQC2.Label {
            text: i18n("Older finished tasks move to todo-archive-YYYY-MM.md. 0 keeps everything in todo.md.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
