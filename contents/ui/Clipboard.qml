import QtQuick

// QML has no clipboard API; a hidden TextEdit is the usual workaround.
TextEdit {
    id: helper

    visible: false
    textFormat: TextEdit.PlainText

    function put(value) {
        helper.text = value;
        helper.selectAll();
        helper.copy();
        helper.text = "";
    }
}
