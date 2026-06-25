local PaintRect = require("HMEng.ui_actors.card_textfx.in_factory.paint.textfx_bg_paint_rect")
local C         = require("HMfns.animate.color.color_const")

local ck = C.BLACK

local Y, N = true, false

local M = {}

--- Helper: _sprite_bg_cfg
local function _sprite_bg_cfg(self)
    local bg = self.config.sprite_bg or self.config.bg;     if not bg then return end

    local out = {}
    for k, v in pairs(bg.paint or bg) do out[k] = v end
    out.color         = bg.fill_color or bg.color or out.color or ck
    out.shadow_color  = bg.shadow_color or out.shadow_color
    out.shadow        = bg.shadow
    out.renderer      = bg.renderer or out.renderer
    out.paint_alpha   = bg.paint_alpha or out.paint_alpha
    return bg, out
end

--- Helper: draw
function M.draw(self)
    local bg, cfg = _sprite_bg_cfg(self);       if not bg then return end

    local T, VT = bg.T or bg, self.VT
    local tz    = self.rcfg.tile_size
    local box = {
        x = (T.x or 0) * tz,         y = (T.y or 0) * tz,
        w = (T.w or VT.w) * tz,      h = (T.h or VT.h) * tz,
        r = T.r or bg.r or 0,
    }
    local ctx = setmetatable({ config = cfg }, { __index = self })
    cfg.shadow = bg.shadow ~= N
    PaintRect.draw_bleed_layer(ctx, box, cfg, N)
end

return M
