import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

CoverBackground {
    readonly property var editor: appWindow.editorPage

    Column {
        y: appWindow.coverTopPadding
        width: parent.width
        spacing: Theme.paddingSmall

        PrimaryCoverLabel {
            text: qsTr("Active project")
        }

        SecondaryCoverLabel {
            text: editor.origAudioFilePath
            truncationMode: TruncationMode.Fade
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
        }

        PrimaryCoverLabel {
            text: qsTr("Actions applied")
        }

        SecondaryCoverLabel {
            text: editor.undoNr
        }
    }
}
