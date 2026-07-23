local Actor = require("HMEng.actors.actor")
local C, LG = require("HMfns.animate.color.color_const"), love.graphics

local push = table.insert
local cw = C.WHITE

return function (Wallpaper)
--------------------------------------------------
--- screen_T
--------------------------------------------------
function Wallpaper.screen_T(gm)
    local rcfg, WT = gm.rcfg,    gm.win_trans or {}
    local norm     = rcfg.tile_size*rcfg.tile_scale
    local _w,  _h  = (WT.real_window_w or LG.getWidth())/norm, (WT.real_window_h or LG.getHeight())/norm
    
    return { x = 0, y = 0, w = _w, h = _h }
end

--------------------------------------------------
--- init_wallpaper_attributes
--------------------------------------------------
--- Helper: _init_config
local function _init_config(args)
    args = args or {}
    return {
        type      = args.type or "wallpaper",    atlas_key    = args.atlas_key,
        quad_key  = args.quad_key,               shader       = args.shader,
        color     = args.color or cw,            shader_opts  = args.shader_opts or {},
        drift     = args.drift or args.parallax,
    }
end

---_________________________________
--- main: init wallpaper attributes
---_________________________________
function Wallpaper:init_wallpaper_attributes(gm, args)
    local T = Wallpaper.screen_T(gm)
    Actor.init(self, gm, T.x, T.y, T.w, T.h)

    self.draw_alpha = args and args.draw_alpha or 1
    self.config     = _init_config(args)
    self.t_shaders  = gm.t_shaders
    self.RMAP       = gm.R.TMAP
    push(self.RMAP, self)

    self:set_container(self)
    self:sync_atlas()
end

--------------------------------------------------
--- remove
--------------------------------------------------
--- Helper: _cleanup
local function _cleanup(tab, obj) for i, v in ipairs(tab or {}) do if v == obj then table.remove(tab, i); break end end end

function Wallpaper:remove()
    _cleanup(self.RMAP, self)
    Actor.remove(self)
end

end
