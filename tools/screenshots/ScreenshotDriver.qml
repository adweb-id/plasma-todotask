import QtQuick
import org.kde.plasma.plasmoid

// Added by take.sh to main.qml of the copy installed in the demo desktop: opens
// the popup in the state of one screenshot. take.sh captures the screen.
Item {
    id: driver
    required property var widget
    readonly property string scenario: "@SCENARIO@"

    function walk(item, visit, skipHeadings) {
        if (!item || (skipHeadings && item.startRename !== undefined)) {
            return;
        }
        visit(item);
        const list = item.data !== undefined ? item.data : [];
        for (let i = 0; i < list.length; i++) {
            walk(list[i], visit, skipHeadings);
        }
    }
    function find(test) {
        let found = null;
        walk(widget.fullRepresentationItem, it => { if (!found && test(it)) found = it; });
        return found;
    }
    function openMenuOf(text) {
        const row = find(it => it.taskText === text && it.listName !== undefined);
        let menu = null;
        walk(row, it => { if (!menu && it.openAt !== undefined) menu = it; }, true);
        if (menu) {
            menu.openAt(row, Qt.point(row.width - 12, 22));
        }
    }

    Timer {
        interval: 7000
        running: true
        onTriggered: {
            Plasmoid.configuration.foldedGroups = JSON.stringify(["Mobile app", "API"]);
            Plasmoid.configuration.queueCollapsed = false;
            Plasmoid.configuration.dailyCollapsed = true;
            // The reminder shows by itself near the tray, without the popup
            if (scenario === "reminder") {
                widget.showReminder();
                return;
            }
            widget.expanded = true;
            later.start();
        }
    }
    Timer {
        id: later
        interval: 1500
        onTriggered: {
            if (scenario === "search") {
                widget.fullRepresentationItem.openSearch();
                const field = find(it => it.placeholderText !== undefined && String(it.placeholderText).indexOf("Search") === 0);
                field.text = "search";
            } else if (scenario === "menu") {
                openMenuOf("Fix coupon validation at **checkout**");
            } else if (scenario === "settings") {
                Plasmoid.internalAction("configure").trigger();
            }
        }
    }
}
