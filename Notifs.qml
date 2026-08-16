pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// glueqs is the notification daemon: keeps history and emits toasts.
Singleton {
    id: root

    property var list: []
    property int unread: 0
    signal toast(var n)

    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: false
        actionsSupported: false
        onNotification: n => {
            const e = {
                app: (n.appName ?? "").toUpperCase(),
                summary: n.summary ?? "",
                body: n.body ?? "",
                time: Qt.formatTime(new Date(), "HH:mm")
            };
            root.list = [e].concat(root.list).slice(0, 30);
            root.unread++;
            root.toast(e);
            n.dismiss();
        }
    }

    function clear() {
        list = [];
        unread = 0;
    }
    function markRead() { unread = 0 }
}
