import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// Forecast from Open-Meteo (no API key). Location: [desktop.weather] location = "City", else guessed from your IP.
Card {
    id: root
    widget: "weather"

    readonly property bool imperial: cfg.units === "imperial"
    readonly property string query: cfg.location ?? ""
    property var place: null   // { name, lat, lon }
    property var data: null
    property string error

    readonly property var now: data?.current ?? null
    readonly property var today: data ? day(0) : null
    readonly property var hours: {
        if (!data) return []
        const t = data.hourly.time, start = t.findIndex(x => x >= data.current.time.slice(0, 13))
        return [1, 3, 5, 7, 9, 11].map(o => start + o).filter(i => i < t.length).map(i => ({
            time: t[i].slice(11, 16), temp: data.hourly.temperature_2m[i],
            icon: icon(data.hourly.weather_code[i], data.hourly.is_day[i]), rain: data.hourly.precipitation_probability[i]
        }))
    }
    readonly property var days: data ? [1, 2, 3, 4, 5].map(day) : []
    readonly property real weekLow: Math.min(...days.map(d => d.low))
    readonly property real weekHigh: Math.max(...days.map(d => d.high))

    function day(i) {
        const d = data.daily
        return {
            name: i === 0 ? "Today" : Qt.formatDate(new Date(d.time[i] + "T12:00"), "ddd"),
            icon: icon(d.weather_code[i], 1), low: d.temperature_2m_min[i], high: d.temperature_2m_max[i],
            rain: d.precipitation_probability_max[i], sunrise: d.sunrise[i].slice(11), sunset: d.sunset[i].slice(11)
        }
    }

    // WMO weather codes
    function icon(code, isDay) {
        const i = Theme.icon
        if (code <= 1) return isDay ? i.sunny : i.night
        if (code === 2) return isDay ? i.partly : i.partlyNight
        if (code === 3) return i.cloudy
        if (code <= 48) return i.fog
        if (code === 65 || code === 82) return i.pouring
        if (code === 66 || code === 67) return i.sleet
        if (code <= 82) return i.rainy
        if (code <= 86) return i.snowy
        return code === 95 ? i.storm : i.hail
    }
    function describe(code) {
        return ({
            0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Freezing fog",
            51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
            61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
            71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
            80: "Light showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Snow showers",
            95: "Thunderstorm", 96: "Thunderstorm, hail", 99: "Thunderstorm, hail"
        })[code] ?? "—"
    }
    function deg(t) { return Math.round(t) + "°" }

    function get(url, done) {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            try {
                if (xhr.status !== 200) throw new Error("HTTP " + xhr.status)
                done(JSON.parse(xhr.responseText))
                root.error = ""
            } catch (e) {
                root.error = data ? "" : "Weather unavailable"
                retry.start()
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function locate() {
        if (query) get(`https://geocoding-api.open-meteo.com/v1/search?count=1&name=${encodeURIComponent(query)}`, r => {
            const p = r.results[0]
            place = { name: p.name, lat: p.latitude, lon: p.longitude }
            refresh()
        })
        else get("https://ipapi.co/json/", r => {
            place = { name: r.city, lat: r.latitude, lon: r.longitude }
            refresh()
        })
    }

    function refresh() {
        if (!place) return locate()
        get("https://api.open-meteo.com/v1/forecast?timezone=auto&forecast_days=6"
            + `&latitude=${place.lat}&longitude=${place.lon}`
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"
            + (imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""), r => data = r)
    }

    Component.onCompleted: refresh()
    onQueryChanged: { place = null; refresh() }
    onImperialChanged: refresh()
    Timer { running: true; repeat: true; interval: 15 * 60000; onTriggered: root.refresh() }
    Timer { id: retry; interval: 60000; onTriggered: root.refresh() }

    // Icon + caption
    component Fact: Row {
        property string icon
        property string text
        property color color: Theme.on_surface_variant
        property int size: Theme.fontSize - 2
        spacing: 4
        Icon { text: parent.icon; color: parent.color; font.pixelSize: parent.size + 2; anchors.verticalCenter: parent.verticalCenter }
        StyledText { text: parent.text; color: parent.color; font.pixelSize: parent.size; anchors.verticalCenter: parent.verticalCenter }
    }

    // Header
    RowLayout {
        spacing: 6
        Icon { text: Theme.icon.pin; color: root.accent; font.pixelSize: 16 }
        StyledText { text: root.place?.name ?? "Locating…"; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Fact { visible: !!root.today; icon: Theme.icon.sunrise; text: root.today?.sunrise ?? "" }
        Fact { visible: !!root.today; icon: Theme.icon.sunset; text: root.today?.sunset ?? "" }
    }

    StyledText {
        visible: !root.data
        text: root.error || "Loading forecast…"
        color: Theme.on_surface_variant
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Theme.pad
        Layout.bottomMargin: Theme.pad
    }

    // Now
    RowLayout {
        visible: !!root.now
        spacing: Theme.pad
        Icon { text: root.now ? root.icon(root.now.weather_code, root.now.is_day) : ""; color: root.accent; font.pixelSize: 64 }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            StyledText { text: root.now ? root.deg(root.now.temperature_2m) : ""; font.pixelSize: 44; font.weight: Font.Bold }
            StyledText { text: root.now ? root.describe(root.now.weather_code) : ""; color: Theme.on_surface_variant }
        }
        ColumnLayout {
            spacing: 4
            Layout.alignment: Qt.AlignTop
            Fact { icon: Theme.icon.thermometer; text: root.now ? "Feels " + root.deg(root.now.apparent_temperature) : ""; Layout.alignment: Qt.AlignRight }
            Fact { icon: Theme.icon.humidity; text: root.now ? root.now.relative_humidity_2m + "%" : ""; Layout.alignment: Qt.AlignRight }
            Fact { icon: Theme.icon.wind; text: root.now ? Math.round(root.now.wind_speed_10m) + (root.imperial ? " mph" : " km/h") : ""; Layout.alignment: Qt.AlignRight }
        }
    }

    // Next hours
    Rectangle {
        visible: root.hours.length > 0
        Layout.fillWidth: true
        implicitHeight: hourRow.implicitHeight + Theme.gap * 2
        radius: Theme.radiusSmall
        color: Theme.alpha(Theme.surface_container_highest, 0.6)

        RowLayout {
            id: hourRow
            anchors.fill: parent
            anchors.margins: Theme.gap
            Repeater {
                model: root.hours
                ColumnLayout {
                    required property var modelData
                    spacing: 2
                    Layout.fillWidth: true
                    StyledText { text: modelData.time; color: Theme.on_surface_variant; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
                    Icon { text: modelData.icon; color: root.accent; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
                    StyledText { text: root.deg(modelData.temp); font.weight: Font.Medium; Layout.alignment: Qt.AlignHCenter }
                    StyledText {
                        text: modelData.rain + "%"
                        opacity: modelData.rain >= 20 ? 1 : 0
                        color: Theme.secondary
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    // Next days: the bar spans each day's low–high within the week's range
    ColumnLayout {
        visible: root.days.length > 0
        spacing: 6
        Repeater {
            model: root.days
            RowLayout {
                id: dayRow
                required property var modelData
                readonly property real span: Math.max(1, root.weekHigh - root.weekLow)
                spacing: Theme.gap
                StyledText { text: modelData.name; Layout.preferredWidth: 40 }
                Icon { text: modelData.icon; color: root.accent; Layout.preferredWidth: 24 }
                Fact {
                    icon: Theme.icon.umbrella
                    text: modelData.rain + "%"
                    opacity: modelData.rain >= 20 ? 1 : 0
                    color: Theme.secondary
                    size: 11
                    Layout.preferredWidth: 48
                }
                StyledText { text: root.deg(modelData.low); color: Theme.on_surface_variant; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 32 }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.surface_container_highest
                    Rectangle {
                        x: parent.width * (modelData.low - root.weekLow) / dayRow.span
                        width: Math.max(6, parent.width * (modelData.high - modelData.low) / dayRow.span)
                        height: parent.height
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: Theme.secondary }
                            GradientStop { position: 1; color: root.accent }
                        }
                    }
                }
                StyledText { text: root.deg(modelData.high); font.weight: Font.Medium; Layout.preferredWidth: 32 }
            }
        }
    }
}
