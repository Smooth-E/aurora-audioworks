import QtQuick 2.0
import Aurora.Controls 1.0
import Sailfish.Silica 1.0
import "../components"

Page {
    objectName: "AboutPage"

    allowedOrientations: Orientation.All

    AppBar {
        id: appBar

        headerText: qsTr("About Audioworks")

        AppBarSpacer { }

        AppBarButton {
            readonly property string version: "v1.5.2.1"

            text: version

            onClicked: {
                Clipboard.text = version
                Notices.show(qsTr("Version info copied to clipboard"), Notice.Short, Notice.Bottom)
            }
        }
    }

    SilicaFlickable {
        anchors {
            top: appBar.bottom
            bottom: parent.bottom
        }

        width: parent.width
        contentHeight: column.height + Theme.paddingLarge

        VerticalScrollDecorator { }

        Column {
            id: column

            readonly property real horizontalMargin: Theme.horizontalPageMargin
            readonly property real widgetWidth: width - horizontalMargin * 2

            width: parent.width

            Item {
                width: 1
                height: Theme.paddingLarge * 2
            }

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.dp(128)
                height: width
                source: Qt.resolvedUrl("../symbols/audiocut.svg")
            }

            Item {
                width: 1
                height: Theme.paddingLarge * 2
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                text: qsTr("Audioworks")
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeLarge
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                text: qsTr("An audio manipulation tool")
                opacity: Theme.opacityOverlay
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                text: qsTr("Contributions and support")
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            PreferenceButton {
                width: parent.width
                icon.source: Qt.resolvedUrl("../symbols/icon-github.svg")
                name: qsTr("GitHub")
                description: qsTr("View source code, propose changes or report problems.")
                
                onClicked: Qt.openUrlExternally("https://github.com/Smooth-E/aurora-audioworks")
            }

            PreferenceButton {
                width: parent.width
                icon.source: Qt.resolvedUrl("../symbols/icon-sparkle.svg")
                name: qsTr("Donate")
                description: qsTr("Support the maintainer of this app.")

                onClicked: Qt.openUrlExternally("https://boosty.to/smooth-e/donate")
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                text: qsTr("Authors")
                color: Theme.highlightColor
                wrapMode: Text.Wrap
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("This app was originally developed for Sailfish OS by people mentioned below. "
                        + "It was then ported to Aurora OS and is now maintained by Smooth-E.")
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Label {
                width: column.widgetWidth
                x: column.horizontalMargin
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                text: qsTr("Copyright © 2020 Tobias Planitzer"
                        + "\nCopyright © 2021-2023 Mark Washeim"
                        + "\nCopyright © 2025 Smooth-E")
            }
        }
    }
}
