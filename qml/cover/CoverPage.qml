import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.paddingLarge * 2
        spacing: Theme.paddingMedium

        Label {
            text: "Meteo.pl"
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        Label {
            text: activeCity.name
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.primaryColor
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            width: parent.width
        }

        Label {
            text: "R: " + activeCity.row + " C: " + activeCity.col
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
            font.family: "Monospace"
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        Icon {
            source: "image://theme/icon-m-weather"
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.primaryColor
        }
    }

    CoverActionList {
        id: coverActions

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: {
                fetchMeteogram(activeCity, true);
            }
        }
    }
}
