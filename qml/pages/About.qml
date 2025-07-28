import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    objectName: "AboutPage"

    allowedOrientations: Orientation.All

    Column {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
        }

        PageHeader {
            title: qsTr("About Audioworks")
        }

        Item {
            width: 1
            height: 3 * Theme.paddingLarge
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 5
            height: width
            source: "../cover/audiocut.svg"
            smooth: true
            asynchronous: true
        }

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            text: qsTr("An Audio Tool")
        }

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("Copyright © 2020 Tobias Planitzer"
                       + "\nCopyright © 2021-2023 Mark Washeim"
                       + "\nCopyright © 2025 Smooth-E")
        }

        Item {
            width: 1
            height: 2 * Theme.paddingLarge
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: qsTr("Audioworks is licensed under the terms of the GNU General Public License v3.")
        }

        Item {
            width: 1
            height: 2 * Theme.paddingLarge
        }

        Label {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottomMargin: Theme.paddingSmall
            }

            color: Theme.secondaryColor
            textFormat: Text.StyledText
            linkColor: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            text: "<a href=\"https://github.com/Smooth-E/aurora-audioworks\">Source: GitHub</a>"

            onLinkActivated: {
                console.log("Opening external browser:", link);
                Qt.openUrlExternally(link)
            }
        }
    }
}
