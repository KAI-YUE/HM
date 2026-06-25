local AnimUtils      = require("HMfns.animate.transitions.anim_utils")
local Timeline       = require("HMui.menu.data.pages._-1_title_page.anims.timeline")
local TitleWallpaper = require("HMui.menu.data.pages._-1_title_page.title_wallpaper")
local PrepWallpaper  = require("HMui.menu.data.pages._-1_title_page.preparation.wallpaper")
local Wallpaper      = require("HMEng.entities.bg.wallpaper")

local Y = true

local M = {}

----------------------------------------------
--- spawn_base
----------------------------------------------
function M.spawn_base(gm)
    if gm.title_wallpaper and not gm.title_wallpaper.REMOVED then gm.title_wallpaper:remove() end
    gm.title_wallpaper = Wallpaper(gm, TitleWallpaper.wallpaper_args())
    return gm.title_wallpaper
end

----------------------------------------------
--- spawn_blur
----------------------------------------------
function M.spawn_blur(gm)
    gm.title_wallpaper_blur_token = (gm.title_wallpaper_blur_token or 0) + 1
    if gm.title_wallpaper_blur and not gm.title_wallpaper_blur.REMOVED then gm.title_wallpaper_blur.draw_alpha = 1; return gm.title_wallpaper_blur; end
    gm.title_wallpaper_blur = Wallpaper(gm, PrepWallpaper.blur_wallpaper_args())
    return gm.title_wallpaper_blur
end

----------------------------------------------
--- clear_blur
----------------------------------------------
local function _remove_wallpaper(wallpaper) if wallpaper and not wallpaper.REMOVED then wallpaper:remove() end; return Y; end

---__________________________________
--- Main: clear_blur
---__________________________________
function M.clear_blur(gm)
    local blur = gm and gm.title_wallpaper_blur;           if not blur then return Y end
    gm.title_wallpaper_blur_token  = (gm.title_wallpaper_blur_token or 0) + 1
    gm.title_wallpaper_blur        = nil
    return _remove_wallpaper(blur)
end

----------------------------------------------
--- fade_out_blur
----------------------------------------------
function M.fade_out_blur(gm)
    local blur   = gm and gm.title_wallpaper_blur;               if not blur then return Y end
    local token  = (gm.title_wallpaper_blur_token or 0) + 1
    gm.title_wallpaper_blur_token = token
    AnimUtils.ease(gm, blur, "draw_alpha", 0, Timeline.stage2.blur_fade, "lerp")
    AnimUtils.after(gm, Timeline.stage2.blur_remove, function()
        if gm.title_wallpaper_blur_token ~= token then return Y end
        if gm.title_wallpaper_blur == blur then gm.title_wallpaper_blur = nil end
        return _remove_wallpaper(blur)
    end)
    return Y
end

return M
