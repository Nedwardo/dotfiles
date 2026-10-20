import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "notificationVolume"

    StyledText {
        width: parent.width
        text: I18n.tr("Notification Sound Volume")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: I18n.tr("Controls the playback level of DMS notification and system sounds (message, login, power, volume-change). Independent of the master output volume.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "volume"
        label: I18n.tr("Volume")
        description: I18n.tr("Notification sound loudness")
        defaultValue: 100
        minimum: 0
        maximum: 100
        unit: "%"
        leftIcon: "notifications_off"
        rightIcon: "notifications_active"
    }

    ToggleSetting {
        settingKey: "muted"
        label: I18n.tr("Mute Notification Sounds")
        description: I18n.tr("Silence all notification and system sounds")
        defaultValue: false
    }

    StyledRect {
        width: 160
        height: 40
        radius: Theme.cornerRadius
        color: testArea.containsMouse ? Theme.primaryHover : Theme.primary

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXS

            DankIcon {
                name: "play_arrow"
                size: Theme.iconSize - 4
                color: Theme.onPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: I18n.tr("Play test sound")
                color: Theme.onPrimary
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: testArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AudioService.playNormalNotificationSound()
        }
    }
}
