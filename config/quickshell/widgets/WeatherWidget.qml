// widgets/WeatherWidget.qml - Weather information widget with auto-location
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "."

PanelWindow {
    id: root

    implicitWidth: 300
    implicitHeight: 350
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-weather"

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 10
    }

    // Weather data
    property string location: "Detecting..."
    property string detectedCity: ""
    property real temperature: 0
    property string condition: "Loading..."
    property string icon: "\uf0c2" // nf-fa-cloud
    property int humidity: 0
    property real windSpeed: 0
    property string windDirection: "N"
    property int feelsLike: 0

    property string primaryColor: ColorManager.primaryColor
    property string accentColor: ColorManager.accentColor
    property string mutedColor: ColorManager.mutedColor
    property string warningColor: "#E5A564"
    property string weatherUrl: "https://wttr.in/?format=j1"

    function getWeatherIcon(code) {
        // Weather condition codes from wttr.in mapped to Nerd Font icons
        const iconMap = {
            "113": "󰖙",  // nf-fa-sun - Sunny/Clear
            "116": "",  // nf-weather-day_cloudy - Partly cloudy
            "119": "󰖐",  // nf-fa-cloud - Cloudy
            "122": "󰅟",  // nf-fa-cloud - Overcast
            "143": "󰖑",  // nf-weather-fog - Mist
            "176": "",  // nf-weather-showers - Patchy rain possible
            "179": "",  // nf-weather-snow - Patchy snow possible
            "182": "",  // nf-weather-sleet - Patchy sleet possible
            "185": "",  // nf-weather-showers - Patchy freezing drizzle
            "200": "",  // nf-weather-thunderstorm - Thundery outbreaks
            "227": "",  // nf-weather-snow - Blowing snow
            "230": "",  // nf-weather-snow - Blizzard
            "248": "",  // nf-weather-fog - Fog
            "260": "",  // nf-weather-fog - Freezing fog
            "263": "",  // nf-weather-showers - Patchy light drizzle
            "266": "",  // nf-weather-showers - Light drizzle
            "281": "",  // nf-weather-showers - Freezing drizzle
            "284": "",  // nf-weather-showers - Heavy freezing drizzle
            "293": "",  // nf-weather-showers - Patchy light rain
            "296": "",  // nf-weather-rain - Light rain
            "299": "",  // nf-weather-rain - Moderate rain at times
            "302": "",  // nf-weather-rain - Moderate rain
            "305": "",  // nf-weather-raindrop - Heavy rain at times
            "308": "󰙾",  // nf-weather-raindrop - Heavy rain
            "311": "",  // nf-weather-showers - Light freezing rain
            "314": "",  // nf-weather-raindrop - Moderate or heavy freezing rain
            "317": "\",  // nf-weather-sleet - Light sleet
            "320": "\",  // nf-weather-sleet - Moderate or heavy sleet
            "323": "\",  // nf-weather-snow - Patchy light snow
            "326": "\",  // nf-weather-snow - Light snow
            "329": "\",  // nf-weather-snow - Patchy moderate snow
            "332": "\",  // nf-weather-snow - Moderate snow
            "335": "\",  // nf-weather-snow - Patchy heavy snow
            "338": "\",  // nf-weather-snow - Heavy snow
            "350": "",  // nf-weather-showers - Ice pellets
            "353": "",  // nf-weather-showers - Light rain shower
            "356": "",  // nf-weather-raindrop - Moderate or heavy rain shower
            "359": "",  // nf-weather-raindrop - Torrential rain shower
            "362": "\",  // nf-weather-sleet - Light sleet showers
            "365": "\",  // nf-weather-sleet - Moderate or heavy sleet showers
            "368": "\",  // nf-weather-snow - Light snow showers
            "371": "\",  // nf-weather-snow - Moderate or heavy snow showers
            "374": "",  // nf-weather-showers - Light showers of ice pellets
            "377": "",  // nf-weather-raindrop - Moderate or heavy showers of ice pellets
            "386": "󰙾",  // nf-fa-thunderstorm - Patchy light rain with thunder
            "389": "󰙾",  // nf-fa-thunderstorm - Moderate or heavy rain with thunder
            "392": "󰙾",  // nf-fa-thunderstorm - Patchy light snow with thunder
            "395": "󰙾"   // nf-fa-thunderstorm - Moderate or heavy snow with thunder
        }
        return iconMap[code] || "\uf0c2"
    }

    // Location detector using IP geolocation
    Process {
        id: locationReader
        command: ["curl", "-s", "https://ipapi.co/json/"]
        running: false
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                locationReader.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                try {
                    const data = JSON.parse(output)
                    root.detectedCity = data.city || "Unknown"
                    root.location = root.detectedCity

                    // Update weather URL with detected location
                    root.weatherUrl = "https://wttr.in/" + encodeURIComponent(root.detectedCity) + "?format=j1"

                    console.log("Weather: Location detected -", root.detectedCity)

                    // Fetch weather for detected location
                    weatherReader.running = true
                } catch (e) {
                    console.log("Weather: Failed to detect location, using default")
                    root.location = "Hyderabad"
                    root.weatherUrl = "https://wttr.in/Hyderabad?format=j1"
                    weatherReader.running = true
                }
                output = ""
            }
        }
    }

    // Weather data fetcher
    Process {
        id: weatherReader
        command: ["curl", "-s", root.weatherUrl]
        running: false
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                weatherReader.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                try {
                    const data = JSON.parse(output)
                    const current = data.current_condition[0]

                    root.temperature = parseFloat(current.temp_C)
                    root.condition = current.weatherDesc[0].value
                    root.humidity = parseInt(current.humidity)
                    root.windSpeed = parseFloat(current.windspeedKmph)
                    root.windDirection = current.winddir16Point
                    root.feelsLike = parseInt(current.FeelsLikeC)
                    root.icon = getWeatherIcon(current.weatherCode)

                    console.log("Weather: Updated -", root.condition, root.temperature + "°C")
                } catch (e) {
                    console.log("Weather: Failed to parse data", e)
                    root.condition = "Error loading"
                }
                output = ""
            }
        }
    }

    // Initial location detection
    Timer {
        interval: 1000
        running: true
        repeat: false
        triggeredOnStart: true
        onTriggered: locationReader.running = true
    }

    // Update timer (every 10 minutes)
    Timer {
        interval: 600000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: weatherReader.running = true
    }

    Rectangle {
        id: container
        anchors.fill: parent
        color: "transparent"


        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            // Location with icon
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
            }

            // Main temp and icon
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 15

                Text {
                    text: root.icon
                    font.pixelSize: 72
                    font.family: "Symbols Nerd Font"
                    color: root.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: root.temperature.toFixed(1) + "°C"
                        font.pixelSize: 48
                        font.weight: Font.Bold
                        font.family: "monospace"
                        color: root.primaryColor
                    }

                    Text {
                        text: "Feels like " + root.feelsLike + "°C"
                        font.pixelSize: 12
                        color: root.mutedColor
                    }
                }
            }



            // Details grid
            Row {
                width: parent.width
                spacing: parent.width / 2 - 60
                anchors.horizontalCenter: parent.horizontalCenter

                // Humidity
                Column {
                    spacing: 4

                    Text {
                        text: ""  // nf-fa-tint
                        font.pixelSize: 20
                        font.family: "Symbols Nerd Font"
                        color: root.primaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: root.humidity + "%"
                        font.pixelSize: 14
                        font.family: "monospace"
                        color: root.accentColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Humidity"
                        font.pixelSize: 11
                        color: root.mutedColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Wind
                Column {
                    spacing: 4

                    Text {
                        text: "󱪈"  // nf-weather-strong_wind
                        font.pixelSize: 20
                        font.family: "Symbols Nerd Font"
                        color: root.primaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: root.windSpeed.toFixed(0) + " km/h"
                        font.pixelSize: 14
                        font.family: "monospace"
                        color: root.accentColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: root.windDirection
                        font.pixelSize: 11
                        color: root.mutedColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
