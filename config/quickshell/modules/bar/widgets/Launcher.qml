import qs.config
import qs.components

// Opens the app launcher. [widgets.launcher] icon: "arch" (default), "owl", or any glyph.
Pill {
    widget: "launcher"
    panel: "launcher"
    icon: Theme.glyph(cfg.icon, "arch")
    fg: Config.color(widget, "color", Theme.primary)
    tooltip: "Apps"
}
