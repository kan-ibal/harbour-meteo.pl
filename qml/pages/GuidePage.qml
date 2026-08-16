import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: guidePage
    allowedOrientations: defaultAllowedOrientations

    property bool _attachedPushed: false

    function _tryPushAttached() {
        if (!_attachedPushed && pageStack) {
            if (pageStack.busy) {
                return;
            }
            _attachedPushed = true;
            pageStack.pushAttached(Qt.resolvedUrl("GuideImagePage.qml"));
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            _tryPushAttached();
        }
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (guidePage.status === PageStatus.Active && !pageStack.busy) {
                guidePage._tryPushAttached();
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: tr("Legenda")
                description: tr("Jak czytać meteogramy UM?")
            }

            Column {
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingMedium

                Label {
                    text: tr("1. Oś Pozioma (Czas)")
                    font.bold: true
                    color: Theme.highlightColor
                }
                Label {
                    text: tr("Górna i dolna skala pozioma przedstawia czas. Ciągłe pionowe grube linie oddzielają dni tygodnia, wyznaczając północ (00:00). Czas podany jest w standardzie zimowym UTC+1 lub letnim UTC+2.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("2. Temperatura")
                    font.bold: true
                    color: Theme.highlightColor
                }
                Label {
                    text: tr("Wykres na samej górze przedstawia temperaturę. Czerwona linia ciągła to temperatura rzeczywista powietrza na wys. 2 metrów. Niebieska linia przerywana to temperatura odczuwalna (uwzględniająca wiatr i wilgoć).")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("3. Opady i Ciśnienie")
                    font.bold: true
                    color: Theme.highlightColor
                }
                Label {
                    text: tr("Drugi wykres pokazuje pionowe słupki opadów (zielony - deszcz, niebieski - śnieg, fioletowy - deszcz ze śniegiem) oraz czarną falującą linię ciągłą, która oznacza ciśnienie atmosferyczne w hPa.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("4. Wiatr")
                    font.bold: true
                    color: Theme.highlightColor
                }
                Label {
                    text: tr("Dolna część meteogramu zawiera średnią prędkość wiatru w m/s (linia ciągła) oraz maksymalne porywy (linia przerywana). Strzałki na samej górze tego panelu wskazują kierunek napływu wiatru.")
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }

                Separator { color: Theme.rgba(Theme.primaryColor, 0.1); width: parent.width }

                Label {
                    text: tr("Przesuń w lewo ➔ aby zobaczyć grafikę")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
