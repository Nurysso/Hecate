import QtQuick 2.15
import QtQuick.Controls 2.0
import SddmComponents 2.0

import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 640
    height: 480
    color: "black"

    // Config properties
    readonly property color textColor: config.stringValue("basicTextColor")
    readonly property int passwordFontSize: config.intValue("passwordFontSize") || 96
    readonly property int usersFontSize: config.intValue("usersFontSize") || 48
    readonly property int sessionsFontSize: config.intValue("sessionsFontSize") || 24
    readonly property int helpFontSize: config.intValue("helpFontSize") || 18
    readonly property string defaultFont: config.stringValue("font") || "monospace"
    readonly property string helpFont: config.stringValue("helpFont") || defaultFont

    // State
    property int currentUsersIndex: userModel.lastIndex
    property int currentSessionsIndex: sessionModel.lastIndex
    readonly property int usernameRole: Qt.UserRole + 1
    readonly property int realNameRole: Qt.UserRole + 2
    readonly property int sessionNameRole: Qt.UserRole + 4

    property string currentUsername: config.boolValue("showUserRealNameByDefault")
        ? userModel.data(userModel.index(currentUsersIndex, 0), realNameRole)
        : userModel.data(userModel.index(currentUsersIndex, 0), usernameRole)
    property string currentSession: sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole)

    // ---- Fade settings (all overridable from theme.conf) ----
    // fadeEnabled=false disables the login fade entirely
    readonly property bool fadeEnabled: config.stringValue("fadeEnabled") !== "false"
    // ms the screen takes to fade to the fade color after pressing Enter (0 = instant)
    readonly property int fadeDuration: fadeEnabled ? cfgInt("fadeDuration", 220) : 0
    // extra ms to hold on the faded screen before the login request is sent
    readonly property int fadeHold: fadeEnabled ? cfgInt("fadeHold", 0) : 0
    // ms for the greeter to fade in from the fade color when it starts (0 = off)
    readonly property int introFadeDuration: fadeEnabled ? cfgInt("introFadeDuration", 0) : 0
    // color to fade to: match Hyprland's misc.background_color
    readonly property color fadeColor: config.stringValue("fadeColor") || "#000000"
    // linear | in | out | inout
    readonly property string fadeEasing: config.stringValue("fadeEasing") || "in"

    // ---- Error border ----
    readonly property color errorBorderColor: config.stringValue("errorBorderColor") || "#ff3117"
    readonly property int errorBorderWidth: cfgInt("errorBorderWidth", 5)

    // current duration used by the overlay (switched during the intro fade)
    property int overlayDuration: fadeDuration

    property string pendingPassword: ""
    property bool loggingIn: false

    // Helpers
    function usersCycleSelectPrev() {
        currentUsersIndex = currentUsersIndex - 1 < 0 ? userModel.count - 1 : currentUsersIndex - 1;
    }

    function usersCycleSelectNext() {
        currentUsersIndex = currentUsersIndex >= userModel.count - 1 ? 0 : currentUsersIndex + 1;
    }

    function sessionsCycleSelectPrev() {
        currentSessionsIndex = currentSessionsIndex - 1 < 0 ? sessionModel.rowCount() - 1 : currentSessionsIndex - 1;
    }

    function sessionsCycleSelectNext() {
        currentSessionsIndex = currentSessionsIndex >= sessionModel.rowCount() - 1 ? 0 : currentSessionsIndex + 1;
    }

    function bgFillMode() {
        switch (config.stringValue("backgroundMode")) {
            case "aspect": return Image.PreserveAspectCrop;
            case "fill":   return Image.Stretch;
            case "tile":   return Image.Tile;
            default:       return Image.Pad;
        }
    }

    // integer config value with a default (config.intValue alone can't tell "missing" from 0)
    function cfgInt(key, def) {
        return config.stringValue(key) !== "" ? config.intValue(key) : def;
    }

    function easingFor(name) {
        switch (name) {
            case "linear": return Easing.Linear;
            case "out":    return Easing.OutQuad;
            case "inout":  return Easing.InOutQuad;
            default:       return Easing.InQuad;
        }
    }

    function generateRandomColor() {
        var c = "#";
        for (var i = 0; i < 3; i++) {
            var n = parseInt(Math.random() * 255);
            var h = n.toString(16);
            c += n < 16 ? "0" + h : h;
        }
        return c;
    }

    function startLogin(password) {
        if (loggingIn)
            return;
        loggingIn = true;
        pendingPassword = password;
        passwordInput.enabled = false;
        fadeOverlay.opacity = 1;
        loginTimer.start();
    }

    // Login timer: waits for the fade, then sends the request
    Timer {
        id: loginTimer
        interval: root.fadeDuration + root.fadeHold
        onTriggered: {
            var user = userModel.data(userModel.index(root.currentUsersIndex, 0), root.usernameRole);
            sddm.login(user, root.pendingPassword, root.currentSessionsIndex);
            root.pendingPassword = "";
        }
    }

    // SDDM signals
    Connections {
        target: sddm

        function onLoginFailed() {
            root.loggingIn = false;
            root.pendingPassword = "";
            fadeOverlay.opacity = 0;
            passwordInput.enabled = true;
            passwordInput.clear();
            passwordInput.forceActiveFocus();
            backgroundBorder.border.width = root.errorBorderWidth;
            animateBorder.restart();
        }

        function onLoginSucceeded() {
            animateBorder.stop();
            backgroundBorder.border.width = 0;
            fadeOverlay.opacity = 1;
        }
    }

    // Main UI
    Item {
        id: mainFrame
        property variant geometry: screenModel.geometry(screenModel.primary)
        x: geometry.x
        y: geometry.y
        width: geometry.width
        height: geometry.height

        Shortcut {
            sequences: ["Alt+U", "F2"]
            onActivated: {
                if (!username.visible) { username.visible = true; return; }
                root.usersCycleSelectNext();
            }
        }
        Shortcut {
            sequences: ["Alt+Ctrl+U", "Ctrl+F2"]
            onActivated: {
                if (!username.visible) { username.visible = true; return; }
                root.usersCycleSelectPrev();
            }
        }
        Shortcut {
            sequences: ["Alt+S", "F3"]
            onActivated: {
                if (!sessionName.visible) { sessionName.visible = true; return; }
                root.sessionsCycleSelectNext();
            }
        }
        Shortcut {
            sequences: ["Alt+Ctrl+S", "Ctrl+F3"]
            onActivated: {
                if (!sessionName.visible) { sessionName.visible = true; return; }
                root.sessionsCycleSelectPrev();
            }
        }
        Shortcut {
            sequence: "F10"
            onActivated: if (sddm.canSuspend && !root.loggingIn) sddm.suspend()
        }
        Shortcut {
            sequence: "F11"
            onActivated: if (sddm.canPowerOff && !root.loggingIn) sddm.powerOff()
        }
        Shortcut {
            sequence: "F12"
            onActivated: if (sddm.canReboot && !root.loggingIn) sddm.reboot()
        }
        Shortcut {
            sequence: "F1"
            onActivated: helpMessage.visible = !helpMessage.visible
        }

        // ---- Background ----
        Rectangle {
            id: background
            anchors.fill: parent
            color: config.stringValue("backgroundFill") || "transparent"

            Image {
                id: image
                anchors.fill: parent
                source: config.stringValue("background")
                smooth: true
                fillMode: root.bgFillMode()
                z: 2
            }

            // error border, pulses after a failed login
            Rectangle {
                id: backgroundBorder
                anchors.fill: parent
                z: 4
                color: "transparent"
                border.color: root.errorBorderColor
                border.width: 0

                SequentialAnimation {
                    id: animateBorder
                    running: false
                    loops: Animation.Infinite
                    NumberAnimation { target: backgroundBorder; property: "border.width"; from: root.errorBorderWidth; to: root.errorBorderWidth * 2; duration: 700 }
                    NumberAnimation { target: backgroundBorder; property: "border.width"; from: root.errorBorderWidth * 2; to: root.errorBorderWidth; duration: 400 }
                }
            }

            // only created when blur is actually requested
            Loader {
                z: 3
                anchors.fill: image
                active: config.intValue("blurRadius") > 0
                sourceComponent: FastBlur {
                    source: image
                    radius: config.intValue("blurRadius")
                }
            }
        }

        // ---- Password ----
        TextInput {
            id: passwordInput
            width: parent.width * (config.realValue("passwordInputWidth") || 0.5)
            height: 200 / 96 * root.passwordFontSize
            font.pointSize: root.passwordFontSize
            font.bold: true
            font.letterSpacing: 20 / 96 * root.passwordFontSize
            font.family: root.defaultFont
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            echoMode: config.boolValue("passwordMask") ? TextInput.Password : TextInput.Normal
            color: config.stringValue("passwordTextColor") || root.textColor
            selectionColor: root.textColor
            selectedTextColor: "#000000"
            clip: true
            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter
            passwordCharacter: config.stringValue("passwordCharacter") || "*"
            cursorVisible: config.boolValue("passwordInputCursorVisible")

            onAccepted: {
                if (text !== "" || config.boolValue("passwordAllowEmpty"))
                    root.startLogin(text);
            }

            Rectangle {
                z: -1
                anchors.fill: parent
                color: config.stringValue("passwordInputBackground") || "transparent"
                radius: config.intValue("passwordInputRadius") || 10
            }

            cursorDelegate: Rectangle {
                id: passwordInputCursor
                width: 18 / 96 * root.passwordFontSize
                visible: config.boolValue("passwordInputCursorVisible")
                anchors.verticalCenter: parent.verticalCenter
                onHeightChanged: height = passwordInput.height / 2

                function getCursorColor() {
                    var c = config.stringValue("passwordCursorColor");
                    if (c.length === 7 && c[0] === "#")
                        return c;
                    if (c === "constantRandom" || c === "random")
                        return root.generateRandomColor();
                    return root.textColor;
                }

                color: getCursorColor()
                property color currentColor: color

                SequentialAnimation on color {
                    loops: Animation.Infinite
                    running: config.boolValue("cursorBlinkAnimation")
                    PauseAnimation { duration: 100 }
                    ColorAnimation { from: passwordInputCursor.currentColor; to: "transparent"; duration: 0 }
                    PauseAnimation { duration: 500 }
                    ColorAnimation { from: "transparent"; to: passwordInputCursor.currentColor; duration: 0 }
                    PauseAnimation { duration: 400 }
                }

                Connections {
                    target: passwordInput
                    function onTextEdited() {
                        if (config.stringValue("passwordCursorColor") === "random")
                            passwordInputCursor.currentColor = root.generateRandomColor();
                    }
                }
            }
        }

        // ---- User / session pickers ----
        UsersChoose {
            id: username
            text: root.currentUsername
            visible: config.boolValue("showUsersByDefault")
            width: mainFrame.width / 2.5 / 48 * root.usersFontSize
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: passwordInput.top
                bottomMargin: 40
            }
            onPrevClicked: root.usersCycleSelectPrev()
            onNextClicked: root.usersCycleSelectNext()
        }

        SessionsChoose {
            id: sessionName
            text: root.currentSession
            visible: config.boolValue("showSessionsByDefault")
            width: mainFrame.width / 2.5 / 24 * root.sessionsFontSize
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 30
            }
            onPrevClicked: root.sessionsCycleSelectPrev()
            onNextClicked: root.sessionsCycleSelectNext()
        }

        // Help
        Text {
            id: helpMessage
            visible: false
            text: "Show help - F1\n" +
                  "Cycle select next user - F2 or Alt+u\n" +
                  "Cycle select previous user - Ctrl+F2 or Alt+Ctrl+u\n" +
                  "Cycle select next session - F3 or Alt+s\n" +
                  "Cycle select previous session - Ctrl+F3 or Alt+Ctrl+s\n" +
                  "Suspend - F10\n" +
                  "Poweroff - F11\n" +
                  "Reboot - F12"
            color: root.textColor
            font.pointSize: root.helpFontSize
            font.family: root.helpFont
            anchors {
                top: parent.top
                topMargin: 30
                left: parent.left
                leftMargin: 30
            }
        }

        Component.onCompleted: passwordInput.forceActiveFocus()
    }

    // Optional hidden cursor
    Loader {
        active: config.boolValue("hideCursor") || false
        anchors.fill: parent
        sourceComponent: MouseArea {
            enabled: false
            cursorShape: Qt.BlankCursor
        }
    }

    // Fade-to-black overlay (direct child of root, above everything)
    Rectangle {
        id: fadeOverlay
        anchors.fill: parent
        z: 100
        color: root.fadeColor
        // starts opaque when an intro fade is configured, so the greeter fades in
        opacity: root.introFadeDuration > 0 ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: root.overlayDuration
                easing.type: root.easingFor(root.fadeEasing)
            }
        }
    }

    // restores the normal fade duration once the intro fade has finished
    Timer {
        id: introDoneTimer
        interval: root.introFadeDuration + 50
        onTriggered: root.overlayDuration = root.fadeDuration
    }

    Component.onCompleted: {
        if (root.introFadeDuration > 0) {
            root.overlayDuration = root.introFadeDuration;
            fadeOverlay.opacity = 0;
            introDoneTimer.start();
        }
    }
}
