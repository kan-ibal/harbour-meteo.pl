import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: searchPage
    allowedOrientations: defaultAllowedOrientations

    property string searchQuery: ""
    property var searchResults: []
    property bool isSearching: false
    property var allCities: []
    property bool isLoadingCities: false

    Component.onCompleted: {
        loadCities();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: "Wyszukiwarka"
                description: "Baza miejscowości old.meteo.pl"
            }

            // Standard Silica Search input
            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Wpisz np. Hel, Zakopane, Poznań..."
                EnterKey.onClicked: {
                    triggerSearch();
                }
                onTextChanged: {
                    searchQuery = text;
                    performLocalSearch();
                }
            }

            Button {
                text: "Szukaj"
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: searchQuery.trim() !== ""
                onClicked: triggerSearch()
            }

            // Indicator when loading cities JSON
            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: isLoadingCities
                visible: isLoadingCities
            }

            // Results Section Header
            SectionHeader {
                text: "Wyniki wyszukiwania (" + searchResults.length + ")"
                visible: searchResults.length > 0
            }

            // List of search matches
            Column {
                width: parent.width
                visible: searchResults.length > 0

                Repeater {
                    model: searchResults
                    delegate: BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin

                            Label {
                                text: modelData.name + (modelData.voivodeship ? " (" + modelData.voivodeship + ")" : "")
                                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Label {
                                text: "Siatka UM: R:" + modelData.row + " C:" + modelData.col +
                                      (modelData.county && modelData.county !== "none" ? " • pow. " + modelData.county : "")
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        onClicked: {
                            activeCity = modelData;
                            fetchMeteogram(activeCity, false);
                            pageStack.pop();
                        }
                    }
                }
            }

            // Favorites section
            SectionHeader {
                text: "Ulubione Miejsca"
            }

            Column {
                width: parent.width
                visible: favoriteCities.length > 0

                Repeater {
                    model: favoriteCities
                    delegate: BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeMedium

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.horizontalPageMargin
                            anchors.right: favButton.left
                            anchors.rightMargin: Theme.paddingMedium
                            anchors.verticalCenter: parent.verticalCenter

                            Label {
                                text: modelData.name + (modelData.voivodeship ? " (" + modelData.voivodeship + ")" : "")
                                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Label {
                                text: "Siatka UM: R:" + modelData.row + " C:" + modelData.col +
                                      (modelData.county && modelData.county !== "none" ? " • pow. " + modelData.county : "")
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        IconButton {
                            id: favButton
                            icon.source: "image://theme/icon-m-favorite-selected"
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin
                            anchors.verticalCenter: parent.verticalCenter
                            onClicked: toggleFavorite(modelData)
                        }

                        onClicked: {
                            activeCity = modelData;
                            fetchMeteogram(activeCity, false);
                            pageStack.pop();
                        }
                    }
                }
            }

            Label {
                text: "Brak ulubionych miast. Dodaj je podczas przeglądania meteogramu."
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                horizontalAlignment: Text.AlignHCenter
                visible: favoriteCities.length === 0
            }
        }
    }

    function loadCities() {
        isLoadingCities = true;
        var xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("../data/meteo_cities.json"), true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                isLoadingCities = false;
                if (xhr.status === 200 || xhr.status === 0) {
                    try {
                        allCities = JSON.parse(xhr.responseText);
                        if (searchQuery.trim() !== "") {
                            performLocalSearch();
                        }
                    } catch (e) {
                        console.log("Error parsing meteo_cities.json: " + e);
                    }
                }
            }
        };
        xhr.send();
    }

    function stripDiacritics(str) {
        if (!str) return "";
        var diacritics = {
            'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z',
            'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N', 'Ó': 'O', 'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z'
        };
        return str.replace(/[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]/g, function(match) {
            return diacritics[match] || match;
        });
    }

    function triggerSearch() {
        performLocalSearch();
    }

    function performLocalSearch() {
        var q = searchQuery.trim();
        if (!q) {
            searchResults = [];
            return;
        }
        var normQuery = stripDiacritics(q).toLowerCase();
        var startsWithMatches = [];
        var containsMatches = [];
        var limit = 50;

        for (var i = 0; i < allCities.length; i++) {
            var city = allCities[i];
            var nameNorm = stripDiacritics(city.name || "").toLowerCase();
            var voivNorm = stripDiacritics(city.voivodeship || "").toLowerCase();
            var countyNorm = stripDiacritics(city.county || "").toLowerCase();

            if (nameNorm.indexOf(normQuery) === 0) {
                startsWithMatches.push(city);
            } else if (nameNorm.indexOf(normQuery) !== -1 ||
                       voivNorm.indexOf(normQuery) !== -1 ||
                       (countyNorm !== "none" && countyNorm.indexOf(normQuery) !== -1)) {
                containsMatches.push(city);
            }

            if (startsWithMatches.length + containsMatches.length >= limit * 2) {
                break;
            }
        }

        searchResults = startsWithMatches.concat(containsMatches).slice(0, limit);
    }
}
