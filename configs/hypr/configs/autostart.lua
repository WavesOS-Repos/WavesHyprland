-- autostart.lua
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/waybar-reload.sh --reload")
    hl.exec_cmd("conky -c ~/.config/conky/Altair/Altair.conf")
     -- image wallpaper daemon
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("~/.config/hypr/scripts/polkit.sh")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- restore last Wallfliper wallpaper (delay avoids frozen video frames)
    hl.exec_cmd("sh -c 'sleep 5 && python ~/.config/wallfliper/main.py --restore'")
end)

