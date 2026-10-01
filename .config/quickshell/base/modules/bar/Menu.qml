import Quickshell
import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking


PanelWindow {
  anchors {
    top: true
    left: true
    right: true
  }

  implicitHeight: 30

Process {

    id: dateProc
    running: true

    stdout: StdioCollector {
        onStreamFinsihed: clock.text = this.text
    }
}


Timer {



    //1000 milliseconds is a second
    interval:1000

    //start the timer immediately
    running: true

    //repeats the timer after finishing
    repeat: true

    //when the timer triggers, set the running property of the process to true, which reruns it if stopped
    onTriggered: dateProc.running = true
}





}