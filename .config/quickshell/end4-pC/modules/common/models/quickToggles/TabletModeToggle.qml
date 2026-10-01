import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Tablet Mode")
    toggled: GlobalStates.tabletMode
    icon: "tablet"

    mainAction: () => {
        Config.options.tablet.enable = !Config.options.tablet.enable
    }

    tooltipText: Translation.tr("Touch-optimized mode")
}
