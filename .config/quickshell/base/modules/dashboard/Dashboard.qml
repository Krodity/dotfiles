import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Hangs under the clock: date, media controls, and cards out to the wallpaper and theme pickers.
BarPopup {
    id: root

    name: "dashboard"
    cardWidth: 460

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Time.longDate
        font.bold: true
        font.pixelSize: 15
    }

    MediaCard {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        uniformCellSizes: true
        spacing: 10

        WallpaperButton {
            Layout.fillWidth: true
        }
        ThemeButton {
            Layout.fillWidth: true
        }
    }
}
