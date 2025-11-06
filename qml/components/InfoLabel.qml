import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias title: titleLabel
    property alias description: descriptionLabel

    width: parent.width
    height: column.implicitHeight + Theme.paddingSmall * 2
    
    Column {
        id: column

        x: Theme.horizontalPageMargin
        y: Theme.paddingSmall
        width: parent.width - 2 * x

        Label {
            id: titleLabel

            width: parent.width
            wrapMode: Text.WordWrap
        }

        Label {
            id: descriptionLabel

            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.secondaryColor
        }
    }
}
