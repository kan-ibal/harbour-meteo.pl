import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: weatherPage
    allowedOrientations: defaultAllowedOrientations

    // Silica Flickable which holds the pulley menu and zoom container
    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: parent.height

        // Native Jolla Silica Pulley Menu
        PullDownMenu {
            MenuItem {
                text: tr("O programie")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: tr("Legenda")
                onClicked: pageStack.push(Qt.resolvedUrl("GuidePage.qml"))
            }
            MenuItem {
                text: tr("Pamięć podręczna")
                onClicked: pageStack.push(Qt.resolvedUrl("CachePage.qml"))
            }
            MenuItem {
                text: tr("Współrzędne siatki")
                onClicked: pageStack.push(Qt.resolvedUrl("GridPage.qml"))
            }
            MenuItem {
                text: tr("Wyszukaj miejscowość")
                onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"))
            }
            MenuItem {
                text: currentLanguage === "pl" ? "Język: English" : "Language: Polski"
                onClicked: toggleLanguage()
            }
            MenuItem {
                text: isCityFavorite(activeCity) ? tr("Usuń z ulubionych") : tr("Oznacz jako ulubione i domyślne")
                onClicked: toggleFavorite(activeCity)
            }
            MenuItem {
                text: tr("Odśwież prognozę")
                onClicked: fetchMeteogram(activeCity, true)
            }
        }

        // Header containing city name and metadata
        PageHeader {
            id: header
            title: activeCity.name
            description: (currentLanguage === "pl" ? ("Wiersz: " + activeCity.row + " Kolumna: " + activeCity.col) : ("Row: " + activeCity.row + " Column: " + activeCity.col)) + (isCityFavorite(activeCity) ? ("\n" + tr("★ Ulubione (Domyślne) • ")) : "")
        }

       // Main status banner
        Rectangle {
            id: statusBannerSource
            width: parent.width
            height: Theme.itemSizeExtraSmall
            color: Theme.rgba(Theme.highlightDimmerColor, 0.1)
            anchors.top: header.bottom

            Label {
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: isCachedForecast ? tr("Najnowsza z offline") : tr("Pobrana z meteo.pl")
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }

        }

        Rectangle {
            id: statusBannerData
            width: parent.width
            height: Theme.itemSizeExtraSmall
            color: Theme.rgba(Theme.highlightDimmerColor, 0.1)
            anchors.top: statusBannerSource.bottom

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: cacheTimeText + " (" + cacheSizeText + ")"
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }
        }
     

        // Interactive Pinch & Zoom Image Frame
        Flickable {
            id: imageFlickable
            anchors.top: statusBannerData.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            contentWidth: img.width
            contentHeight: img.height

            boundsBehavior: Flickable.StopAtBounds

            Image {
                id: img
                source: meteogramLocalPath
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                width: imageFlickable.width * zoomScale
                height: imageFlickable.height * zoomScale

                property real zoomScale: 1.0

                onStatusChanged: {
                    if (status === Image.Error) {
                        activeError = tr("Nie udało się załadować pobranego meteogramu.");
                    }
                }
            }

            // PinchArea for zooming in on mobile
            PinchArea {
                anchors.fill: parent
                pinch.target: img
                pinch.minimumScale: 0.8
                pinch.maximumScale: 3.5

                onPinchUpdated: {
                    img.zoomScale = pinch.scale;
                }
            }

            // Double tap to reset zoom scale
            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    img.zoomScale = (img.zoomScale > 1.0) ? 1.0 : 1.8;
                }
            }
        }

        // Loading and Error view state screens
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: header.height
            color: Theme.rgba(Theme.solidDarkColor, 0.85)
            visible: isDownloading || activeError !== ""

            Column {
                anchors.centerIn: parent
                width: parent.width - Theme.paddingLarge * 2
                spacing: Theme.paddingLarge

                BusyIndicator {
                    running: isDownloading
                    size: BusyIndicatorSize.Large
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    text: isDownloading ? tr("Pobieranie najnowszego meteogramu...") : activeError
                    width: parent.width
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primaryColor
                    font.pixelSize: Theme.fontSizeMedium
                }

                Button {
                    text: tr("Spróbuj ponownie")
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: activeError !== ""
                    onClicked: {
                        fetchMeteogram(activeCity, true);
                    }
                }
            }
        }
    }
}
