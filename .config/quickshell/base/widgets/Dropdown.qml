import QtQuick
import QtQuick.Controls
import qs.config

// Themed ComboBox. options: [{ value, label }]; `current` is the selected value; emits selected(value).
ComboBox {
    id: root

    property var options: []
    property var current
    signal selected(var value)

    implicitWidth: 200
    implicitHeight: 34
    model: options
    textRole: "label"
    valueRole: "value"
    currentIndex: options.findIndex(o => o.value === current)
    onActivated: index => selected(options[index].value)

    font.family: Appearance.font.family
    font.pixelSize: Appearance.font.size

    contentItem: StyledText {
        leftPadding: 12
        rightPadding: 30
        verticalAlignment: Text.AlignVCenter
        text: root.currentIndex >= 0 ? root.options[root.currentIndex].label : "—"
        elide: Text.ElideRight
    }

    indicator: MaterialIcon {
        x: root.width - width - 8
        anchors.verticalCenter: parent.verticalCenter
        icon: "expand_more"
        color: Appearance.colors.muted
    }

    background: Rectangle {
        radius: 12
        color: root.hovered ? Appearance.colors.surfaceHover : Appearance.colors.surface
        border.width: root.popup.visible ? 1 : 0
        border.color: Appearance.colors.accent
    }

    delegate: ItemDelegate {
        id: item
        required property var modelData
        required property int index
        width: root.popup.width - 8
        x: 4
        height: 32
        highlighted: root.highlightedIndex === index
        contentItem: StyledText {
            text: item.modelData.label
            font.bold: item.index === root.currentIndex
            color: item.index === root.currentIndex ? Appearance.colors.accent : Appearance.colors.fg
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 8
            color: item.highlighted ? Appearance.colors.surfaceHover : "transparent"
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(list.contentHeight + 8, 300)
        padding: 0
        topPadding: 4
        bottomPadding: 4

        contentItem: ListView {
            id: list
            clip: true
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds
        }

        background: Rectangle {
            radius: 12
            color: Appearance.colors.bg
            border.width: 1
            border.color: Appearance.colors.border
        }
    }
}
