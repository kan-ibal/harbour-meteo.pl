import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: gridPage
    allowedOrientations: defaultAllowedOrientations

    property var gridCities: []

    Component.onCompleted: {
        loadGridCities();
    }

    function loadGridCities() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("../data/grid_cities.json"), true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        gridCities = JSON.parse(xhr.responseText);
                    } catch (e) {
                        console.log("Error parsing grid_cities.json: " + e);
                    }
                }
            }
        };
        xhr.send();
    }

    Column {
        id: topColumn
        width: parent.width
        spacing: Theme.paddingMedium

        PageHeader {
            title: "Siatka Współrzędnych"
            description: "Ręczny dobór punktu modelu UM"
        }

        Label {
            text: "Wprowadź współrzędne wiersza (X) i kolumny (Y) siatki numerycznej meteo.pl."
            width: parent.width - Theme.paddingLarge * 2
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
        }

        TextField {
            id: rowInput
            width: parent.width
            label: "Wiersz (Row)"
            placeholderText: "np. 406 (Zakres: 100 - 650)"
            text: activeCity.row.toString()
            inputMethodHints: Qt.ImhDigitsOnly
        }

        TextField {
            id: colInput
            width: parent.width
            label: "Kolumna (Column)"
            placeholderText: "np. 250 (Zakres: 10 - 500)"
            text: activeCity.col.toString()
            inputMethodHints: Qt.ImhDigitsOnly
        }

        Button {
            text: "Zastosuj współrzędne"
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                var r = parseInt(rowInput.text, 10);
                var c = parseInt(colInput.text, 10);
                
                if (!isNaN(r) && !isNaN(c) && r >= 100 && r <= 650 && c >= 10 && c <= 500) {
                    var resolvedName = "Siatka [" + r + ", " + c + "]";
                    for (var i = 0; i < gridCities.length; i++) {
                        if (parseInt(gridCities[i].row, 10) === r && parseInt(gridCities[i].col, 10) === c) {
                            resolvedName = gridCities[i].name;
                            break;
                        }
                    }

                    activeCity = {
                        "name": resolvedName,
                        "row": rowInput.text,
                        "col": colInput.text,
                        "id": 0
                    };
                    console.log("gridData", activeCity.row);
                    fetchMeteogram(activeCity, false);
                    pageStack.pop();
                } else {
                    console.log("Nieprawidłowe współrzędne.");
                }
            }
        }
    }

    SilicaFlickable {
        anchors.top: topColumn.bottom
        anchors.topMargin: Theme.paddingMedium
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentHeight: scrollableColumn.height

        Column {
            id: scrollableColumn
            width: parent.width
            spacing: Theme.paddingSmall

            SectionHeader {
                text: "Popularne punkty kontrolne"
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Repeater {
                    model: gridCities

                    delegate: BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeSmall

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.rightMargin: Theme.horizontalPageMargin
                            spacing: Theme.paddingLarge

                            Label {
                                text: modelData.name
                                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: "Wiersz: " + modelData.row + " Kol: " + modelData.col
                                color: Theme.secondaryColor
                                font.pixelSize: Theme.fontSizeTiny
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onClicked: {
                            rowInput.text = modelData.row.toString();
                            colInput.text = modelData.col.toString();
                        }
                    }
                }
            }
        }
    }
}
