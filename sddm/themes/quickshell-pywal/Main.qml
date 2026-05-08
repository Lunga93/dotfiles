// Entry point for the quickshell-pywal SDDM theme. Reads runtime colors and
// wallpaper through SDDM's config system (theme.conf merged with
// theme.conf.user, which apply-theme writes via /var/lib/sddm-theme).

import QtQuick
import QtQuick.Effects
import "."

Item {
    id: root

    width: 1920
    height: 1080

    property int currentUserIndex: userModel ? userModel.lastIndex : 0
    property int currentSessionIndex: sessionModel ? sessionModel.lastIndex : 0
    property string errorText: ""
    property bool authenticating: false

    Colors {
        id: colors
        background: config.background  || "#1c1c1e"
        foreground: config.foreground  || "#f5f5f7"
        accent:     config.accent      || "#0a84ff"
        viewBg:     config.viewBg      || "#26262a"
    }

    // SDDM UserModel roles (src/greeter/UserModel.h):
    //   NameRole = UserRole+1, RealNameRole = +2, HomeDirRole = +3,
    //   IconRole = +4, NeedsPasswordRole = +5
    function userField(idx, role) {
        if (!userModel) return "";
        if (idx < 0 || idx >= userModel.count) return "";
        const i = userModel.index(idx, 0);
        return userModel.data(i, role);
    }

    function userInfo(idx) {
        return {
            name:          userField(idx, Qt.UserRole + 1) || "",
            realName:      userField(idx, Qt.UserRole + 2) || "",
            icon:          userField(idx, Qt.UserRole + 4) || "",
            needsPassword: true
        };
    }

    Rectangle {
        anchors.fill: parent
        color: colors.background
    }

    Image {
        id: wallpaperImg
        anchors.fill: parent
        source: (config.wallpaperPath && config.wallpaperPath.length > 0)
            ? "file://" + config.wallpaperPath
            : "file:///var/lib/sddm-theme/wallpaper"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 32
            blur: 0.55
            brightness: -0.15
            saturation: -0.05
        }
    }

    Rectangle {
        anchors.fill: parent
        color: colors.dimOverlay
    }

    LoginCard {
        id: loginCard
        anchors.centerIn: parent
        colors: colors
        userInfo: root.userInfo(root.currentUserIndex)
        errorText: root.errorText
        authenticating: root.authenticating
        // SDDM exposes keyboard.capsLock (bool) on most versions; guard
        // against it being missing or non-boolean in test mode.
        capsLock: (typeof keyboard !== "undefined" && keyboard !== null
                  && keyboard.capsLock === true)
        onSubmit: function(password) {
            root.tryLogin(password);
        }
    }

    ClockDisplay {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 28
        anchors.rightMargin: 32
        colors: colors
    }

    SessionSelector {
        id: sessionPicker
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 24
        anchors.leftMargin: 24
        colors: colors
        sessionModelRef: sessionModel
        currentIndex: root.currentSessionIndex
        onSelected: function(newIndex) {
            root.currentSessionIndex = newIndex;
        }
    }

    PowerControls {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 24
        anchors.rightMargin: 24
        colors: colors
        sddmRef: sddm
    }

    function tryLogin(password) {
        if (!password || password.length === 0) return;
        if (!sddm) return;
        const u = userField(root.currentUserIndex, Qt.UserRole + 1);
        if (!u) {
            root.errorText = "No user selected.";
            return;
        }
        root.errorText = "";
        root.authenticating = true;
        sddm.login(u, password, root.currentSessionIndex);
    }

    Connections {
        target: sddm
        ignoreUnknownSignals: true

        function onLoginSucceeded() {
            root.authenticating = false;
            successAnim.start();
        }

        function onLoginFailed() {
            root.authenticating = false;
            root.errorText = "Incorrect password";
            loginCard.shakeNow();
            loginCard.clearPassword();
            loginCard.focusPassword();
        }
    }

    SequentialAnimation {
        id: successAnim
        ParallelAnimation {
            NumberAnimation {
                target: loginCard
                property: "scale"
                to: 1.04
                duration: Theme.durationMed
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Theme.durationXSlow
                easing.type: Easing.InCubic
            }
        }
    }

    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationXSlow; easing.type: Easing.OutCubic }
    }

    focus: true
    Keys.onEscapePressed: {
        loginCard.clearPassword();
    }
}
