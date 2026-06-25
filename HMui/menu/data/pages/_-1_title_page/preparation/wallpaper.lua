local TitleWallpaper = require("HMui.menu.data.pages._-1_title_page.title_wallpaper")

local M = {}

local _toon_fog = true

-------------------------------------------------
--- Blur wallpaper args
-------------------------------------------------
function M.blur_wallpaper_args()
    local args = TitleWallpaper.wallpaper_args()
    args.atlas_key, args.draw_alpha = "title_map_blur", 1
    if not _toon_fog then args.shader, args.shader_opts = nil, nil end
    return args
end

return M
