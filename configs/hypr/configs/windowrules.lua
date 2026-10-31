-- windowrules.lua
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name = "thunar-transparency",
    match = {
        class = "^(thunar)$"
    },
    -- Opacity expects a string containing "active inactive"
    opacity = "0.85 0.75" 
})

hl.window_rule({
    name  = "qylock-sddm-picker",
    match = { class = "qylock-sddm" },
    float = true,
    size  = "900 600",
})

hl.window_rule({
    name  = "sysupdate",
    match = { class = "sysupdate" },
    float = true,
    size  = "900 600",
})

hl.window_rule({
    name  = "floating-terminal",
    match = { class = "floating-terminal" },
    float = true,
    size  = "900 600",
})

hl.window_rule({
    name = "floating-editor",
    match = { class = "editor" },
    float = true,
    size = "1000 700",
})

hl.window_rule({
    name  = "hypr-settings",
    match = { class = "hypr-settings" },
    float = true,
    size  = "900 600",
})

hl.window_rule({
    name = "hypr-keybinds",
    match = { class = "hypr-keybinds" },
    float = true,
    center = true,
    size = "1000 650",
})

hl.window_rule({
    name  = "hyprpm-plugins",
    match = { class = "hyprpm-plugins" },
    float = true,
    size  = "900 600",
})

hl.window_rule({
    name = "yazi",
    match = { class = "yazi" },
    float = true,
    size = "1000 700",
})

hl.window_rule({
    name = "eww",
    match = { class = "eww" },
    float = true,
    pin = true,
    opaque = false,
})
