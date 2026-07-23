local Composite = require("HMEng.visual.composite_layer")
local Render    = require("HMfns.systems.render")
local Shader    = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.shader")
local LG        = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local M = {}

M.config_keys = {
    "composite_items", "composite_blend",
    "paint",
    "tint", "sprite_color", "widget_dist",
}

--------------------------------------------------
--- item helpers
--------------------------------------------------
local function _item_h(item)
    if item.h then return item.h end
    local m = item.metrics;      if not (m and item.w) then return 0 end
    return item.w*m.h/m.w
end

local function _item_color(self, item)
    local color = item.sprite_color or item.tint
    if type(color) == "table" then return color end
    if self.config.sprite_color then color = self:resolve_visual_color("sprite_color"); if type(color) == "table" then return color end end
    if self.config.tint then color = self:resolve_visual_color("tint"); if type(color) == "table" then return color end end
    return { 1, 1, 1, 1 }
end

local function _draw_item(self, item, tz)
    local h = _item_h(item);     if h <= 0 then return end
    local sx, sy = item.w*tz/item.metrics.w, h*tz/item.metrics.h
    local c = _item_color(self, item)

    LG.setColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
    LG.draw(item.img, item.quad, (item.x or 0)*tz, (item.y or 0)*tz, item.r or 0, sx, sy)
end

--------------------------------------------------
--- render canvas
--------------------------------------------------
local function _render_canvas(self, canvas, w, h)
    Composite.render_to_canvas(canvas, { reset_transform = true, shader = Composite.premultiply_shader(), blend = self.config.composite_blend or "lighten" }, function()
        for _, item in ipairs(self.composite_items or {}) do _draw_item(self, item, self.rcfg.tile_size) end
    end)
end

--- Helper: _composite_quad
local function _composite_quad(self, w, h)
    local q = self.composite_quad
    if q and self.composite_quad_w == w and self.composite_quad_h == h then return q end

    q = LG.newQuad(0, 0, w, h, w, h)
    self.composite_quad, self.composite_quad_w, self.composite_quad_h = q, w, h
    return q
end

--------------------------------------------------
--- init
--------------------------------------------------
function M.init(self, gm)
    local cfg = self.config
    self.composite_items = {}
    self.draw_alpha = self.draw_alpha or 1

    for _, item in ipairs(cfg.composite_items or {}) do
        local atlas = gm.T_atlas[item.atlas_key];        if not atlas then goto continue end
        local quad  = atlas:get_quad(item.quad_key);     if not quad then goto continue end
        local _, _, qw, qh = quad:getViewport()
        item.img, item.quad, item.metrics = atlas.image, quad, { w = qw, h = qh }
        self.composite_items[#self.composite_items + 1] = item
        ::continue::
    end
end

----------------------------------------------------
--- draw 
----------------------------------------------------
function M.draw(self)
    local px_w, px_h = self.VT.w*self.rcfg.tile_size, self.VT.h*self.rcfg.tile_size
    local w, h = math.ceil(px_w), math.ceil(px_h)
    if w <= 0 or h <= 0 then return end

    local canvas = Composite.ensure_canvas(self, "composite_canvas", w, h)
    _render_canvas(self, canvas, w, h)

    push_draw_trans(self)
    LG.scale(1/self.rcfg.tile_size)

    local old_img, quad = self.sprite_img, _composite_quad(self, w, h)
    self.sprite_img = canvas
    local shader_on, old_shader = Shader.apply(self, Shader.paint_shader(self.config.paint), quad, false, { x = 0, y = 0, w = px_w, h = px_h }, function() return 0 end)
    Composite.draw_canvas(canvas, { alpha = self.draw_alpha or 1, sx = px_w/w, sy = px_h/h, shader = shader_on and LG.getShader() or nil })
    Shader.clear(shader_on, old_shader)
    self.sprite_img = old_img
    LG.pop()
end

return M
