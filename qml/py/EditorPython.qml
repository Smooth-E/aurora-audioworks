import QtQuick 2.0
import io.thp.pyotherside 1.4

Python {
    id: py

    // File operations
    
    function getHomePath() {
        call("audiox.getHomePath", [])
    }

    function createTmpAndSaveFolder() {
        call("audiox.createTmpAndSaveFolder", [ tempAudioFolderPath, saveAudioFolderPath ])
    }

    function deleteAllTMPFunction() {
        undoNr = 0
        call("audiox.deleteAllTMPFunction", [ tempAudioFolderPath ])
    }

    function deleteLastTMPFunction() {
        console.log(lastTmpAudio2delete)
        console.log(lastTmpImage2delete)
        call("audiox.deleteLastTmpFunction", [ lastTmpAudio2delete, lastTmpImage2delete ])
    }

    function deleteFile() {
        stopPlayingResetWaveform()
        py.deleteAllTMPFunction()
        call("audiox.deleteFile", [ origAudioFilePath ])
    }

    function renameOriginal() {
        stopPlayingResetWaveform()

        py.deleteAllTMPFunction()
        var newFilePath = origAudioFolderPath + idFilenameRenameText.text + "." + origAudioType
        var newFileName = idFilenameRenameText.text
        var newFileType = origAudioType

        call("audiox.renameOriginal", [ origAudioFilePath, newFilePath, newFileName, newFileType ])
    }

    function createWaveformImage() {
        finishedLoading = false
        idImageWaveform.source = ""
        idImageWaveformZoom.source = ""
        var outputWaveformImagePath =  tempAudioFolderPath + "waveform" + ".tmp" + undoNr + ".png"

        if (debug == true) {
            console.debug(inputPathPy)
            console.debug(outputWaveformImagePath)
        }

        var waveformColor = "yellow"
        var stretch = "" //"compand,"
        var waveformPixelLength = idWaveformOverview.width * zoomAreaFactor
        var waveFormpixelHeight = idWaveformZoom.height //120

        var args = [ inputPathPy, outputWaveformImagePath, waveformColor, waveformPixelLength, 
                     waveFormpixelHeight, stretch]
        call("audiox.createWaveformImage", args)
    }

    function getAudioLengthPy() {
        var source = idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
        var tempAudioFilePath = decodeURIComponent("/" + source)
        call("audiox.getAudioLength", [ tempAudioFilePath ])
    }

    function copyToClipboard() {
        outputPathPy = tempAudioFolderPath + "audio" + ".tmp" + undoNr + "." + tempAudioType
        call("audiox.copyToClipboard", [ inputPathPy, fromPosMillisecond, toPosMillisecond ])
    }

    function pasteFromClipboard(pasteType) {
        preparePathAndUndo()

        var pasteHere = manualNowStamp
        call("audiox.pasteFromClipboard", [ inputPathPy, outputPathPy, tempAudioType, pasteHere, pasteType ])
    }

    // Audio manipulation

    function cutRemove() {
        preparePathAndUndo()
        call("audiox.cutRemove", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
    }
    
    function cutExtract() {
        preparePathAndUndo()
        call("audiox.cutExtract", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
    }

    function paddingSilence(){
        var padHere = manualNowStamp
        var durationSilence = idSliderPaddingDuration.value * 1000

        if (idComboPadding.currentIndex === 0) {
            var positionSilence = "beginning"
        }
        if (idComboPadding.currentIndex === 1) {
            positionSilence = "end"
        }
        if (idComboPadding.currentIndex === 2) {
            positionSilence = "cursor"
        }

        preparePathAndUndo()

        var args = [ inputPathPy, outputPathPy, tempAudioType, padHere, positionSilence, durationSilence ]
        call("audiox.paddingSilence", args)
    }

    function volumeChange() {
        preparePathAndUndo()

        var changeDB = idVolumeSlider.value
        var args = [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, changeDB ]
        call("audiox.volumeChange", args)
    }

    function volumeFadeIn() {
        preparePathAndUndo()
        call("audiox.volumeFadeIn", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
    }

    function volumeFadeOut() {
        preparePathAndUndo()
        call("audiox.volumeFadeOut", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
    }

    function volumeSilence() {
        preparePathAndUndo()

        var changeDB = -120
        var args = [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, changeDB ]
        call("audiox.volumeChange", args)
    }

    function speedChange() {
        preparePathAndUndo()
        var factorSpeed = idSpeedSlider.value

        if (idComboBoxSpeedPitch.currentIndex === 0) {
            var keepPitch = "false"
            call("audiox.speedChange", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond,
                                         factorSpeed, keepPitch ])
        }
        else {
            keepPitch = "true"
            call("audiox.slowDown", [ inputPathPy, outputPathPy, tempAudioType, factorSpeed ])
        }
    }

    function reverseAudio() {
        preparePathAndUndo()
        call("audiox.reverseAudio", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond ])
    }

    function denoiseAudio() {
        preparePathAndUndo()

        var filterType = idComboDenoiseType == 0 ? "afftdn" : "anlmdn"
        call("audiox.denoiseAudio", [ inputPathPy, outputPathPy, tempAudioType, filterType ])
    }
    function trimSilence() {
        preparePathAndUndo()

        var breakMS = idSliderSilenceDuration.value * 1000 // 1000 ms
        var breakDB = idSliderSilenceDB.value // -16...-25 dB
        var breakPadding = 100 //ms

        call("audiox.trimSilence", [ inputPathPy, outputPathPy, tempAudioType, fromPosMillisecond, toPosMillisecond, 
                                     breakMS, breakDB, breakPadding ])
    }

    function echoEffect() {
        preparePathAndUndo()

        if (idSliderEchoType.currentIndex === 0) { // double instruments
            var in_gain = 0.8
            var out_gain = 0.88
            var delays = 60
            var decays = 0.4
        }
        else if (idSliderEchoType.currentIndex === 1) { // mountain concert
            in_gain = 0.8
            out_gain = 0.9
            delays = 1000
            decays = 0.3
        }
        else { // robot style
            in_gain = 0.8
            out_gain = 0.88
            delays = 6
            decays = 0.4
        }

        call("audiox.echoEffect", [ inputPathPy, outputPathPy, tempAudioType, in_gain, out_gain, delays, decays ])
    }

    function lowPassFilter() {
        preparePathAndUndo()

        var filterFrequency = idFilterFrequencyText.text
        var filterOrder = 1 // ...4
        call("audiox.lowPassFilter", [ inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ])
    }

    function highPassFilter() {
        preparePathAndUndo()

        var filterFrequency = idFilterFrequencyText.text
        var filterOrder = 1 // ...4
        call("audiox.highPassFilter", [ inputPathPy, outputPathPy, tempAudioType, filterFrequency, filterOrder ])
    }

    // https://ffmpeg.org/ffmpeg-filters.html#flanger
    function flangerEffect() {
        preparePathAndUndo()
        
        var speed = flanger.speed // 0.1 - 10 Hz
        var delay = flanger.delay // 0-30
        var depth = flanger.depth // 0 - 10
        var phase = flanger.phase // 0 - 100
        var regen = 5 // -95 - 95

        //shape // sinusoidal / triangular
        // width // 0-100 71 default
        call("audiox.flangerEffect", [ inputPathPy, outputPathPy, tempAudioType, speed, depth, phase, delay, regen ])
    }

    // https://ffmpeg.org/ffmpeg-filters.html#aphaser
    function phaserEffect() {
        preparePathAndUndo()

        var in_gain = 0.5
        var out_gain = 0.75
        var speed = phaser.speed // 0.1 - 10 Hz
        var delay = phaser.delay // 0-30
        var decay = phaser.decay // 0 - 10

        //shape // sinusoidal / triangular
        // width // 0-100 71 default
        var args = [ inputPathPy, outputPathPy, tempAudioType, in_gain, out_gain, delay, decay, speed ]
        call("audiox.phaserEffect", args)
    }

    // https://ffmpeg.org/ffmpeg-filters.html#achorus
    function chorusEffect() {
        preparePathAndUndo()

        var in_gain = 0.5
        var out_gain = 0.90
        var speed = chorus.speed // 0.1 - 10 Hz
        var delay = chorus.delay // 0-30
        var decay = chorus.decay // 0 - 10
        var depth = chorus.depth // 0 - 10

        //shape // sinusoidal / triangular
        // width // 0-100 71 default
        call("audiox.chorusEffect", [ inputPathPy, outputPathPy, tempAudioType, delay, decay, speed, depth ])
    }

    onError: {
        // when an exception is raised, this error handler will be called
        console.log('python error: ' + traceback);
    }

    onReceived: {
        // asychronous messages from Python arrive here via pyotherside.send()
        console.log('got message from python: ' + data);
    }

    Component.onCompleted: {
        addImportPath(Qt.resolvedUrl('.'))
        importModule('audiox', function () { })

        // Handlers do something to QML with received Infos from Python file (=pyotherside.send)
        setHandler('homePathFolder', function( homeDir ) {
            tempAudioFolderPath = homeDir + "/.cache/de.poetaster/harbour-audiocut/"
            saveAudioFolderPath = homeDir + "/Music/"
            homeDirectory = homeDir
            //py.createTmpAndSaveFolder(tempAudioFolderPath, saveAudioFolderPath )
            py.createTmpAndSaveFolder( )
            py.deleteAllTMPFunction(tempAudioFolderPath)
        })

        setHandler('warningPydubNotAvailable', function() {
            warningNoPydub = true
        })

        setHandler('warningLameNotAvailable', function() {
            warningNoLAME = true
        })

        setHandler('loadImageWaveform', function(outputWaveformImagePath, audioLengthMillisecondsPython) {
            idImageWaveform.source = outputWaveformImagePath
            idImageWaveformZoom.source = outputWaveformImagePath
            audioLengthSecondsPython = audioLengthMillisecondsPython / 1000
            millisecondsPerPixelPython = (audioLengthMillisecondsPython / (idWaveformOverview.width * zoomAreaFactor) )
            finishedLoading = true
            showTools = true
            calculatePlayerPixelSpeed()
            stopPlayingResetWaveform()
        })

        setHandler('loadTempAudio', function( newFilePath ) {
            idAudioPlayer.source = newFilePath
            fromPosPixel = 0
            toPosPixel = 0
            autostart_getAudiolengthQML( newFilePath )
            py.createWaveformImage()
        })

        setHandler('finishedSavingRenaming', function( newFilePath, newFileName, newFileType ) {
            idAudioPlayer.source = newFilePath
            origAudioFilePath = newFilePath
            origAudioFileName = newFileName + "." + newFileType
            origAudioFolderPath = origAudioFilePath.replace(origAudioFileName, "")
            var origAudioFileNameArray = origAudioFileName.split(".")
            origAudioName = (origAudioFileNameArray.slice(0, origAudioFileNameArray.length-1)).join(".")
            origAudioType = origAudioFileNameArray[origAudioFileNameArray.length - 1]
            undoNr = 0
            py.createWaveformImage()
        })

        setHandler('deletedFile', function() {
            origAudioFilePath = ""
            origAudioFileName = ""
            origAudioFolderPath = ""
            origAudioType = ""
            origAudioName = ""
            idAudioPlayer.source = ""
            idImageWaveform.source = ""
            idImageWaveformZoom.source = ""
            audioLengthSecondsPython = 0
            millisecondsPerPixelPython = 0
            showTools = false
        })

        setHandler('deleteLastTmp', function() {
            finishedLoading = true
            showTools = true
        })

        setHandler('getAudioLenghtPy', function(audioLengthMillisecondsPython) {
            audioLengthSecondsPython = audioLengthMillisecondsPython / 1000
            millisecondsPerPixelPython = (audioLengthMillisecondsPython / (idWaveformOverview.width * zoomAreaFactor) )
            var source = idAudioPlayer.source.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            autostart_getAudiolengthQML( decodeURIComponent( "/" + source ) )
        })

        setHandler('copiedToClipboard', function() {
            clipboardAvailable = true
        })
    }
}
