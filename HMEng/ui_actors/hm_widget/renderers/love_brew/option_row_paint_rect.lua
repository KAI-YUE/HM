local Render    = require("HMfns.systems.render")
local PaintSeeds = require("HMEng.ui_actors.card_textfx.data.paint_seeds")
local Base      = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect")
local C         = require("HMfns.animate.color.color_const")
local TabUtils  = require("HMfns.utils.table_utils")
local LG        = love.graphics

local max = math.max
local min = math.min
local pick = TabUtils.random_pick
local push_draw_trans = Render.push_actor_draw_transform

local Y, N = true, false

local M = {}

M.config_keys = {}
for _, key in ipairs(Base.config_keys or {}) do M.config_keys[#M.config_keys + 1] = key end
for _, key in ipairs({
    "paint_rect_renderer",
    "hover_edge",                "hover_edge_color",
    "hover_edge_outer_inset",    "hover_edge_outer_offset",
    "hover_edge_inner_inset",    "hover_edge_inner_offset",
    "hover_edge_bleed",          "hover_edge_wobble", "hover_edge_grace_s", "hover_edge_fade_s",
    "hover_inner_bleed",         "hover_inner_wobble", "hover_inner_feather_px",
}) do M.config_keys[#M.config_keys + 1] = key end

M.hit_test        = Base.hit_test
M.hit_test_outer  = Base.hit_test_outer
M.text_layout_box = Base.text_layout_box
M.init            = Base.init

local T_inter = { "hover", "drag", "click" }

-----------------------------
--- hover edge helpers
----------------------------------
--- Helper: _interaction_is
local function _interaction_is(st, key) return st and st[key] and st[key].is end
local function _focus_is(st) return st and st.focus and st.focus.is end

--- Helper: _child_hover_edge_active
local function _child_hover_edge_active(child)
    if not child or child.REMOVED then return N end
    local st = child.states
    if _focus_is(st) then return Y end
    for _, _act in ipairs(T_inter) do if _interaction_is(st, _act) then return Y end; end
    for _, c in ipairs(child.children or {}) do if _child_hover_edge_active(c) then return Y end end
    return N
end

--- Helper: _hover_edge_raw_active
local function _hover_edge_raw_active(self)
    local active = (self.states.hover and self.states.hover.is) or _focus_is(self.states)
    if not active then for _, child in ipairs(self.children or {}) do if _child_hover_edge_active(child) then active = Y; break end end end
    return active
end

--- Helper: _hover_edge_active
local function _hover_edge_active(self)
    local cfg = self.config
    if cfg.hover_edge == N then return N end

    local now = self._T.real_s or 0
    local active = _hover_edge_raw_active(self)
    if active then
        if not self._hover_edge_raw_active then self._hover_edge_reveal_started_at = now end
        self._hover_edge_raw_active = Y
        self._hover_edge_active_until = now + (cfg.hover_edge_grace_s or 0)
        return Y
    end

    self._hover_edge_raw_active = N
    return now <= (self._hover_edge_active_until or -1)
end

--- Helper: _hover_edge_alpha
local function _hover_edge_alpha(self)
    local cfg, now = self.config, self._T.real_s or 0
    local dur = cfg.hover_edge_fade_s or 0
    if dur <= 0 then return 1 end
    return min(1, max(0, (now - (self._hover_edge_reveal_started_at or now)) / dur))
end

--- Helper: _color_alpha
local function _color_alpha(color, alpha)
    color = color or C.BLACK
    return { color[1], color[2], color[3], (color[4] or 1)*alpha }
end

--- Helper: _idle_fill_color
local function _idle_fill_color(cfg)
    local idle = cfg.idle_color
    if cfg.idle_fill_color then return cfg.idle_fill_color end
    if idle then if idle.fill_color then return idle.fill_color elseif idle[1] then return idle end end
    return cfg.fill_color or C.BLACK
end

--- Helper: _hover_seed_entry
local function _hover_seed_entry(self)
    local cfg = self.config
    cfg._hover_edge_paint_seed_entry = cfg._hover_edge_paint_seed_entry or cfg.paint_seed_entry or pick(PaintSeeds, self.ID)
    return cfg._hover_edge_paint_seed_entry
end

--- Helper: _paint_cfg
local function _paint_cfg(self, color, opts)
    local opts, out   = opts or {}, {}
    local cfg, src    = self.config, self.config.paint or self.config
    for k, v in pairs(src) do out[k] = v end

    out.color,      out.shadow       = color,                             (opts.shadow == Y)
    out.paint_seed_entry             = opts.paint_seed_entry or _hover_seed_entry(self)
    out.bleed,      out.wobble       = opts.bleed or cfg.hover_edge_bleed or out.bleed, opts.wobble or cfg.hover_edge_wobble or out.wobble
    out.feather_px, out.fx_mask_ref  = opts.feather_px or out.feather_px, out.fx_mask_ref or cfg.fx_mask_ref or "fx_mask"
    out.fx_mask_dir_ref              = out.fx_mask_dir_ref or cfg.fx_mask_dir_ref or "fx_mask_dir"
    return out
end

--- Helper: _inset_pair | _offset_pair
local function _inset_pair(v) if type(v) == "number" then return v, v end; v = v or {}; return v.x or v.w or 0, v.y or v.h or 0 end
local function _offset_pair(v, tz) v = v or {}; return (v.x or 0)*tz, (v.y or 0)*tz end

--- Helper: _inset_box
local function _inset_box(base, inset, offset, tz)
    local ix, iy  = _inset_pair(inset)
    local ox, oy  = _offset_pair(offset, tz)
    local dx, dy  = ix*tz,                          iy*tz
    local w,  h   = max(1, base.w - 2*dx),          max(1, base.h - 2*dy)
    local _x, _y  = base.x + dx + ox,               base.y + dy + oy

    return { x = _x, y = _y, w = w, h = h }
end

--- Helper: _hover_edge_boxes
local function _hover_edge_boxes(self, base, tz)
    local cfg = self.config
    local outer       = _inset_box(base, cfg.hover_edge_outer_inset, cfg.hover_edge_outer_offset, tz)
    local inner       = _inset_box(base, cfg.hover_edge_inner_inset, cfg.hover_edge_inner_offset, tz)

    return outer, inner
end

--- Helper: _draw_hover_edge
local function _draw_hover_edge(self)
    if not _hover_edge_active(self) then return end

    local VT,      tz         = self.VT,   self.rcfg.tile_size
    local wpx,     hpx        = VT.w * tz, VT.h * tz
    local pressed, p_dist     = self:button_press_distance()
    local cfg,     sp         = self.config, self.shadow_parallax or { x = 0, y = 0 }
    local dx,      dy         = pressed and -sp.x*p_dist or 0, pressed and -sp.y*p_dist or 0
    local outer,   inner_box  = _hover_edge_boxes(self, { x = dx, y = dy, w = wpx, h = hpx }, tz)
    local alpha,   seed_entry = _hover_edge_alpha(self), _hover_seed_entry(self)
    local edge,    inner      = _color_alpha(self.config.hover_edge_color or C.UI.WIDGET_DARK, alpha), _idle_fill_color(cfg)

    push_draw_trans(self, pressed and 0.985 or 1)
    LG.scale(1/tz)
    Base.draw_bleed_layer(self, outer,     _paint_cfg(self, edge, { shadow = N, paint_seed_entry = seed_entry }), N, { skip_shadow = Y })
    Base.draw_bleed_layer(self, inner_box, _paint_cfg(self, inner, { shadow = N, paint_seed_entry = seed_entry, bleed = cfg.hover_inner_bleed, wobble = cfg.hover_inner_wobble, feather_px = cfg.hover_inner_feather_px }), N, { skip_shadow = Y })
    LG.pop()
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self)
    Base.draw(self)
    _draw_hover_edge(self)
end

return M
