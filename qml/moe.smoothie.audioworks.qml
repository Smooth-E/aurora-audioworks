import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0 // File-Loader
import QtMultimedia 5.0 // Audio Support
import io.thp.pyotherside 1.4

import "pages"

ApplicationWindow
{
    id: appWindow

    readonly property bool isLandscape: orientation === Orientation.Landscape
                                        || orientation === Orientation.LandscapeInverted

    readonly property real coverTopPadding: isLandscape ? Theme.paddingLarge : Theme.paddingMedium

    property var editorPage
    property bool showEditorCover: editorPage && editorPage.showTools

    initialPage: Qt.resolvedUrl("pages/FirstPage.qml")
    allowedOrientations: defaultAllowedOrientations
    cover: Qt.resolvedUrl(showEditorCover ? "cover/EditorCover.qml" : "cover/WelcomeCover.qml")
}
