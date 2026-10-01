import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// One minimal notification toast: [icon] summary / body [picture], plus action buttons only if the app
// sends any. No close button or countdown bar: every toast times out on its own (hover quietly pauses it;
// a click runs the app's "default" action if it has one, else just closes it early). Critical = accent ring
// and a longer timeout. Slides in from the right; animates out before telling Notifs to drop it.
Item {
    id: root

    required property var notification
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property int timeout: Notifs.timeoutFor(notification)
    property bool leaving: false
    property string leaveAs: "dismiss"   // or "expire"

    // Start the exit animation; the notification is closed once it's finished.
    function close(as) {
        if (leaving) return;
        leaveAs = as;
        leaving = true;
    }

    width: parent?.width ?? Appearance.popup.width
    implicitHeight: leaving ? 0 : card.implicitHeight
    clip: true
    Behavior on implicitHeight {
        NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
    }

    // Time left, 1 → 0 (drives the auto-close; not drawn). Paused while hovered; restarted when the app
    // replaces the content.
    property real remaining: 1
    NumberAnimation on remaining {
        id: countdown
        running: !root.leaving
        paused: running && hover.hovered
        from: 1
        to: 0
        duration: Math.max(1, root.timeout)
        onFinished: if (root.remaining <= 0) root.close("expire")
    }
    Connections {
        target: root.notification
        function onSummaryChanged() { countdown.restart(); }
        function onBodyChanged() { countdown.restart(); }
    }

    Timer {
        // Runs after the slide-out: now actually close it (this destroys the delegate).
        running: root.leaving
        interval: Appearance.anim.normal + 20
        onTriggered: root.leaveAs === "expire" ? Notifs.expire(root.notification) : Notifs.dismiss(root.notification)
    }

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: content.implicitHeight + 24
        radius: 16
        color: Appearance.colors.bg
        border.width: root.critical ? 2 : 1
        border.color: root.critical ? Appearance.colors.accent : Appearance.colors.border
        clip: true

        // Slide in from the right on creation, out to the right when leaving.
        property real slide: 1
        Component.onCompleted: slide = 0
        opacity: root.leaving ? 0 : 1 - slide
        transform: Translate {
            x: root.leaving ? 40 : card.slide * 40
        }
        Behavior on slide {
            NumberAnimation { duration: Appearance.anim.normal; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Appearance.anim.normal }
        }

        HoverHandler {
            id: hover
        }
        TapHandler {
            onTapped: {
                const a = Notifs.defaultAction(root.notification);
                if (a) Notifs.invoke(root.notification, a);
                else root.close("dismiss");
            }
        }

        ColumnLayout {
            id: content

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 8

            // [icon]  summary / body  [picture]
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                IconImage {
                    Layout.alignment: Qt.AlignTop
                    implicitSize: 24
                    source: Notifs.iconFor(root.notification)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.notification?.summary || root.notification?.appName || ""
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: root.notification?.body ?? ""
                        textFormat: Text.PlainText
                        font.pixelSize: Appearance.font.small
                        color: Appearance.colors.muted
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                // Real pictures only (album art, screenshots); icon-type images are the icon on the left.
                ClippingRectangle {
                    visible: (root.notification?.image ?? "") !== "" && !Notifs.isIconImage(root.notification)
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 10
                    color: Appearance.colors.surface

                    Image {
                        anchors.fill: parent
                        source: root.notification?.image ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            // Action buttons, only when the app sends some (the "default" action is the click on the toast).
            RowLayout {
                Layout.fillWidth: true
                visible: actionRepeater.count > 0
                spacing: 6

                Repeater {
                    id: actionRepeater
                    model: (root.notification?.actions ?? []).filter(a => a.identifier !== "default")

                    HoverRect {
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 10
                        baseColor: Appearance.colors.surface
                        onClicked: Notifs.invoke(root.notification, modelData)

                        StyledText {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.modelData.text
                            font.pixelSize: Appearance.font.small
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
