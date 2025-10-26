import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

import "../components"
import "../py"

Dialog {
    id: saveDialog
    allowedOrientations: Orientation.All

    // values transmitted from FirstPage.qml
    property string homeDirectory
    property string origAudioFilePath
    property string origAudioFileName
    property string origAudioFolderPath
    property string origAudioName
    property string origAudioType
    property var tempAudioFolderPath
    property var tempAudioType
    property var inputPathPy
    property bool warningNoLAME

    // variables for saving
    property var savePath
    property var estimatedFileSize
    property bool validatorNameOverwrite : false
    property var estimatedFolder

    property bool saveComplete

    // variables for tags
    property var tagTitle : ""
    property var tagArtist : ""
    property var tagAlbum : ""
    property var tagDate : ""
    property var tagTrack : ""

    function checkOverwriting() {
        if (idComboBoxTargetFolder.currentIndex === 0) {
            estimatedFolder = origAudioFolderPath
        }
        else if (idComboBoxTargetFolder.currentIndex === 1) {
            estimatedFolder = homeDirectory + "/Music" + "/Audioworks/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 2) {
            estimatedFolder = homeDirectory + "/Music/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 3) {
            estimatedFolder = homeDirectory + "/Downloads/"
        }
        else if (idComboBoxTargetFolder.currentIndex === 4) {
            estimatedFolder = homeDirectory + "/"
        }

        validatorNameOverwrite = estimatedFolder === origAudioFolderPath
                                 && origAudioName === idFilenameNew.text
                                 && ("." + origAudioType) === idComboBoxFileExtension.value.toString()
    }

    canAccept: idFilenameNew.text.length > 0
    acceptDestination: busyPageComponent

    onAccepted: py.saveFunction()

    SaveDialogPython {
        id: py
    }

    DialogHeader {
        id: header

        acceptText: qsTr("Save")
    }

    SilicaFlickable {
        id: listView

        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right 
        }

        contentHeight: columnSaveAs.height

        VerticalScrollDecorator { }

        Column {
            id: columnSaveAs

            width: parent.width
            spacing: Theme.paddingSmall

            SectionHeader {
                text: qsTr("Destination")
                horizontalAlignment: Text.AlignLeft
            }

            Row {
                width: parent.width

                TextField {
                    id: idFilenameNew

                    width: parent.width - idComboBoxFileExtension.width - Theme.paddingMedium
                    label: validatorNameOverwrite === true ? qsTr("overwrite...") : ""
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: origAudioName + "_edit"

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }

                    EnterKey.onClicked: idFilenameNew.focus = false
                    
                    onTextChanged: checkOverwriting()
                }

                ComboBox {
                    id: idComboBoxFileExtension

                    width: Theme.dp(128)

                    menu: ContextMenu {
                        MenuItem {
                            text: ".wav"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".flac"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: ".ogg"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: warningNoLAME === false
                            text: ".mp3"
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            } // end row save filename

            ComboBox {
                id: idComboBoxTargetFolder

                width: parent.width
                label: qsTr("Destination folder")

                menu: ContextMenu {
                    id: idCropShape

                    MenuItem {
                        text: qsTr("Original Folder")
                    }
                    MenuItem {
                        text: "Music/Audioworks"
                    }
                    MenuItem {
                        text: "Music"
                    }
                    MenuItem {
                        text: "Downloads"
                    }
                    MenuItem {
                        text: "/home"
                    }
                }

                onCurrentItemChanged: checkOverwriting()
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - x * 2

                Item {
                    width: 1
                    height: Theme.paddingMedium
                }

                Label {
                    width: parent.width
                    text: qsTr("Output file information")
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    opacity: Theme.opacityOverlay
                    text: qsTr("Source file: %1").arg(origAudioFileName)
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    opacity: Theme.opacityOverlay
                    text: qsTr("Path: %1").arg(origAudioFolderPath)
                    truncationMode: TruncationMode.Fade
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    opacity: Theme.opacityOverlay
                    text: qsTr("Estimated output size: %1kb").arg(estimatedFileSize)
                    truncationMode: TruncationMode.Fade
                }

                Item {
                    width: 1
                    height: Theme.paddingMedium
                }
            }

            Column {
                width: parent.width
                opacity: idComboBoxFileExtension.currentIndex !== 0 ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    FadeAnimator { }
                }

                SectionHeader {
                    text: qsTr("Audio tags")
                    horizontalAlignment: Text.AlignLeft
                }

                TextField {
                    id: idTagtextTitle

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagTitle
                    description: qsTr("Title")

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }

                    EnterKey.onClicked: idTagtextTitle.focus = false
                }

                TextField {
                    id: idTagtextArtist

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagArtist
                    description: qsTr("Artist")

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }

                    EnterKey.onClicked: idTagtextArtist.focus = false
                }

                TextField {
                    id: idTagtextAlbum

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagAlbum
                    description: qsTr("Album")

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }
                    
                    EnterKey.onClicked: idTagtextAlbum.focus = false
                }

                Row {
                    width: parent.width

                    TextField {
                        id: idTagtextTrack

                        width: parent.width / 2
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: tagTrack
                        description: qsTr("Track#")
                        
                        validator: IntValidator {
                            bottom: 1
                            top: 255
                        }

                        EnterKey.onClicked: idTagtextTrack.focus = false
                    }

                    TextField {
                        id: idTagtextDate

                        width: parent.width / 2
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: tagDate
                        description: qsTr("Year")

                        validator: IntValidator {
                            bottom: 1
                            top: 9999
                        }

                        EnterKey.onClicked: idTagtextDate.focus = false
                    }
                }
            }
        } // end Column
    } // end Silica Flickable

    Component {
        id: busyPageComponent

        Page {
            function closeIfCompleted() {
                if (status === PageStatus.Active && saveDialog.saveComplete) {
                    pageStack.pop(pageStack.find(function(page) { return page.isMainPage }))
                }
            }

            backNavigation: false

            onStatusChanged: closeIfCompleted()

            Connections {
                target: saveDialog

                onSaveCompleteChanged: closeIfCompleted()
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Theme.paddingLarge

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: true
                    size: BusyIndicatorSize.Large
                }

                Label {
                    width: parent.width
                    text: qsTr("Saving...")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                }
            }
        }
    }

    // autostart functions
    Component.onCompleted: {
        // get infos from the original file
        if (origAudioType.indexOf('wav') !== -1 ) {
            idComboBoxFileExtension.currentIndex = 0
        }
        else if (origAudioType.indexOf('flac') !== -1) {
            idComboBoxFileExtension.currentIndex = 1
        }
        else if (origAudioType.indexOf('ogg') !== -1) {
            idComboBoxFileExtension.currentIndex = 2
        }
        else if ( (origAudioType.indexOf('mp3') !== -1) && (warningNoLAME === false) ) {
            idComboBoxFileExtension.currentIndex = 3
        }
        else {
            idComboBoxFileExtension.currentIndex = 0
        }
        py.getFileSizeFunction()

        const mayHaveTags = origAudioType.indexOf('mp3') !== -1
                            || origAudioType.indexOf('ogg') !== -1
                            || origAudioType.indexOf('flac') !== -1
        if (mayHaveTags) {
            py.getAudioTagsFunction()
        }
    }
}
