import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: Qt.resolvedUrl("../icons/cfg-general.svg")
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Tasks")
        icon: Qt.resolvedUrl("../icons/cfg-tasks.svg")
        source: "configTasks.qml"
    }
    ConfigCategory {
        name: i18n("Reminders")
        icon: Qt.resolvedUrl("../icons/cfg-reminders.svg")
        source: "configReminders.qml"
    }
}
