import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid

// Added to main.qml of a throw-away copy by take.sh; never part of the package.
// Puts the widget in the state of one screenshot scenario, then renders its
// window into a PNG itself (no screen capture) and quits.
Item {
    id: driver

    required property var widget
    readonly property string scenario: "@SCENARIO@"
    readonly property string outFile: "@OUT@"
    readonly property int shotWidth: @WIDTH@
    readonly property int shotHeight: @HEIGHT@

    // The open context menu, if any (it lives in the window's popup layer,
    // so it is rendered on its own and laid over the popup by take.sh)
    property var openMenu: null

    // Size the popup, show the usual file path in the footer (all writes to
    // the demo file are done by now), then render a moment later
    function capture() {
        const full = widget.fullRepresentationItem;
        const win = full.Window.window;
        if (win) {
            win.width = shotWidth;
            win.height = shotHeight;
        }
        full.width = shotWidth;
        full.height = shotHeight;
        widget.filePath = "~/Documents/todo.md";
        grabTimer.start();
    }

    Timer {
        id: grabTimer
        interval: 600
        onTriggered: driver.grab()
    }

    function grab() {
        const full = widget.fullRepresentationItem;
        full.grabToImage(result => {
            result.saveToFile(outFile);
            if (!openMenu) {
                Qt.quit();
                return;
            }
            const box = openMenu.background;
            const at = box.mapToItem(full, 0, 0);
            box.parent.grabToImage(menuShot => {
                menuShot.saveToFile(outFile.replace(/\.png$/, ".menu.png"));
                const p = box.parent.mapToItem(full, 0, 0);
                console.log("FULL_SIZE " + full.width + " " + full.height);
            console.log("MENU_AT " + Math.round(p.x) + " " + Math.round(p.y));
                Qt.quit();
            });
        });
    }

    // Every Item and non-visual object (menus are Popups) under `item`;
    // a group heading (it has startRename) is skipped when `skipHeadings` is set
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

    function rowOf(text) {
        let found = null;
        walk(widget.fullRepresentationItem, it => {
            if (!found && it.taskText === text && it.listName !== undefined) {
                found = it;
            }
        });
        return found;
    }

    function openMenuOf(text) {
        const row = rowOf(text);
        let menu = null;
        walk(row, it => {
            if (!menu && it.openAt !== undefined) {
                menu = it;
            }
        }, true);
        if (menu) {
            menu.openAt(row, Qt.point(row.width - 12, 22));
            openMenu = menu;
        }
    }

    function folds(groups, queueOpen, dailyOpen) {
        Plasmoid.configuration.foldedGroups = JSON.stringify(groups);
        Plasmoid.configuration.queueCollapsed = !queueOpen;
        Plasmoid.configuration.dailyCollapsed = !dailyOpen;
    }

    Component.onCompleted: {
        const win = driver.Window.window;
        if (win) {
            win.width = shotWidth;
            win.height = shotHeight;
        }
        switch (scenario) {
        case "overview":
        case "overview-light":
            folds(["Mobile app", "Infrastructure"], true, false);
            break;
        case "groups":
            folds(["Webshop", "API", "Mobile app", "Infrastructure"], true, true);
            break;
        case "menu":
            folds(["Webshop", "Mobile app", "Infrastructure"], true, false);
            break;
        default:
            folds(["Webshop", "API", "Mobile app", "Infrastructure"], true, false);
        }
    }

    // The toast lasts 5 s, so it is started late enough to be on screen at capture
    Timer {
        interval: driver.scenario === "toast" ? 5000 : 2500
        running: true
        onTriggered: {
            switch (driver.scenario) {
            case "menu":
                driver.openMenuOf("Add rate limiting to the search endpoint");
                break;
            case "toast":
                driver.widget.addTask("Prepare the sprint demo", false);
                break;
            case "groups":
                driver.widget.addGroup = "API";
                break;
            }
        }
    }

    // Long enough for the action above and its animation to settle
    Timer {
        interval: driver.scenario === "toast" ? 6500 : 4500
        running: true
        onTriggered: driver.capture()
    }
}
