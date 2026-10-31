-- keybinds.lua
local mainMod = "SUPER"

-- ── Apps ──────────────────────────────────────────────────
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + RETURN",
    hl.dsp.exec_cmd("kitty --class floating-terminal"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + B",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/open-default-browser.sh"))
hl.bind(mainMod .. " + SHIFT + B",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/default_browser.sh"))
hl.bind(mainMod .. " + C",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/cliphist.sh c"))
hl.bind(mainMod .. " + ALT + W",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/cliphist.sh w"))
hl.bind(mainMod .. " + SHIFT + D",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi-emoji.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
-- Default editor
hl.bind(mainMod .. " + Y",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/open-default-editor.sh"))
hl.bind(mainMod .. " + SHIFT + Y",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/default_editor.sh"))
hl.bind(mainMod .. " + SHIFT + E",
    hl.dsp.exec_cmd("kitty --class yazi -e yazi"))
-- ── Rice ──────────────────────────────────────────────────
hl.bind(mainMod .. " + G",
    hl.dsp.exec_cmd("kitty --class hypr-settings -e ~/.config/hypr/scripts/settings.sh"))
hl.bind(mainMod .. " + W",
    hl.dsp.exec_cmd("python ~/.config/wallfliper/main.py"))
hl.bind(mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-layout.sh"))
hl.bind(mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi_theme.sh"))
hl.bind(mainMod .. " + A",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind(mainMod .. " + U",
    hl.dsp.exec_cmd("kitty --class sysupdate -e ~/.config/hypr/scripts/systemupdate.sh"))
hl.bind(mainMod .. " + SHIFT + I",
    hl.dsp.exec_cmd("kitty --class qylock-sddm -e bash -lc '~/.config/qylock/sddm.sh; echo; read -n 1 -p \"Press any key...\"'"))
hl.bind(mainMod .. " + H",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds.sh"))
hl.bind(mainMod .. " + X",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/wlogout.sh"))
hl.bind(
  mainMod .. " + SHIFT + C",
  hl.dsp.exec_cmd("~/.config/hypr/scripts/colorpicker.sh")
)
hl.bind(mainMod .. " + T",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-switch.sh")
)
hl.bind(mainMod .. " + SHIFT + F",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/eww-widget.sh")
)

-- ── Window ────────────────────────────────────────────────
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + ALT + V",
    hl.dsp.exec_cmd("hyprctl dispatch togglefloating"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move window (hjkl)
hl.bind(mainMod .. " + CTRL + H",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind(mainMod .. " + CTRL + J",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))
hl.bind(mainMod .. " + CTRL + K",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind(mainMod .. " + CTRL + L",
    hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))

-- ── Workspaces ────────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key,
        hl.dsp.exec_cmd("hyprctl dispatch movetoworkspacesilent " .. i))
end

hl.bind(mainMod .. " + S",
    hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- ── Zoom ──────────────────────────────────────────────────
hl.bind(mainMod .. " + Z",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh"))
hl.bind(mainMod .. " + SHIFT + Z",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh --in"))
hl.bind(mainMod .. " + ALT + Z",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom.sh --out"))

-- ── System / bar ─────────────────────────────────────────
hl.bind(mainMod .. " + CTRL + R",
    hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("CTRL + ESCAPE",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-reload.sh --toggle"))
hl.bind("CTRL + ALT + ESCAPE",
    hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-reload.sh --reload"))

-- Window switcher
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("rofi -show window"))
hl.bind("ALT + TAB",         hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/themes/rofi-window.rasi"))

-- Optional: Pyprland (only if installed)
-- hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("pypr toggle_minimized"))
-- hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("pypr toggle_minimized"))

-- ── Media (locked) ────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true })
hl.bind("XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true })
hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ── Screen zoom (full desktop magnifier) ──────────────────
local MAX_ZOOM = 3.0
local MIN_ZOOM = 1.0
local TOGGLE_ZOOM = 2.0

local function zoom(offset)
    local current = hl.get_config("cursor.zoom_factor") or 1.0
    if offset ~= nil then
        current = current + offset
    else
        -- Super+Z toggle
        if current > MIN_ZOOM + 0.05 then
            current = MIN_ZOOM
        else
            current = TOGGLE_ZOOM
        end
    end
    current = math.max(MIN_ZOOM, math.min(MAX_ZOOM, current))
    hl.config({ cursor = { zoom_factor = current } })
end

hl.bind(mainMod .. " + Z", function()
    zoom(nil)
end)

hl.bind(mainMod .. " + SHIFT + Z", function()
    zoom(0.5)
end)

-- optional: zoom out (not in your .keybinds, but useful)
hl.bind(mainMod .. " + ALT + Z", function()
    zoom(-0.5)
end)

