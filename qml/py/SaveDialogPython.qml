import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4

Python {
    id: py

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

    Component.onCompleted: {
        // Which Pythonfile will be used?
        importModule('audiox', function () {});

        // Handlers = Signals to do something in QML whith received Infos from pyotherside.send
        setHandler('tempFilesDeleted', function(i) {
            //console.log("temp files deleted: " + i)
        });

        setHandler('fileIsSaved', function() {
            saveComplete = true
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
} // end Python
