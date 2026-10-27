import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// How tasks move: a new day, In review, the Daily tasks and the archive
KCM.SimpleKCM {
    property alias cfg_carryOver: carryCheck.checked
    property alias cfg_reviewStep: reviewCheck.checked
    property string cfg_dailyDays
    property alias cfg_archiveDays: archiveSpin.value

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: carryCheck
            Kirigami.FormData.label: i18n("New day:")
            text: i18n("Keep unfinished tasks in Today")
        }

        QQC2.CheckBox {
            id: reviewCheck
            Kirigami.FormData.label: i18n("Ticking a task:")
            text: i18n("Send it to In review first")
        }

        QQC2.Label {
            text: i18n("A task ticked in Today waits in In review until it is ticked again there. Shift+click the box, or right-click → Done, skip review, to finish one at once.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
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

        QQC2.Label {
            text: i18n("Daily tasks can hold date variables, filled in for the day: {date}, {date-1}, {date:dd/MM/yyyy}.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        }


        QQC2.SpinBox {
            id: archiveSpin
            Kirigami.FormData.label: i18n("Archive finished tasks after (days):")
            from: 0
            to: 365
        }

        QQC2.Label {
            text: i18n("Older finished tasks move to a monthly archive file next to the task file (todo-archive-YYYY-MM.md). 0 keeps everything in the task file.")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        }
    }
}
