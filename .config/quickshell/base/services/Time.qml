pragma Singleton

import Quickshell
import QtQuick

// One clock for the whole shell, per the guide's Time singleton.
Singleton {
    id: root

    readonly property string date: Qt.formatDateTime(clock.date, "ddd, MMM d")
    readonly property string longDate: Qt.formatDateTime(clock.date, "dddd, MMMM d")
    readonly property string time: Qt.formatDateTime(clock.date, "h:mm AP")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
