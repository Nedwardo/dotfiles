import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins

// Background surface: authoritative applier. Keeps AudioService's notification
// sound volume/mute in sync with the saved plugin settings on startup and on
// every change, independent of whether the bar/CC widget is placed anywhere.
PluginComponent {
    id: root

    readonly property int volumePercent: {
        const v = pluginData ? pluginData.volume : undefined
        if (v === undefined || v === null || isNaN(v))
            return 100
        return Math.max(0, Math.min(100, Math.round(v)))
    }
    readonly property bool muted: pluginData ? pluginData.muted === true : false

    function apply() {
        AudioService.notificationsVolume = volumePercent / 100
        AudioService.notificationsAudioMuted = muted
    }

    onVolumePercentChanged: apply()
    onMutedChanged: apply()
    Component.onCompleted: apply()

    // The sound players are lazily (re)created; reassert our values whenever
    // availability flips so the Qt.binding on their volume picks up our number.
    Connections {
        target: AudioService
        function onSoundsAvailableChanged() {
            root.apply()
        }
    }

    function persist(key, value) {
        if (pluginService)
            pluginService.savePluginData(pluginId, key, value)
    }

    // CLI / keybind control, mirroring `dms ipc call audio setvolume`.
    //   dms ipc call notifvol get
    //   dms ipc call notifvol set 40
    //   dms ipc call notifvol mute | unmute | toggle
    IpcHandler {
        target: "notifvol"

        function get(): string {
            const applied = Math.round(AudioService.notificationsVolume * 100)
            return `${applied} ${AudioService.notificationsAudioMuted ? "muted" : "unmuted"}`
        }

        function set(percent: string): string {
            const n = parseInt(percent, 10)
            if (isNaN(n))
                return "ERROR: expected an integer percent (0-100)"
            const clamped = Math.max(0, Math.min(100, n))
            root.persist("volume", clamped)
            if (clamped > 0 && root.muted)
                root.persist("muted", false)
            return `OK: notification volume ${clamped}%`
        }

        function mute(): string {
            root.persist("muted", true)
            return "OK: muted"
        }

        function unmute(): string {
            root.persist("muted", false)
            return "OK: unmuted"
        }

        function toggle(): string {
            const next = !root.muted
            root.persist("muted", next)
            return next ? "OK: muted" : "OK: unmuted"
        }
    }
}
