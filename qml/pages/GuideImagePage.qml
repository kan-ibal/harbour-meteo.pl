import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: guideImagePage
    allowedOrientations: defaultAllowedOrientations

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                id: header
                title: tr("Legenda Graficzna")
                description: tr("Objaśnienia symboli meteogramu")
            }

            Flickable {
                id: imageFlickable
                width: parent.width
                height: Math.max(Theme.itemSizeHuge * 5, guideImagePage.height - header.height - Theme.paddingMedium * 2)
                contentWidth: img.width
                contentHeight: img.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Image {
                    id: img
                    property string legendLang: (typeof currentLanguage !== "undefined" && currentLanguage === "en") ? "en" : "pl"
                    source: Qt.resolvedUrl("../data/leg_um_" + legendLang + "_cbase_256.png")
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    width: imageFlickable.width * zoomScale
                    height: imageFlickable.height * zoomScale

                    property real zoomScale: 1.0

                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Błąd ładowania obrazu legendy: " + source);
                        }
                    }
                }

                PinchArea {
                    anchors.fill: parent
                    pinch.target: img
                    pinch.minimumScale: 1.0
                    pinch.maximumScale: 3.5

                    onPinchUpdated: {
                        img.zoomScale = pinch.scale;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        img.zoomScale = (img.zoomScale > 1.0) ? 1.0 : 2.0;
                    }
                }
            }
        }
    }
}
