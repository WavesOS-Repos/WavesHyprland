-- ~/.config/hypr/hyprland.lua
local config_dir = os.getenv("HOME") .. "/.config/hypr/configs/"

dofile(config_dir .. "monitors.lua")
dofile(config_dir .. "programs.lua")
dofile(config_dir .. "environment.lua")

-- Load colors and keep them global
colors = dofile(config_dir .. "colors.lua")

dofile(config_dir .. "general.lua")
dofile(config_dir .. "decorations.lua")
dofile(config_dir .. "animations.lua")
dofile(config_dir .. "input.lua")
dofile(config_dir .. "keybinds.lua")
dofile(config_dir .. "windowrules.lua")
dofile(config_dir .. "autostart.lua")
dofile(config_dir .. "plugins.lua")
