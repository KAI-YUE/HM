local Render      = require("HMfns.systems.render")
local ApplyShader = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.apply_shader")
local TextFx      = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local Split       = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.split")

local Children    = require("HMEng.ui_actors.hm_widget.renderers.page_brew.render_children")
local Regions     = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.render.regions")
local Polygon     = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.render.polygon_render")
local Strokes     = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.render.strokes")

local LG = love.graphics

local _draw_textfx    = TextFx.draw_card_textfx
local push_draw_trans = Render.push_actor_draw_transform

local M = {}

---____________________________
--- main: draw
---______________________________________
function M.draw(self)
    local VT,  tz   = self.VT, self.rcfg.tile_size
    local wpx, hpx  = VT.w * tz, VT.h * tz

    local pressed, p_dist = self:button_press_distance()
    local cfg, sp         = self.config, self.shadow_parallax or { x = 0, y = 0 }
    local dx,  dy         = -sp.x*p_dist, -sp.y*p_dist
    local fdx, fdy        = 0, 0

    if pressed then fdx, fdy = dx, dy end

    if cfg.split then
        cfg.page_regions = Split.regions(self.gm, cfg.split)
        Split.sync_strokes(self)
    end

    local card_textfx_first         = cfg.draw_order == "card_textfx_first"
    local card_textfx_shadow_first  = cfg.draw_order == "card_textfx_shadow_first"
    if card_textfx_first        then _draw_textfx(self) end
    if card_textfx_shadow_first then _draw_textfx(self, { shadow_only = true }) end

    push_draw_trans(self, pressed and 0.985 or 1)
    LG.scale(1 / tz)

    local shader_on, old_shader = ApplyShader.apply_fx_mask_shader(self, wpx, hpx)
    Regions.draw(self, wpx, hpx, fdx, fdy)
    Polygon.draw(self, wpx, hpx, fdx, fdy)
    Strokes.draw(self, wpx, hpx, fdx, fdy, dx - fdx, dy - fdy)

    LG.pop()
    ApplyShader.clear_shader(shader_on, old_shader)

    Children.draw(self)
    if not card_textfx_first then _draw_textfx(self, { skip_shadow = card_textfx_shadow_first }) end
end

return M
