pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// The notification daemon (owns org.freedesktop.Notifications while this shell runs) + the list of
// notifications currently shown as toasts. Toasts are drawn by modules/notifications/Toasts.qml.
//
// Lifecycle: a new notification is tracked and put at the top of `toasts`. The toast's own timer (or the
// user) then closes it through dismiss()/expire() below, which tell the sending app too. If the app itself
// closes/replaces it, the Notification object updates or goes away and the list follows.
Singleton {
    id: root

    property var toasts: []          // Notification objects, newest first
    readonly property int maxToasts: 4
    readonly property int defaultTimeout: 6000   // ms, when the app doesn't ask for one

    readonly property int criticalTimeout: 10000 // ms

    // How long a toast stays up, in ms. Every toast times out (by design there's no close button):
    // critical = criticalTimeout; otherwise the app's expire_timeout (Quickshell gives seconds; <= 0 = default),
    // capped at 30 s.
    function timeoutFor(n) {
        if (n?.urgency === NotificationUrgency.Critical) return criticalTimeout;
        return n?.expireTimeout > 0 ? Math.min(30000, Math.round(n.expireTimeout * 1000)) : defaultTimeout;
    }

    function remove(n) {
        toasts = toasts.filter(t => t && t !== n);
    }

    // User closed it (✕ or click): tells the app "dismissed".
    function dismiss(n) {
        remove(n);
        n?.dismiss();
    }

    // Timed out: tells the app "expired".
    function expire(n) {
        remove(n);
        n?.expire();
    }

    // Run an action button (or the "default" action on a click), then close unless it's resident.
    function invoke(n, action) {
        const resident = n?.resident;
        action?.invoke();
        if (!resident) dismiss(n);
    }

    // notify-send -i and many apps send their icon as the image hint, which Quickshell exposes as
    // "image://icon/<name-or-path>". That's an icon, not a picture: show it in the header, not as a thumbnail.
    function isIconImage(n) {
        return (n?.image ?? "").startsWith("image://icon/");
    }

    // Header icon: app_icon → icon-type image → the sender's desktop entry → generic.
    function iconFor(n) {
        const name = n?.appIcon ?? "";
        if (name.startsWith("/")) return `file://${name}`;
        if (name.startsWith("file://") || name.startsWith("image://")) return name;
        if (name) {
            const p = Quickshell.iconPath(name, true);
            if (p) return p;
        }
        if (isIconImage(n)) return n.image;
        const entry = n?.desktopEntry ? DesktopEntries.byId(n.desktopEntry) : null;
        if (entry?.icon) {
            const p = Quickshell.iconPath(entry.icon, true);
            if (p) return p;
        }
        return Quickshell.iconPath("dialog-information", true);
    }

    function defaultAction(n) {
        return (n?.actions ?? []).find(a => a.identifier === "default") ?? null;
    }

    // After a hot reload the server (keepOnReload) still tracks the notifications, but this list starts
    // empty; show them again so none are left tracked-but-invisible.
    Component.onCompleted: toasts = [...server.trackedNotifications.values].reverse().slice(0, maxToasts)

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        persistenceSupported: false

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.remove(n));
            // Overflow: the oldest shown toast expires to make room.
            const shown = [n, ...root.toasts.filter(t => t && t !== n)];
            shown.slice(root.maxToasts).forEach(old => old.expire());
            root.toasts = shown.slice(0, root.maxToasts);
        }
    }
}
