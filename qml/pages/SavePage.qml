import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4


Page {
    id: page
    allowedOrientations: Orientation.Portrait //All

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

    // variables for tags
    property var tagTitle : ""
    property var tagArtist : ""
    property var tagAlbum : ""
    property var tagDate : ""
    property var tagTrack : ""


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

    Python {
        id: py

        Component.onCompleted: {
            // Which Pythonfile will be used?
            importModule('audiox', function () {});

            // Handlers = Signals to do something in QML whith received Infos from pyotherside.send
            setHandler('tempFilesDeleted', function(i) {
                //console.log("temp files deleted: " + i)
            });
            setHandler('fileIsSaved', function() {
                idSaveButtonRunningIndicator.running = false
                idSaveButton.enabled = true
                pageStack.pop()
            });
            setHandler('debugPythonLogs', function(i) {
                console.log(i)
            });
            setHandler('estimatedFileSize', function(estimatedSize) {
                estimatedFileSize = Math.round ( (parseInt(estimatedSize)/1000) * 100) / 100
            });
            setHandler('audioTags', function(title, artist, album, date, track) {
                console.log(title, artist, album, date, track)
                tagTitle = title
                tagArtist = artist
                tagAlbum = album
                tagDate = date
                tagTrack = track
            });
        }

        // file operations
        function saveFunction() {
            tagTitle = idTagtextTitle.text
            tagArtist = idTagtextArtist.text
            tagAlbum = idTagtextAlbum.text
            tagDate = idTagtextDate.text
            tagTrack = idTagtextTrack.text
            var folderSavePath
            if (idComboBoxTargetFolder.currentIndex === 0) {
                folderSavePath = origAudioFolderPath
            }
            else if (idComboBoxTargetFolder.currentIndex === 1) {
                folderSavePath = homeDirectory + "/Music" + "/Audioworks/"
            }
            else if (idComboBoxTargetFolder.currentIndex === 2) {
                folderSavePath = homeDirectory + "/Music/"
            }
            else if (idComboBoxTargetFolder.currentIndex === 3) {
                folderSavePath = homeDirectory + "/Downloads/"
            }
            else if (idComboBoxTargetFolder.currentIndex === 4) {
                folderSavePath = homeDirectory + "/"
            }
            var newFileName = idFilenameNew.text.toString()
            var newFileType = idComboBoxFileExtension.value.toString().substring(1)
            var mp3Bitrate = "128"
            var mp3CompressBitrateType = "-V2" // abr = average variable bitrate // vbr = true variable bitrate
            savePath = folderSavePath + newFileName + idComboBoxFileExtension.value.toString()
            inputPathPy = ( "/" + inputPathPy.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"") )
            
            var args = [
                        inputPathPy,
                        savePath,
                        tempAudioFolderPath,
                        tempAudioType,
                        newFileName,
                        newFileType,
                        mp3Bitrate,
                        mp3CompressBitrateType,
                        tagTitle,
                        tagArtist,
                        tagAlbum,
                        tagDate,
                        tagTrack
                      ]
            
            call("audiox.saveFile", args)
        }
        function getFileSizeFunction() {
            var path = origAudioFilePath.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            var sizeInputPathPy = decodeURIComponent(path)
            call("audiox.getFileSizeFunction", [ sizeInputPathPy ])
        }
        function getAudioTagsFunction() {
            var path = origAudioFilePath.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            var sizeInputPathPy = decodeURIComponent(path)
            call("audiox.getAudioTagsFunction", [ sizeInputPathPy ])
        }

        onError: {
            // when an exception is raised, this error handler will be called
            console.log('python error: ' + traceback);
        }
    } // end Python


    SilicaFlickable {
        id: listView

        anchors.fill: parent
        contentHeight: columnSaveAs.height

        VerticalScrollDecorator { }

        Column {
            id: columnSaveAs

            width: page.width

            PageHeader {
                title:  qsTr("Save as")
            }

            Row {
                width: parent.width

                TextField {
                    id: idFilenameNew

                    label: (validatorNameOverwrite === true) ? qsTr("overwrite...") : ""
                    width: parent.width / 6 * 3.75
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    y: Theme.paddingSmall
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

                    width: parent.width / 6 * 1.25

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

                IconButton {
                    id: idSaveButton

                    visible: idFilenameNew.text.length > 0
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    
                    icon {
                        source: "../symbols/icon-m-apply.svg"
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium
                    }

                    onClicked: {
                        idSaveButtonRunningIndicator.running = true
                        idSaveButton.enabled = false
                         py.saveFunction()
                    }

                    BusyIndicator {
                        id: idSaveButtonRunningIndicator

                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }

                        size: BusyIndicatorSize.Medium
                    }
                }
            } // end row save filename

            ComboBox {
                id: idComboBoxTargetFolder

                width: parent.width

                menu: ContextMenu {
                    id: idCropShape
                    MenuItem {
                        text: qsTr("Original Folder")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Music/Audioworks"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Music"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "Downloads"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: "/home"
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                onCurrentItemChanged: checkOverwriting()
            }

            Label {
                x: Theme.paddingLarge * 1.2
                width: parent.width - 2*Theme.paddingLarge
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("Source file: %1\nPath: %2\nSize: %2 kb")
                      .arg(origAudioFileName)
                      .arg(origAudioFolderPath)
                      .arg(estimatedFileSize)
            }

            Item {
                width: parent.width
                height: 2*Theme.paddingLarge
            }

            SectionHeader {
                text: qsTr("Audio tags") + "\n"
                visible: idComboBoxFileExtension.currentIndex !== 0
            }

            Grid {
                width: parent.width
                visible: idComboBoxFileExtension.currentIndex !== 0
                columns: 1

                TextField {
                    id: idTagtextTitle

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagTitle

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }

                    EnterKey.onClicked: idTagtextTitle.focus = false
                    
                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("Title")
                    }
                }

                TextField {
                    id: idTagtextArtist

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagArtist

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }

                    EnterKey.onClicked: idTagtextArtist.focus = false

                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("Artist")
                    }
                }

                TextField {
                    id: idTagtextAlbum

                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText
                    text: tagAlbum

                    validator: RegExpValidator {
                        // negative list
                        regExp: /^[^<>'\"/;*:`#?]*$/
                    }
                    
                    EnterKey.onClicked: idTagtextAlbum.focus = false

                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("Album")
                    }
                }

            }

            Grid {
                width: parent.width
                visible: idComboBoxFileExtension.currentIndex !== 0
                columns: 2

                TextField {
                    id: idTagtextTrack

                    width: parent.width / 2
                    inputMethodHints: Qt.ImhDigitsOnly
                    text: tagTrack
                    
                    validator: IntValidator {
                        bottom: 1
                        top: 255
                    }

                    EnterKey.onClicked: idTagtextTrack.focus = false
                    
                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("Track#")
                    }
                }

                TextField {
                    id: idTagtextDate

                    width: parent.width / 2
                    inputMethodHints: Qt.ImhDigitsOnly
                    text: tagDate

                    validator: IntValidator {
                        bottom: 1
                        top: 9999
                    }

                    EnterKey.onClicked: idTagtextDate.focus = false
                    
                    Label {
                        anchors.top: parent.bottom
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        text: qsTr("Year")
                    }
                }
            }
        } // end Column
    } // end Silica Flickable

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
}
