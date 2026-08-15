import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.4
import "pages"
import "cover"

ApplicationWindow {
    id: appWindow
    initialPage: Qt.resolvedUrl("pages/WeatherPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // Global application properties
    property var activeCity: ({
        "name": "Warszawa",
        "row": 406,
        "col": 250,
        "id": 2216,
        "voivodeship": "mazowieckie"
    })
    
    property string meteogramLocalPath: ""
    property string cacheTimeText: "Brak danych"
    property string cacheSizeText: ""
    property bool isCachedForecast: false
    property bool isDownloading: false
    property string activeError: ""
    
    // Sailfish OS cache folder path
    property string cacheDir: StandardPaths.cache + "/harbour-meteopl"

    // Database of favorites managed locally
    property var favoriteCities: []

    // Python executor helper
    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("py"));
            importModule('mgram_fetcher', function() {
                console.log("Python backend engine initialized successfully!");
                loadInitialMeteogram();
            });
        }

        onError: {
            console.log("PyOtherSide error: " + trace);
            appWindow.activeError = "Błąd silnika Python: " + trace;
        }

        onReceived: {
            console.log("Python event received: " + data);
        }
    }

    function loadInitialMeteogram() {
        py.call('mgram_fetcher.load_settings', [cacheDir], function(resultJson) {
            if (resultJson) {
                try {
                    var settings = JSON.parse(resultJson);
                    if (settings.favoriteCities && Array.isArray(settings.favoriteCities)) {
                        favoriteCities = settings.favoriteCities;
                    }
                    if (settings.defaultFavoriteCity && settings.defaultFavoriteCity.name && settings.defaultFavoriteCity.row && settings.defaultFavoriteCity.col) {
                        activeCity = settings.defaultFavoriteCity;
                    } else if (settings.activeCity && settings.activeCity.name && settings.activeCity.row && settings.activeCity.col) {
                        activeCity = settings.activeCity;
                    } else if (favoriteCities.length > 0) {
                        activeCity = favoriteCities[0];
                    }
                } catch(e) {
                    console.log("Error parsing settings: " + e);
                }
            }
            fetchMeteogram(activeCity, false);
        });
    }

    function saveSettings() {
        var defaultFav = isCityFavorite(activeCity) ? activeCity : (favoriteCities.length > 0 ? favoriteCities[0] : activeCity);
        var data = {
            "favoriteCities": favoriteCities,
            "activeCity": activeCity,
            "defaultFavoriteCity": defaultFav
        };
        py.call('mgram_fetcher.save_settings', [cacheDir, JSON.stringify(data)], function(res) {
            console.log("Settings saved.");
        });
    }

    function fetchMeteogram(city, forceRefresh) {
        if (isDownloading) return;
        isDownloading = true;
        activeError = "";
        
        py.call('mgram_fetcher.fetch', [city.id || 0, city.row || 0, city.col || 0, cacheDir, forceRefresh], function(resultJson) {
            isDownloading = false;
            var result = JSON.parse(resultJson);
            if (result.error) {
                activeError = result.error;
                meteogramLocalPath = "";
            } else {
                meteogramLocalPath = "file://" + result.filePath;
                isCachedForecast = result.isCached;
                
                var date = new Date(result.fetchedAt * 1000);
                cacheTimeText = date.toLocaleTimeString() + " (" + date.toLocaleDateString() + ")";
                cacheSizeText = result.size;
                
                // Keep coordinates updated
                activeCity.row = result.row;
                activeCity.col = result.col;

                saveSettings();
            }
        });
    }

    function toggleFavorite(city) {
        var foundIdx = -1;
        for (var i = 0; i < favoriteCities.length; i++) {
            if (favoriteCities[i].row === city.row && favoriteCities[i].col === city.col) {
                foundIdx = i;
                break;
            }
        }
        if (foundIdx >= 0) {
            favoriteCities.splice(foundIdx, 1);
        } else {
            favoriteCities.push(city);
            // Setting a city as favorite automatically sets it as the active standard city
            activeCity = city;
        }
        // Force state update notification
        favoriteCities = favoriteCities;
        saveSettings();
    }

    function isCityFavorite(city) {
        for (var i = 0; i < favoriteCities.length; i++) {
            if (favoriteCities[i].row === city.row && favoriteCities[i].col === city.col) {
                return true;
            }
        }
        return false;
    }
}
