import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: aboutPage
    allowedOrientations: defaultAllowedOrientations

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: tr("O Programie")
                description: tr("harbour-meteopl client")
            }

            Column {
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Image {
                    source: "image://theme/icon-m-weather"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.iconSizeLauncher
                    height: Theme.iconSizeLauncher
                }

                Label {
                    text: "MeteoPL v1.1"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.highlightColor
                }

                Label {
                    text: tr("Natywny klient meteogramów dla systemu Sailfish OS. Pozwala pobierać, przeglądać i lokalnie zapisywać (cache) prognozy numeryczne ICM UM 4 km z portalu old.meteo.pl.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("Autorzy i Licencja")
                    font.bold: true
                    color: Theme.highlightColor
                }

                Label {
                    text: tr("• Inspiracja: J2Enjoyer<br/>• Licencja: MIT<br/>• Meteogramy: <a href=\"https://old.meteo.pl\">ICM Uniwersytet Warszawski (meteo.pl)</a><br/>• Adaptacja: kan-ibal")
                    textFormat: Text.StyledText
                    linkColor: Theme.highlightColor
                    onLinkActivated: Qt.openUrlExternally(link)
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("Zastrzeżenie (Disclaimer)")
                    font.bold: true
                    color: Theme.highlightColor
                }

                Label {
                    text: tr("Prezentowane dane są wynikiem obliczeń numerycznych i mogą odbiegać od rzeczywistych warunków pogodowych. Autorzy nie biorą odpowiedzialności za decyzje podjęte na ich podstawie.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }
        }
    }
}
