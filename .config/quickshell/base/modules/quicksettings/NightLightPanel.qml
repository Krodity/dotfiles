import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Night light dropdown: hangs under the Night light tile, same width. Icon-only Warmer / Cooler buttons step
// the temperature by NightLight.step per press (hold to repeat); either one turns the filter on.
// Opened/closed by the tile's chevron (quick settings `section`); placed in BarPopup's overlay layer.
// A plain item, not a Controls Popup: a Popup's overlay ate the chevron click, so it couldn't be collapsed.
Rectangle {
    id: root

    property bool open

    implicitHeight: buttons.implicitHeight + 20
    radius: 18
    color: Appearance.colors.bg
    border.width: 1
    border.color: Appearance.colors.border

    visible: opacity > 0
    opacity: open ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: Appearance.anim.fast }
    }

    component StepButton: Rectangle {
        id: btn

        property string icon
        property int dir
        readonly property bool atLimit: dir < 0 ? NightLight.temperature <= NightLight.minTemp
                                                : NightLight.temperature >= NightLight.maxTemp

        Layout.fillWidth: true
        implicitHeight: 38
        radius: 12
        // Same fill and outline as the dropdown itself; hover/press only tint it.
        color: mouse.pressed ? Appearance.colors.surfaceHover
             : mouse.containsMouse ? Qt.alpha(Appearance.colors.surfaceHover, 0.6) : Appearance.colors.bg
        border.width: 1
        border.color: Appearance.colors.border
        opacity: atLimit ? 0.4 : 1
        Behavior on color {
            ColorAnimation { duration: Appearance.anim.fast }
        }

        MaterialIcon {
            anchors.centerIn: parent
            icon: btn.icon
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                NightLight.adjust(btn.dir);
                repeat.interval = 400;
                repeat.start();
            }
            onReleased: repeat.stop()
            onCanceled: repeat.stop()
        }

        // Hold: first repeat after 400 ms, then every 150 ms.
        Timer {
            id: repeat
            repeat: true
            onTriggered: {
                interval = 150;
                if (btn.atLimit) stop();
                else NightLight.adjust(btn.dir);
            }
        }
    }

    RowLayout {
        id: buttons
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        StepButton {
            icon: "wb_twilight" // warmer
            dir: -1
        }

        StepButton {
            icon: "wb_sunny" // cooler
            dir: 1
        }
    }
}
