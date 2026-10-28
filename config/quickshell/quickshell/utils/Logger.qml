pragma Singleton
import QtQuick

QtObject {
    id: root

    // Global toggle: Set default level to Warning so debug logs are hidden by default
    property int defaultLevel: LoggingCategory.Warning

    // Category for ColorManager & Themes
    readonly property LoggingCategory colors: LoggingCategory {
        name: "hecate.colors"
        defaultLogLevel: root.defaultLevel
    }

    // Category for Window Dock & Hyprland client queries
    readonly property LoggingCategory dock: LoggingCategory {
        name: "hecate.dock"
        defaultLogLevel: root.defaultLevel
    }

    // Category for Workspace management
    readonly property LoggingCategory workspaces: LoggingCategory {
        name: "hecate.workspaces"
        defaultLogLevel: root.defaultLevel
    }

    // Category for System/IO Process calls
    readonly property LoggingCategory system: LoggingCategory {
        name: "hecate.system"
        defaultLogLevel: root.defaultLevel
    }
}
