local colors_file = os.getenv("HOME") .. "/.config/hypr/matugen-colors.lua"
local ok, result = pcall(dofile, colors_file)

local colors
if ok and type(result) == "table" and result.primary then
    colors = result
else
    colors = {
        primary = "#89b4fa", secondary = "#cba6f7", tertiary = "#f5c2e7",
        background = "#1e1e2e", on_background = "#cdd6f4",
        surface = "#313244", outline = "#6c7086", error = "#f38ba8",
    }
end

function rgba(hex, alpha)
    hex = tostring(hex or "#ffffff"):gsub("#", "")
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

return colors
