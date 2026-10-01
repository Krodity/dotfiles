import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

// HSV colour picker: saturation/value square, hue bar, opacity bar, exact hex field.
// Set `value`; listen to picked(color) for edits.
ColumnLayout {
    id: root

    property color value: "white"
    signal picked(color c)

    // Working HSV copy so dragging to grey/black doesn't lose the hue.
    property real h: 0
    property real s: 0
    property real v: 1
    property real a: 1
    property bool editing: false

    function sync() {
        if (value.hsvHue >= 0) h = value.hsvHue;
        s = value.hsvSaturation;
        v = value.hsvValue;
        a = value.a;
    }

    function emit() {
        picked(Qt.hsva(h, s, v, a));
    }

    onValueChanged: if (!editing) sync()
    Component.onCompleted: sync()
    spacing: 10

    // Saturation → right, value → up.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 150
        radius: 12
        color: Qt.hsva(root.h, 1, 1, 1)

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "white" }
                GradientStop { position: 1; color: "transparent" }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: "black" }
            }
        }

        Rectangle {
            x: root.s * parent.width - width / 2
            y: (1 - root.v) * parent.height - height / 2
            width: 16
            height: 16
            radius: 8
            color: "transparent"
            border.width: 2
            border.color: root.v > 0.5 && root.s < 0.5 ? "black" : "white"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            onPressed: mouse => { root.editing = true; update(mouse); }
            onPositionChanged: mouse => update(mouse)
            onReleased: root.editing = false
            function update(mouse) {
                root.s = Math.max(0, Math.min(1, mouse.x / width));
                root.v = 1 - Math.max(0, Math.min(1, mouse.y / height));
                root.emit();
            }
        }
    }

    component Bar: Rectangle {
        id: bar
        property real position
        signal moved(real position)

        Layout.fillWidth: true
        implicitHeight: 14
        radius: 7

        Rectangle {
            x: bar.position * (bar.width - width)
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: "white"
            border.width: 2
            border.color: "#40000000"
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onPressed: mouse => { root.editing = true; bar.moved(Math.max(0, Math.min(1, mouse.x / width))); }
            onPositionChanged: mouse => bar.moved(Math.max(0, Math.min(1, mouse.x / width)))
            onReleased: root.editing = false
        }
    }

    Bar {
        position: root.h
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0 / 6; color: "#ff0000" }
            GradientStop { position: 1 / 6; color: "#ffff00" }
            GradientStop { position: 2 / 6; color: "#00ff00" }
            GradientStop { position: 3 / 6; color: "#00ffff" }
            GradientStop { position: 4 / 6; color: "#0000ff" }
            GradientStop { position: 5 / 6; color: "#ff00ff" }
            GradientStop { position: 6 / 6; color: "#ff0000" }
        }
        onMoved: p => { root.h = Math.min(p, 0.999); root.emit(); }
    }

    Bar {
        position: root.a
        color: Appearance.colors.surface
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.hsva(root.h, root.s, root.v, 0) }
            GradientStop { position: 1; color: Qt.hsva(root.h, root.s, root.v, 1) }
        }
        onMoved: p => { root.a = p; root.emit(); }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: 10
            color: root.value
            border.width: 1
            border.color: Appearance.colors.border
        }

        TextField {
            id: hexField
            Layout.fillWidth: true
            text: String(root.value)
            color: acceptableInput ? Appearance.colors.fg : "#f38ba8"
            font.family: "monospace"
            font.pixelSize: Appearance.font.size
            selectByMouse: true
            validator: RegularExpressionValidator {
                regularExpression: /#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})/
            }
            background: Rectangle {
                radius: 10
                color: Appearance.colors.surface
                border.width: hexField.activeFocus ? 1 : 0
                border.color: Appearance.colors.accent
            }
            onAccepted: root.picked(Qt.color(text.startsWith("#") ? text : `#${text}`))
        }

        StyledText {
            text: `${Math.round(root.a * 100)}%`
            color: Appearance.colors.muted
            font.pixelSize: Appearance.font.small
        }
    }
}
