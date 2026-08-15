import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: cachePage
    allowedOrientations: defaultAllowedOrientations

    property string totalSizeText: "Obliczanie..."
    property var cachedFiles: []

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refreshCacheInfo();
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
                title: "Menedżer Pamięci"
                description: "Zapisane meteogramy offline"
            }

            Rectangle {
                width: parent.width - Theme.paddingLarge * 2
                height: Theme.itemSizeMedium
                color: Theme.rgba(Theme.highlightColor, 0.05)
                border.color: Theme.rgba(Theme.highlightColor, 0.2)
                border.width: 1
                radius: Theme.paddingMedium
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    text: "Użycie pamięci cache:"
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                }

                Label {
                    text: totalSizeText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingLarge
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingMedium
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                }

                Button {
                    text: "Wyczyść"
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        py.call('mgram_fetcher.clear_cache', [cacheDir], function(ok) {
                            refreshCacheInfo();
                            fetchMeteogram(activeCity, false);
                        });
                    }
                }
            }

            SectionHeader {
                text: "Zapisane prognozy (" + cachedFiles.length + ")"
            }

            Column {
                width: parent.width
                visible: cachedFiles.length > 0

                Repeater {
                    model: cachedFiles
                    delegate: BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: "Współrzędne: " + modelData.row + " , " + modelData.col
                                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                            }
                            Label {
                                text: "Model run: " + modelData.fdate + " | " + modelData.size
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                            }
                        }

                        onClicked: {
                            activeCity = {
                                "name": "Współrzędne [" + modelData.row + ", " + modelData.col + "]",
                                "row": modelData.row,
                                "col": modelData.col,
                                "id": 0
                            };
                            fetchMeteogram(activeCity, false);
                            pageStack.pop();
                        }
                    }
                }
            }

            Label {
                text: "Brak zapisanych plików."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                visible: cachedFiles.length === 0
            }
        }
    }

    function refreshCacheInfo() {
        py.call('mgram_fetcher.get_cache_info', [cacheDir], function(resultJson) {
            var info = JSON.parse(resultJson);
            totalSizeText = info.totalSize;
            cachedFiles = info.files;
        });
    }
}
