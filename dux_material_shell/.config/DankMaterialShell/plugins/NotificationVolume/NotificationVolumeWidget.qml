import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Bar + Control Center surface for the notification volume slider.
PluginComponent {
    id: root

    property var popoutService: null
    layerNamespacePlugin: "notification-volume"

    readonly property int volumePercent: {
        const v = pluginData ? pluginData.volume : undefined
        if (v === undefined || v === null || isNaN(v))
            return 100
        return Math.max(0, Math.min(100, Math.round(v)))
    }
    readonly property bool muted: pluginData ? pluginData.muted === true : false
    readonly property bool silent: muted || volumePercent === 0
    readonly property string statusIcon: silent ? "notifications_off" : "notifications_active"

    // Persist and apply immediately for instant audio feedback. The daemon also
    // reacts to the settings change, so AudioService stays authoritative.
    function setVolume(v) {
        const clamped = Math.max(0, Math.min(100, Math.round(v)))
        AudioService.notificationsVolume = clamped / 100
        if (clamped > 0 && root.muted) {
            AudioService.notificationsAudioMuted = false
            if (pluginService)
                pluginService.savePluginData(pluginId, "muted", false)
        }
        if (pluginService)
            pluginService.savePluginData(pluginId, "volume", clamped)
    }

    function toggleMute() {
        const next = !root.muted
        AudioService.notificationsAudioMuted = next
        if (pluginService)
            pluginService.savePluginData(pluginId, "muted", next)
    }

    // ---- Bar pills ----------------------------------------------------------
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.statusIcon
                size: Theme.iconSize - 2
                color: root.silent ? Theme.surfaceVariantText : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.silent ? I18n.tr("Muted") : (root.volumePercent + "%")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.statusIcon
                size: Theme.iconSizeSmall
                color: root.silent ? Theme.surfaceVariantText : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.volumePercent
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall - 1
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ---- Bar popout ---------------------------------------------------------
    popoutWidth: 340
    popoutHeight: 168

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: I18n.tr("Notification Volume")
            detailsText: I18n.tr("Volume of notification & system sounds")
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                DankSlider {
                    id: popoutSlider
                    width: parent.width
                    minimum: 0
                    maximum: 100
                    value: root.volumePercent
                    unit: "%"
                    showValue: true
                    leftIcon: "notifications_off"
                    rightIcon: "notifications_active"
                    onSliderValueChanged: newValue => root.setVolume(newValue)

                    Binding {
                        target: popoutSlider
                        property: "value"
                        value: root.volumePercent
                        when: !popoutSlider.isDragging
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 40
                        radius: Theme.cornerRadius
                        color: muteArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: root.muted ? "notifications_off" : "notifications_active"
                                size: Theme.iconSize - 4
                                color: root.muted ? Theme.error : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: root.muted ? I18n.tr("Unmute") : I18n.tr("Mute")
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: muteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMute()
                        }
                    }

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 40
                        radius: Theme.cornerRadius
                        color: testArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "play_arrow"
                                size: Theme.iconSize - 4
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Test")
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
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
            }
        }
    }

    // ---- Control Center integration ----------------------------------------
    ccWidgetIcon: root.statusIcon
    ccWidgetPrimaryText: I18n.tr("Notifications")
    ccWidgetSecondaryText: root.silent ? I18n.tr("Muted") : (root.volumePercent + "%")
    ccWidgetIsActive: !root.silent
    ccWidgetIsToggle: true
    onCcWidgetToggled: root.toggleMute()

    ccDetailHeight: 64
    ccDetailContent: Component {
        Rectangle {
            color: "transparent"

            DankSlider {
                id: ccSlider
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM
                minimum: 0
                maximum: 100
                value: root.volumePercent
                unit: "%"
                showValue: true
                leftIcon: "notifications_off"
                rightIcon: "notifications_active"
                onSliderValueChanged: newValue => root.setVolume(newValue)

                Binding {
                    target: ccSlider
                    property: "value"
                    value: root.volumePercent
                    when: !ccSlider.isDragging
                }
            }
        }
    }
}
