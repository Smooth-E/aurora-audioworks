import QtQuick 2.0
import Sailfish.Silica 1.0
import Aurora.Controls 1.0
import Sailfish.Pickers 1.0 // File-Loader
import QtMultimedia 5.0 // Audio Support
import "../py"

Page {
    id: mainPage
    allowedOrientations: Orientation.All

    readonly property bool isMainPage: true

    property bool debug : false

    // file variables

    readonly property var inputPathPyRegexp: /^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/
    property string inputPathPy: decodeURIComponent("/" + idAudioPlayer.source.toString().replace(inputPathPyRegexp,""))
    property string saveAudioFolderPath
    property string symbolSourceFolder : "/usr/share/moe.smoothie.audioworks/qml/symbols/"
    property string lastTmpAudio2delete
    property string lastTmpImage2delete
    property string origAudioFilePath
    property string origAudioFileName
    property string origAudioFolderPath
    property string origAudioName
    property string origAudioType
    property string homeDirectory
    property string tempAudioFolderPath: StandardPaths.home + '/.cache/de.poetaster/harbour-audiocut'
    property string tempAudioType : "wav"
    property string outputPathPy

    // UI variables
    
    property bool warningNoPydub : false
    property bool warningNoLAME : false
    property int undoNr: 0
    property bool finishedLoading : true
    property bool showTools : false
    property var handleSize : Theme.paddingLarge
    property var zoomAreaFactor : 5
    property bool audioPlaying : false

    //ms, timerintervall depending on system
    property var minIntervallSpeedSystem : 50
    
    //factor, by which the marker will jump if millisecondsPerPixelPython < minIntervallSpeedSystem
    property var minIntervallPxFaktor
    
    property var clipboardAvailable : false
    property bool hideMarkersPaste: buttonCopyPaste.down && idComboBoxToolsCopyPaste.currentIndex != 0
    property bool markersDiffExists: (toPosMillisecond - fromPosMillisecond) > 0

    // Audio variables

    // careful: QML multimedia calculates audio duration different than Python and
    // changes during playback -> correction factor for playback
    property var millisecondsPerPixelPython : 0
    property var millisecondsPerPixelQML : idAudioPlayer.duration / (idWaveformOverview.width * zoomAreaFactor)
    property var correctionFactorMsPx : millisecondsPerPixelPython / millisecondsPerPixelQML

    property var audioLengthSecondsPython : 0
    property var manualPixelstamp : Math.round( Math.abs(idImageWaveformZoom.x) + idMarkerAB.x + handleSize/2 )
    property var manualNowStamp : manualPixelstamp * millisecondsPerPixelPython
    property var fromPosPixel : 0
    property var toPosPixel : 0
    property var fromPosMillisecond : Math.round(fromPosPixel * millisecondsPerPixelPython)
    property var toPosMillisecond : Math.round(toPosPixel * millisecondsPerPixelPython)

    function openFilePickerFromCover() {
        idAudioPlayer.stop()
        pageStack.pop(mainPage, PageStackAction.Immediate)
        pageStack.push(filePickerPage, { }, PageStackAction.Immediate)
        appWindow.activate()
    }

    function openFilePicker() {
        idAudioPlayer.stop()
        pageStack.push(filePickerPage)
    }

    function openAboutPage() {
        idAudioPlayer.stop()
        pageStack.push(Qt.resolvedUrl("About.qml"))
    }

    function preparePathAndUndo() {
        idAudioPlayer.stop()
        finishedLoading = false
        idImageWaveform.source = ""
        idImageWaveformZoom.source = ""
        undoNr = undoNr + 1
        outputPathPy = tempAudioFolderPath + "audio" + ".tmp" + undoNr + "." + tempAudioType
        stopPlayingResetWaveform()
    }

    function autostart_getAudiolengthQML(pathTo) {
        console.log("autostart_getAudiolengthQML: " + pathTo)
        idAudioPlayer.volume = 0
        idAudioPlayer.source = pathTo
        idAudioPlayer.play()
        idTimerPreloadAudioOnce.running = true
    }

    function calculatePlayerPixelSpeed() {
        if (millisecondsPerPixelPython < minIntervallSpeedSystem) {
            idTimerPlay.interval = minIntervallSpeedSystem
            minIntervallPxFaktor = minIntervallSpeedSystem / millisecondsPerPixelPython
        }
        else {
            idTimerPlay.interval = millisecondsPerPixelPython
            minIntervallPxFaktor = 1
        }
    }

    function stopPlayingResetWaveform() {
        idAudioPlayer.stop()
        audioPlaying = false
        idMarkerRegion.x = 0
        idMarkerAB.x = -handleSize/2
        idImageWaveformZoom.x = 0
        idMarkerPosText.reanchorToLeft()
    }

    function clearMarkerPos() {
        console.log("ToDo")
    }

    function undoBackwards() {
        idAudioPlayer.stop()
        finishedLoading = false
        undoNr = undoNr - 1

        const regexp = /^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/
        lastTmpAudio2delete = decodeURIComponent("/" + idAudioPlayer.source.toString().replace(regexp, ""))
        lastTmpImage2delete = decodeURIComponent("/" + idImageWaveform.source.toString().replace(regexp, ""))
        
        if (undoNr <= 0) {
            undoNr = 0
            idAudioPlayer.source = encodeURI(origAudioFilePath)
        }
        else {
            idAudioPlayer.source = idAudioPlayer.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        }

        idImageWaveform.source = idImageWaveform.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))
        idImageWaveformZoom.source = idImageWaveformZoom.source.toString().replace(".tmp"+(undoNr+1), ".tmp"+(undoNr))

        py.getAudioLengthPy()
        py.deleteLastTMPFunction()

        stopPlayingResetWaveform()
    }

    Component.onCompleted: {
        appWindow.editorPage = mainPage

        if(debug) {
            console.debug(tempAudioFolderPath)
        }

        py.getHomePath()
    }

    Timer {
        id: idTimerPlay

        running: false
        repeat: true
        //interval: ?? defined by audio file length and screen pixel, (not possible for intervals < 20ms !!!)

        onTriggered: {
            // case A = move only slider in zoom window (idMarkerAB)
            if (idMarkerAB.x + handleSize/2 < idWaveformZoom.width/2 
                || idMarkerRegion.x + idMarkerRegion.width >= idWaveformOverview.width) {
                if ( ((idMarkerAB.x + handleSize/2)+ ( 1 * minIntervallPxFaktor )) <= idWaveformZoom.width ) {
                    idMarkerAB.x = idMarkerAB.x + ( 1 * minIntervallPxFaktor )
                }

                if ( (idMarkerAB.x + handleSize/2 > (idWaveformOverview.width/2 + Theme.paddingLarge * 1.5 ) ) ) {
                    idMarkerPosText.reanchorToRight()
                }
            }
            // case B = move both at the same time
            else {
                if ( (idMarkerRegion.x + ( 1 / zoomAreaFactor * minIntervallPxFaktor )) <= idWaveformOverview.width ) {
                    idMarkerRegion.x = idMarkerRegion.x + ( 1 / zoomAreaFactor * minIntervallPxFaktor )
                }
                idImageWaveformZoom.x = idImageWaveformZoom.x - ( 1 * minIntervallPxFaktor )
            }
        }
    }

    Timer {
        id: idTimerPreloadAudioOnce

        interval: 1000
        running: false
        repeat: false
        
        onTriggered: {
            idAudioPlayer.stop()
            idAudioPlayer.volume = 1.0
        }
    }

    Component {
       id: filePickerPage

       FilePickerPage {
           title: qsTr("Select audio file")
           nameFilters: [ '*.wav', '*.mp3', '*.flac', '*.ogg', '*.aac', '*.mp4' ]

           onSelectedContentPropertiesChanged: {
               origAudioFilePath = selectedContentProperties.filePath.toString()
               origAudioFileName = selectedContentProperties.fileName
               origAudioFolderPath = origAudioFilePath.replace(selectedContentProperties.fileName, "")
               var origAudioFileNameArray = origAudioFileName.split(".")
               origAudioName = (origAudioFileNameArray.slice(0, origAudioFileNameArray.length-1)).join(".")
               origAudioType = origAudioFileNameArray[origAudioFileNameArray.length - 1]
               autostart_getAudiolengthQML( origAudioFilePath )
               py.deleteAllTMPFunction()
               py.createWaveformImage()
               undoNr = 0
               stopPlayingResetWaveform()
               clearMarkerPos()
           }
       }
    }

    Audio {
        id: idAudioPlayer

        onStopped: {
            idTimerPlay.running = false
            audioPlaying = false
        }
    }

    RemorsePopup {
        id: remorse
    }

    EditorPython {
        id: py
    }

    AppBar {
        id: appBar

        headerText: qsTr("Audioworks")
        subHeaderText: origAudioFilePath

        AppBarSpacer { }

        AppBarButton {
            visible: showTools
            icon.source: "image://theme/icon-splus-save"

            onClicked: {
                idAudioPlayer.stop()

                const props = {
                    homeDirectory: homeDirectory,
                    origAudioFilePath: origAudioFilePath,
                    origAudioFileName: origAudioFileName,
                    origAudioFolderPath: origAudioFolderPath,
                    origAudioName: origAudioName,
                    origAudioType: origAudioType,
                    tempAudioFolderPath: tempAudioFolderPath,
                    tempAudioType: tempAudioType,
                    warningNoLAME: warningNoLAME,
                    inputPathPy: idAudioPlayer.source.toString()
                }
                pageStack.push(Qt.resolvedUrl("SaveDialog.qml"), props)
            }
        }

        AppBarButton {
            visible: showTools
            enabled: undoNr >= 1 && finishedLoading
            
            icon {
                source: "../symbols/icon-undo.svg"
                color: Theme.primaryColor
            }

            onClicked: undoBackwards()
        }

        AppBarButton {
            visible: !showTools
            icon.source: "image://theme/icon-splus-file-draft"

            onClicked: openFilePicker()
        }

        AppBarButton {
            visible: !showTools
            icon.source: "image://theme/icon-splus-about"

            onClicked: openAboutPage()
        }

        AppBarButton {
            visible: showTools
            icon.source: "image://theme/icon-splus-more"

            onClicked: popup.open()

            PopupMenu {
                id: popup
                
                PopupMenuItem {
                    icon.source: "image://theme/icon-splus-file-draft"
                    text: qsTr("Open file")

                    onClicked: openFilePicker()
                }

                PopupMenuItem {
                    icon.source: "image://theme/icon-splus-about"
                    text: qsTr("About")

                    onClicked: openAboutPage()
                }
            }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.horizontalPageMargin * 2
        width: parent.width - x * 2
        spacing: Theme.paddingMedium
        opacity: finishedLoading && !showTools ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            FadeAnimator { }
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Welcome to Audioworks!")
            font.pixelSize: Theme.fontSizeHuge
            color: Theme.highlightColor
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: qsTr("Tap the button above to open a file and start editing")
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            opacity: Theme.opacityOverlay
        }
    }

    Item {
        anchors {
            top: appBar.bottom
            bottom: parent.bottom
        }

        width: parent.width
        opacity: finishedLoading ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            FadeAnimator { }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: true
            size: BusyIndicatorSize.Large
        }
    }

    SilicaFlickable {
        anchors {
            top: appBar.bottom
            bottom: parent.bottom
        }

        width: parent.width
        contentHeight: column.height
        opacity: showTools && finishedLoading ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            FadeAnimator { }
        }

        Column {
            id: column

            width: parent.width

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Row {
                id: idTimeInfoRow

                x: Theme.horizontalPageMargin
                width: parent.width - x * 2

                Label {
                    width: parent.width / 5
                    anchors.baseline: idCurrentPosition.baseline
                    horizontalAlignment: Text.AlignLeft
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeTiny
                    text: "00:00:00"
                }

                Label {
                    id: idCurrentPosition

                    width: parent.width / 5 * 3
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.secondaryHighlightColor

                    text: {
                        if (!showTools) {
                            return "none"
                        }

                        const date = new Date(idAudioPlayer.position * correctionFactorMsPx).toISOString().substr(11, 8)
                        return  "< " + date + " >"
                    }
                }

                Label {
                    id: idAudioDurationLabel

                    width: parent.width / 5
                    anchors.baseline: idCurrentPosition.baseline
                    horizontalAlignment: Text.AlignRight
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeTiny

                    //take only digits 11...23 from iso string, which is the time without date infos
                    text: new Date(audioLengthSecondsPython * 1000).toISOString().substr(11, 8)
                }
            } // end idTimeInfoRow

            Item {
                id: idWaveformOverview

                x: Theme.horizontalPageMargin
                width: parent.width - x * 2
                height: Theme.itemSizeLarge

                Image {
                    id: idImageWaveform

                    height: parent.height
                    width: parent.width
                    cache: false
                    fillMode: Image.PreserveAspectFit

                    Rectangle {
                        id: idFromTillRegionOverview

                        visible: buttonEffects.down === false && buttonFile.down === false && hideMarkersPaste === false
                        x: fromPosPixel / zoomAreaFactor
                        width: (toPosPixel - fromPosPixel) / zoomAreaFactor
                        height: parent.height / 8
                        z: -5
                        color: Theme.errorColor
                        opacity: 0.5
                    }
                }

                Rectangle {
                    id: idMarkerRegion

                    x: 0
                    y: 0
                    z: -1
                    width: parent.width / zoomAreaFactor
                    height: parent.height
                    color: Theme.highlightColor
                    opacity: 0.25

                    MouseArea {
                        id: dragMarkerRegion

                        preventStealing: true
                        anchors.fill: parent

                        drag{
                            target: parent
                            axis: Drag.XAxis
                            minimumX: 0
                            maximumX: idWaveformOverview.width - parent.width
                        }

                        onMouseXChanged: idImageWaveformZoom.x = - (parent.x * zoomAreaFactor)

                        onEntered: {
                            idAudioPlayer.pause()
                            idTimerPlay.running = false
                        }

                        onReleased: {
                            if (audioPlaying === true) {
                                var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx)
                                idAudioPlayer.seek(playFromMillisecond)
                                idAudioPlayer.play()
                                idTimerPlay.running = true
                            }
                        }
                    }
                }
            } // end idWaveformOverview

            Item {
                id: idWaveformZoom

                x: Theme.horizontalPageMargin
                width: parent.width - x * 2
                height: Theme.itemSizeLarge

                Rectangle {
                    id: idBackgroundFillerZoom

                    anchors.fill: parent
                    color: Theme.highlightColor
                    opacity: 0.25
                    z: -1
                }

                Item {
                    width: parent.width
                    height: Theme.itemSizeLarge
                    clip: true

                    Image {
                        id: idImageWaveformZoom

                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        cache: false

                        Rectangle {
                            id: idFromTillRegionZoom

                            visible: buttonEffects.down === false && buttonFile.down === false
                                     && hideMarkersPaste === false

                            x: fromPosPixel
                            width: (toPosPixel - fromPosPixel)
                            height: parent.height
                            z: -5
                            color: Theme.errorColor
                            opacity: 0.5
                        }
                    }
                 }

                Rectangle {
                    id: idMarkerAB

                    x: -handleSize/2
                    width: handleSize
                    height: parent.height
                    color: "transparent"

                    Rectangle {
                        width: 1
                        height: idBackgroundFillerZoom.height
                        anchors.centerIn: parent
                        color: Theme.primaryColor
                    }

                    Rectangle {
                        width: handleSize
                        height: handleSize
                        color: Theme.primaryColor
                        radius: handleSize
                        anchors.verticalCenter: parent.top
                    }

                    Rectangle {
                        width: handleSize
                        height: handleSize
                        color: Theme.primaryColor
                        radius: handleSize
                        anchors.verticalCenter: parent.bottom
                    }

                    MouseArea {
                        anchors {
                            fill: parent
                            leftMargin: -5 * Theme.paddingLarge
                            rightMargin: -5 * Theme.paddingLarge
                            topMargin: -Theme.paddingLarge
                            bottomMargin: -Theme.paddingLarge
                        }

                        preventStealing: true

                        drag {
                            target: parent
                            axis: Drag.XAxis
                            minimumX: -parent.width / 2
                            maximumX: idWaveformZoom.width - parent.width / 2
                        }

                        onEntered: {
                            idAudioPlayer.pause()
                            idTimerPlay.running = false
                        }

                        onReleased: {
                            if (audioPlaying === true) {
                                var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx)
                                idAudioPlayer.seek(playFromMillisecond)
                                idAudioPlayer.play()
                                idTimerPlay.running = true
                            }
                        }

                        onMouseXChanged: {
                            const waveFormWidth = idWaveformOverview.width / 2 + Theme.paddingLarge * 1.5
                            if (idMarkerAB.x + handleSize / 2 > waveFormWidth) {
                                idMarkerPosText.reanchorToRight()
                            }
                            else if (idMarkerAB.x + handleSize / 2 < waveFormWidth) {
                                idMarkerPosText.reanchorToLeft()
                            }
                        }
                    }

                    Label {
                        id: idMarkerPosText
                    
                        function reanchorToRight() {
                            anchors.left = undefined
                            anchors.leftMargin = undefined
                            anchors.right = parent.right
                            anchors.rightMargin = Theme.paddingSmall
                        }
                    
                        function reanchorToLeft() {
                            anchors.rightMargin = undefined
                            anchors.leftMargin = Theme.paddingSmall
                            anchors.right = undefined
                            anchors.left = parent.left
                        }

                        anchors {
                            top: parent.bottom
                            topMargin: Theme.paddingMedium
                            left : parent.left
                            leftMargin : Theme.paddingSmall
                        }

                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeTiny
                        text: new Date(manualNowStamp).toISOString().substr(11,12)
                    }
                }
            } // end idWaveformZoom

            Item {
                width: 1
                height: 3 * Theme.paddingLarge
            }

            Row {
                id: idPlayPauseMarkerRow

                visible: showTools === true
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                height: Theme.itemSizeLarge

                IconButton {
                    height: parent.height
                    width: parent.width / 5

                    icon.source : buttonEffects.down !== true && buttonFile.down !== true && hideMarkersPaste !== true
                                  ? "../symbols/icon-m-marker.svg"
                                  : ""
                    
                    icon.height: Theme.iconSizeMedium * 1.1
                    icon.width: Theme.iconSizeMedium * 1.1

                    onClicked: {
                        if ( fromPosPixel === 0 && toPosPixel === 0) {
                            fromPosPixel = manualPixelstamp
                            toPosPixel = manualPixelstamp
                        }
                        else {
                            var oldToPosPixel = toPosPixel
                            var oldFromPosPixel = fromPosPixel
                            fromPosPixel = manualPixelstamp
                            if (fromPosPixel > toPosPixel) {
                                fromPosPixel = oldToPosPixel
                                toPosPixel = manualPixelstamp
                            }
                        }
                    }

                    onPressAndHold: fromPosPixel = 0
                }

                Label {
                    width: parent.width/5
                    height: parent.height
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.errorColor
                    text: buttonEffects.down === true || buttonFile.down === true || hideMarkersPaste === true
                          ? ""
                          : new Date(fromPosMillisecond).toISOString().substr(11,12)
                }

                IconButton {
                    height: parent.height
                    width: parent.width / 5
                    icon.source: (audioPlaying === false) ? "image://theme/icon-m-play?" : "image://theme/icon-m-pause?"
                    icon.width: Theme.iconSizeLarge
                    icon.height: Theme.iconSizeLarge

                    onClicked: {
                        if (audioPlaying === false) {
                            var playFromMillisecond = Math.round(manualNowStamp / correctionFactorMsPx)
                            idAudioPlayer.seek(playFromMillisecond)
                            idAudioPlayer.play()
                            audioPlaying = true
                            idTimerPlay.running = true
                        }
                        else {
                            idAudioPlayer.pause()
                            audioPlaying = false
                            idTimerPlay.running = false
                        }
                    }

                    onPressAndHold: {
                        stopPlayingResetWaveform()
                        idTimerPlay.running = false
                    }
                }

                Label {
                    width: parent.width/5
                    height: parent.height
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.errorColor
                    text: buttonEffects.down === true || buttonFile.down === true || hideMarkersPaste === true 
                          ? ""
                          : new Date(toPosMillisecond).toISOString().substr(11,12)
                }

                IconButton {
                    height: parent.height
                    width: parent.width / 5
                    
                    icon.source : buttonEffects.down !== true && buttonFile.down !== true && hideMarkersPaste !== true
                                  ? "../symbols/icon-m-marker.svg"
                                  : ""
                    
                    icon.height: Theme.iconSizeMedium * 1.1
                    icon.width: Theme.iconSizeMedium * 1.1

                    onClicked: {
                        var oldToPosPixel = toPosPixel
                        var oldFromPosPixel = fromPosPixel
                        toPosPixel = manualPixelstamp
                        if (toPosPixel < fromPosPixel) {
                            toPosPixel = oldFromPosPixel
                            fromPosPixel = manualPixelstamp
                        }
                    }

                    onPressAndHold: toPosPixel = idImageWaveformZoom.sourceSize.width
                }

            } // end idPlayPauseMarkerRow

            Item {
                width: 1
                height: 2 * Theme.paddingLarge
            }

            Row {
                id: idToolsRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                IconButton {
                    id: buttonCut

                    icon.opacity: 1
                    down: true
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-cut.svg"
                    icon.width: Theme.iconSizeMedium * 1.1
                    icon.height: Theme.iconSizeMedium * 1.1

                    onClicked: {
                        buttonCut.down = true
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }

                IconButton {
                    id: buttonVolume

                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "image://theme/icon-m-speaker?"

                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = true
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }

                IconButton {
                    id: buttonSpeed

                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-speed.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium

                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = true
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = false
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }

                IconButton {
                    id: buttonCopyPaste

                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "image://theme/icon-m-clipboard?"
                    icon.width: Theme.iconSizeMedium * 1.35
                    icon.height: Theme.iconSizeMedium * 1.35

                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = true
                        buttonEffects.down = false
                        buttonFile.down = false
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }

                    Rectangle {
                        visible: (clipboardAvailable === true)
                        anchors.centerIn: parent
                        height: parent.height / 10
                        width: parent.width / 10
                        color: Theme.errorColor // primaryColor
                    }
                }

                IconButton {
                    id: buttonEffects

                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source : "../symbols/icon-m-effects.svg"
                    icon.width: Theme.iconSizeMedium
                    icon.height: Theme.iconSizeMedium

                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = true
                        buttonFile.down = false
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }

                IconButton {
                    id: buttonFile

                    icon.opacity: 1
                    down: false
                    width: parent.width / 6
                    height: Theme.itemSizeSmall
                    icon.source: "image://theme/icon-m-file-document-light?"

                    onClicked: {
                        buttonCut.down = false
                        buttonVolume.down = false
                        buttonSpeed.down = false
                        buttonCopyPaste.down = false
                        buttonEffects.down = false
                        buttonFile.down = true
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin:  Theme.paddingMedium
                        height: Theme.paddingSmall
                        width: parent.width
                        color: (parent.down === true) ? "transparent" : Theme.secondaryColor
                        border.color: Theme.secondaryColor
                    }
                }
            } // end ToolsRow

            Item {
                width: 1
                height: 2 * Theme.paddingLarge
            }

            Row {
                id: idSubmenuCut

                visible: buttonCut.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                ComboBox {
                    id: idComboBoxToolsCut
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("remove (trim marked)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("extract (trim unmarked)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("add silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsCut.currentIndex === 0) {
                            py.cutRemove()
                        }
                        if (idComboBoxToolsCut.currentIndex === 1) {
                            py.cutExtract()
                        }
                        if (idComboBoxToolsCut.currentIndex === 2) {
                            py.paddingSilence()
                        }
                    }
                }
            }

            ComboBox {
                id: idComboPadding

                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonCut.down && idComboBoxToolsCut.currentIndex === 2 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("at beginning")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("at end")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("at cursor")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            Slider {
                id: idSliderPaddingDuration
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonCut.down && idComboBoxToolsCut.currentIndex === 2 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 5
                smooth: true
                stepSize: 0.5
                minimumValue: 0.5
                maximumValue: 60

                Label {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }

                    text: parent.value + qsTr(" sec duration")
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }


            Row {
                id: idSubmenuVolume

                visible: buttonVolume.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                ComboBox {
                    id: idComboBoxToolsVolume
                    width: parent.width / 5 * 4
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("volume -/+")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("fade in")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("fade out")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
                    onClicked: {
                        if (idComboBoxToolsVolume.currentIndex === 0) {
                            py.volumeChange()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 1) {
                            py.volumeFadeIn()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 2) {
                            py.volumeFadeOut()
                        }
                        if (idComboBoxToolsVolume.currentIndex === 3) {
                            py.volumeSilence()
                        }
                    }
                }
            }

            Slider {
                id: idVolumeSlider

                enabled: ( finishedLoading === true && showTools === true )
                visible: (buttonVolume.down && idComboBoxToolsVolume.currentIndex === 0)
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 0
                smooth: true
                stepSize: 0.5
                minimumValue: -15
                maximumValue: +15

                Label {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }

                    text: parent.value > 0 ? "+" + parent.value + " " + qsTr(" dB") : parent.value + " " + qsTr(" dB")
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }


            Row {
                id: idSubmenuSpeed

                visible: buttonSpeed.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                ComboBox {
                    id: idComboBoxSpeedPitch

                    width: parent.width / 5 * 4

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("speed - ignore pitch")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("speed - keep pitch")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("reverse (backwards)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }

                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium

                    onClicked: {
                        if (idComboBoxSpeedPitch.currentIndex === 0) {
                            py.speedChange()
                        }
                        else if (idComboBoxSpeedPitch.currentIndex === 1) {
                            py.speedChange()
                        }
                        else if (idComboBoxSpeedPitch.currentIndex === 2) {
                            py.reverseAudio()
                        }
                    }
                }
            }

            Slider {
                id: idSpeedSlider

                enabled: finishedLoading === true && showTools === true
                visible: buttonSpeed.down && 
                         (idComboBoxSpeedPitch.currentIndex === 0 || idComboBoxSpeedPitch.currentIndex === 1)
                
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 1
                smooth: true
                stepSize: 0.05
                minimumValue: 0.5 //(idComboBoxSpeedPitch.currentIndex === 0) ? 0.5 : 1 // pydub can not keep pitch when slower than usual
                maximumValue: 2

                Label {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }

                    text: qsTr("x ") + parent.value
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }


            Row {
                id: idSubmenuCopyPaste

                visible: buttonCopyPaste.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                ComboBox {
                    id: idComboBoxToolsCopyPaste

                    width: parent.width / 5 * 4

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("copy")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (insert)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (replace)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            enabled: (clipboardAvailable === true)
                            text: qsTr("paste (overlay)")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }

                IconButton {
                    width: parent.width / 5
                    enabled: finishedLoading === true && showTools === true
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium

                    onClicked: {
                        if (idComboBoxToolsCopyPaste.currentIndex === 0) {
                            py.copyToClipboard()
                        }
                        else if (idComboBoxToolsCopyPaste.currentIndex === 1) {
                           py.pasteFromClipboard("add")
                        }
                        else if (idComboBoxToolsCopyPaste.currentIndex === 2) {
                           py.pasteFromClipboard("replace")
                        }
                        else if (idComboBoxToolsCopyPaste.currentIndex === 3) {
                           py.pasteFromClipboard("overlay")
                        }
                    }
                }
            }


            Row {
                id: idSubmenuEffects

                visible: buttonEffects.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                ComboBox {
                    id: idComboBoxToolsEffects

                    width: parent.width / 5 * 4 // 6?

                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("denoise")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("trim silence")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("echo effect")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("low-pass filter")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("high-pass filter")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("flanger")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("phaser")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("chorus")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }

                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true && idFilterFrequencyText.text !== "" )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium

                    onClicked: {
                        if (idComboBoxToolsEffects.currentIndex === 0) {
                            py.denoiseAudio()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 1) {
                            py.trimSilence()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 2) {
                            py.echoEffect()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 3) {
                            py.lowPassFilter()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 4) {
                            py.highPassFilter()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 5) {
                            py.flangerEffect()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 6) {
                            py.phaserEffect()
                        }
                        else if (idComboBoxToolsEffects.currentIndex === 7) {
                            py.chorusEffect()
                        }
                    }
                }
            }

            ComboBox {
                id: idComboDenoiseType

                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 0 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("type 1")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("type 2")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            ComboBox {
                id: idSliderEchoType

                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 2 )
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("double instruments")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("mountain concert")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                    MenuItem {
                        text: qsTr("robot style")
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }
            }

            Slider {
                id: idSliderSilenceDB

                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: -16
                smooth: true
                stepSize: 1
                minimumValue: -50
                maximumValue: 0

                Label {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }

                    text: parent.value + qsTr(" dB threshold")
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            Slider {
                id: idSliderSilenceDuration

                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 1 )
                width: parent.width
                height: 1.1 * Theme.itemSizeMedium
                value: 5
                smooth: true
                stepSize: 0.5
                minimumValue: 0.5
                maximumValue: 60

                Label {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                        horizontalCenter: parent.horizontalCenter
                    }

                    text: parent.value + qsTr(" sec duration")
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            TextField {
                id: idFilterFrequencyText

                enabled: ( finishedLoading === true && showTools === true )
                visible: buttonEffects.down
                         && (idComboBoxToolsEffects.currentIndex === 3 || idComboBoxToolsEffects.currentIndex === 4)
                
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                inputMethodHints: Qt.ImhDigitsOnly
                text: "1000"
                label: qsTr("cutoff frequency (Hz)")
                
                validator: IntValidator {
                    bottom: 0
                    top: 20000
                }

                EnterKey.onClicked: idFilterFrequencyText.focus = false
            }

            Flanger{
                id: flanger
            
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 5  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }
            
            Phaser{
                id: phaser
            
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 6  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }
            
            Chorus{
                id: chorus
            
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonEffects.down && idComboBoxToolsEffects.currentIndex === 7  )
                anchors.top: idSubmenuEffects.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            }


            Row {
                id: idSubmenuFile
            
                visible: buttonFile.down
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
            
                ComboBox {
                    id: idComboBoxToolsFile
            
                    width: parent.width / 5 * 4
            
                    menu: ContextMenu {
                        MenuItem {
                            text: qsTr("rename")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                        MenuItem {
                            text: qsTr("delete")
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }
                    }
                }
            
                IconButton {
                    width: parent.width / 5
                    enabled: ( finishedLoading === true && showTools === true )
                    icon.source: "../symbols/icon-m-apply.svg"
                    icon.height: Theme.iconSizeMedium
                    icon.width: Theme.iconSizeMedium
            
                    onClicked: {
                        if (idComboBoxToolsFile.currentIndex === 0) {
                            py.renameOriginal()
                        }
                        else if (idComboBoxToolsFile.currentIndex === 1) {
                            remorse.execute( qsTr("Delete file?"),  py.deleteFile )
                        }
                    }
                }
            }

            TextField {
                id: idFilenameRenameText
            
                enabled: ( finishedLoading === true && showTools === true )
                visible: ( buttonFile.down && idComboBoxToolsFile.currentIndex === 0 )
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText
                text: origAudioName
                horizontalAlignment: TextEdit.AlignHCenter

                validator: RegExpValidator { 
                    // negative list
                    regExp: /^[^<>'\"/;*:`#?]*$/
                }

                EnterKey.onClicked: idFilenameRenameText.focus = false
            }
        } // end column
    } // end flickable
}
