-- decorations.lua
hl.config({
    decoration = {
        rounding       = 7,
        rounding_power = 2,

        active_opacity   = 1,
        inactive_opacity = 0.85,

        shadow = {
            enabled      = true,
            range        = 99,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 4,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },
})
