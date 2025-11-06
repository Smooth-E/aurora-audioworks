import QtQuick 2.0
import Sailfish.Silica 1.0

CoverTemplate {
    secondaryText: qsTr("Welcome to Audioworks!")
    description: qsTr("Open a file and start editing")

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-new"

            onTriggered: appWindow.editorPage.openFilePickerFromCover()
        }
    }
}
