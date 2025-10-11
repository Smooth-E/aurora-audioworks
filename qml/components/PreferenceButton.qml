import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property alias icon: icon
    property alias name: nameLabel.text
    property alias description: descriptionLabel.text
    
    readonly property real _horizontalMargin: Theme.horizontalPageMargin
    readonly property real _margin: Theme.paddingMedium
    
    width: contentItem.childrenRect.width
    height: contentItem.childrenRect.height + _margin * 2

    Icon {
        id: icon

        anchors {
            top: parent.top
            left: parent.left
            topMargin: _margin
            leftMargin: _horizontalMargin
        }

        width: Theme.iconSizeMedium
        height: width
    }

    Label {
        id: nameLabel

        anchors {
            left: icon.right
            right: parent.right
            top: parent.top
            topMargin: _margin
            leftMargin: _margin
            rightMargin: _horizontalMargin
        }

        height: contentHeight
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeMedium
    }

    Label {
        id: descriptionLabel

        anchors {
            left: icon.right
            right: parent.right
            top: nameLabel.bottom
            leftMargin: _margin
            rightMargin: _horizontalMargin
            topMargin: Theme.paddingSmall
        }

        height: contentHeight
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        opacity: Theme.opacityOverlay
    }
}
