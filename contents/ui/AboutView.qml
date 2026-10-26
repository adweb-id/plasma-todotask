import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

// "About Todo Task", opened from the panel icon's right-click menu.
// Name, version, author and links come from metadata.json.
ColumnLayout {
    id: about

    required property var widget

    readonly property var meta: Plasmoid.metaData

    spacing: Kirigami.Units.largeSpacing

    Kirigami.Icon {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Kirigami.Units.iconSizes.enormous
        implicitHeight: Kirigami.Units.iconSizes.enormous
        source: Qt.resolvedUrl("../icons/todotask-logo.svg").toString()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Kirigami.Heading {
            Layout.fillWidth: true
            level: 2
            horizontalAlignment: Text.AlignHCenter
            text: about.meta.name
        }

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: i18n("Version %1", about.meta.version)
            opacity: 0.7
        }
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: about.meta.description
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        text: i18n("%1 · License %2", about.meta.copyrightText, about.meta.license)
    }

    // Wraps onto two lines in a narrow popup
    Flow {
        id: links

        // One line when the buttons fit, as wide as they need
        readonly property real natural: helpButton.implicitWidth + sourceButton.implicitWidth
                                        + bugButton.implicitWidth + spacing * 2

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(natural, about.width - Kirigami.Units.largeSpacing * 2)
        spacing: Kirigami.Units.smallSpacing

        // Answers to common questions, in the README on GitHub
        IconButton {
            id: helpButton
            tone: "accent"
            iconName: "help"
            text: i18n("Help")
            onClicked: Qt.openUrlExternally(about.meta.website + "#faq")
        }

        IconButton {
            id: sourceButton
            tone: "accent"
            iconName: "external"
            text: i18n("Source code")
            onClicked: Qt.openUrlExternally(about.meta.website)
        }

        IconButton {
            id: bugButton
            tone: "accent"
            iconName: "bug"
            text: i18n("Report a bug")
            onClicked: Qt.openUrlExternally(about.meta.bugReportUrl)
        }
    }

    IconButton {
        Layout.alignment: Qt.AlignHCenter
        iconName: "back"
        text: i18n("Back")
        onClicked: about.widget.showAbout = false
    }
}
