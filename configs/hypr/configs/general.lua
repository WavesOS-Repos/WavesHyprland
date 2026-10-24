-- general.lua
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,

        col = {
            active_border = {
                colors = { rgba(colors.primary), rgba(colors.secondary) },
                angle = 45
            },
            inactive_border = rgba(colors.outline, "aa"),
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})
