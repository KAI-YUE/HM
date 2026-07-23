local Render      = require("HMfns.systems.render")
local Pendulum    = require("HMEng.ui_actors.hm_widget.renderers.common.pendulum_string")
local Metrics     = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.metrics")
local Background  = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.background")
local Effects     = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.effects")
local Parts       = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.parts")
local Overlays    = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw_helpers.overlays")
local LG          = love.graphics

local push_draw_trans = Render.push_actor_draw_transform

local Y, N = true, false

local M = {}

--- Helper: _parent_hover_active
local function _parent_hover_active(self)
    local p = self.parent;     if not p then return N end
    local st = p.states;       if not st then return N end
    return (st.hover and st.hover.is) or (st.focus and st.focus.is)
end

--- Helper: _reset_parent_hover_reveal
local function _reset_parent_hover_reveal(self)
    if not self._parent_hover_reveal_active then return end
    self._parent_hover_reveal_active = N
    self._parent_hover_reveal_token  = (self._parent_hover_reveal_token or 0) + 1
    self.draw_alpha = 0
end

--- Helper: _enqueue_parent_hover_reveal
local function _enqueue_parent_hover_reveal(self)
    local cfg = self.config
    if self._parent_hover_reveal_active then return end

    self._parent_hover_reveal_active = Y
    self._parent_hover_reveal_token  = (self._parent_hover_reveal_token or 0) + 1
    self.draw_alpha = 0

    local delay        = cfg.parent_hover_reveal_s or 0.16
    local target_alpha = cfg.parent_hover_reveal_alpha or 1
    local EM           = self.gm.E_MANAGER
    if not EM or delay <= 0 then self.draw_alpha = target_alpha; return end

    local token = self._parent_hover_reveal_token
    EM:enqueue_event({ trigger = "ease", ease = cfg.parent_hover_reveal_ease or "sine", blockable = N, blocking = N,
        ref_table = self, ref_value = "draw_alpha", ease_to = target_alpha, delay = delay,
        func = function(v) return self._parent_hover_reveal_token == token and v or (self.draw_alpha or 0) end,
    })
end

--- Helper: _update_parent_hover_reveal
local function _update_parent_hover_reveal(self, active)
    if not self.config.show_on_parent_hover then return end
    if active then return _enqueue_parent_hover_reveal(self) end
    _reset_parent_hover_reveal(self)
end

--- Helper: _draw_bg_in_transform
local function _draw_bg_in_transform(self, scale, rotate, offset)
    push_draw_trans(self, scale, rotate, offset)
    LG.scale(1/self.rcfg.tile_size)
    Background.draw(self)
    LG.pop()
end

--- Helper: draw_sprite_layer
local function _draw_sprite_layer(self, img, quad, layout, offset, shadow)
    local cfg           = self.config
    local x, y, sx, sy  = layout.x, layout.y, layout.sx, layout.sy

    if Parts.has_visible_mask(self, cfg) then Parts.draw_mask(self, img, x, y, layout.dw, layout.dh, offset.x, offset.y, shadow, Effects.hover_elapsed) end

    Parts.draw_face(self, img, quad, x, y, sx, sy, offset.x, offset.y, shadow, Effects.hover_elapsed)
    Overlays.draw(self, offset.x, offset.y, shadow)
end

--- Helper: _sprite_layout
local function _sprite_layout(self, SM)
    local x, y, sx, sy, wpx, hpx = Metrics.layout_sprite(self, SM)
    return { x = x, y = y, sx = sx, sy = sy, wpx = wpx, hpx = hpx, dw = SM.w * sx, dh = SM.h * sy }
end

--- Helper: press_offsets
local function _press_offsets(self, pressed, p_dist)
    local cfg     = self.config
    local sp      = cfg.shadow_parallax or self.shadow_parallax or { x = 0, y = 0 }
    local dx, dy  = -sp.x * p_dist, -sp.y * p_dist

    if pressed and not cfg.no_press_squash then return { x = dx, y = dy }, { x = dx, y = dy } end
    return { x = dx, y = dy }, { x = 0, y = 0 }
end

-----------------------------
-- Main draw
-----------------------------
function M.draw(self, opts)
    local cfg = self.config
    local parent_hover_active = _parent_hover_active(self)
    _update_parent_hover_reveal(self, parent_hover_active)
    if cfg.show_on_parent_hover and not parent_hover_active then return end

    local quad, img, SM = self.sprite_quad, self.sprite_img, self.sprite_metrics
    if not quad or not img or not SM then return end
    opts = opts or {}

    Effects.clear_hover_start_when_safe(self)

    local layout,        press_scale            = _sprite_layout(self, SM), 1
    local pressed,       p_dist                 = self:button_press_distance()
    local shadow_offset, face_offset            = _press_offsets(self, pressed, p_dist)
    local hover_zoom,    hover_offset, hover_r  = Effects.hover_transform(self)

    if pressed and not cfg.no_press_squash then press_scale = 0.985 end

    local draw_scale           = press_scale * hover_zoom
    local draw_rotate          = hover_r + (self.draw_rotate or 0)
    local has_pendulum_string  = Pendulum.visible(self)
    local static_bg            = cfg.hover_shake_sprite_only and not has_pendulum_string

    if has_pendulum_string then
        _draw_bg_in_transform(self, draw_scale, draw_rotate, hover_offset)
        Pendulum.draw(self, layout.wpx, layout.hpx, draw_scale, hover_offset)
    end

    if static_bg then _draw_bg_in_transform(self, press_scale, self.draw_rotate or 0) end

    push_draw_trans(self, draw_scale, draw_rotate, hover_offset)
    LG.scale(1/self.rcfg.tile_size)

    if not has_pendulum_string and not static_bg then Background.draw(self) end
    if cfg.shadow and not opts.skip_shadow then _draw_sprite_layer(self, img, quad, layout, shadow_offset, Y) end

    if not opts.shadow_only then _draw_sprite_layer(self, img, quad, layout, face_offset, N) end
    LG.pop()
end

return M
