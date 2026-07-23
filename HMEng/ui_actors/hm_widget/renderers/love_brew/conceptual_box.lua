local CardTextFx = require("HMEng.ui_actors.card_textfx")
local TabUtils   = require("HMfns.utils.table_utils")

local min, max = math.min, math.max
local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

M.handles_child_widgets = Y

M.config_keys = {
    "textfx", "extra_textfx", "textfx_static", "letter_flip", "lang",
    "child_widgets", "child_align", "textfx_align",
}

--- Helper: aligned_pos
local function aligned_pos(T, box, align)
    if not align then return T.x or 0, T.y or 0 end
    local x, y = T.x or 0, T.y or 0
    if align.x == "center" or align.x == "middle" then x = 0.5*((box.w or 0) - (T.w or 0)) end
    if align.x == "right"                         then x = (box.w or 0) - (T.w or 0) end
    if align.y == "center" or align.y == "middle" then y = 0.5*((box.h or 0) - (T.h or 0)) end
    if align.y == "bottom"                        then y = (box.h or 0) - (T.h or 0) end
    return x, y
end

--- Helper: textfx_T
local function textfx_T(self, src)
    local VT, fxcfg  = self.VT, src or {}
    local T,  r      = fxcfg.T or fxcfg, (VT.r or 0) + (T.r or fxcfg.r or 0)
    local x,  y      = aligned_pos(T, self.T, self.config.textfx_align)

    return {
        x     = VT.x + x,           y     = VT.y + y,
        w     = T.w or VT.w,        h     = T.h or VT.h,
        r     = r,                  scale = (VT.scale or 1) * (T.scale or fxcfg.scale or 1),
    }
end

--- Helper: textfx_configs
local function textfx_configs(cfg)
    local out = {}
    if cfg.textfx then out[#out + 1] = cfg.textfx end
    for _, textfx in ipairs(cfg.extra_textfx or {}) do out[#out + 1] = textfx end
    return out
end

--- Helper: init_textfx_args
local function init_textfx_args(self, gm, src)
    local cfg, args = self.config, copy(src)
    args.T,         args.no_register  = textfx_T(self, src), Y
    args.text,      args.lang         = tostring(args.text or ""), args.lang or cfg.lang or gm.selected_lang
    args.button,    args.can_hover    = N, N
    args.can_click, args.can_collide  = N, N

    if args.textfx_static == nil then args.textfx_static = args.static end
    if args.textfx_static == nil then args.textfx_static = cfg.textfx_static end
    if args.letter_flip   == nil then args.letter_flip   = cfg.letter_flip   end
    return args
end

--- Helper: child_items
local function child_items(cfg)
    local items = cfg.child_widgets
    if not items then return {} end
    if not items[1] and not (items.style or items.renderer or items.T) then return {} end
    return items[1] and items or { items }
end

--- Helper: child_role
local function child_role(gm, parent, item, T)
    local major = item.room_ref and gm._room_r or parent
    return { role_type = "Minor", major = major, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" }
end

--- Helper: new_child
local function new_child(gm, item)
    local HMWidget = require("HMEng.ui_actors.hm_widget")
    return HMWidget(gm, item)
end

--- Helper: child_bounds
local function child_bounds(children)
    local l, t, r, b
    for _, child in ipairs(children or {}) do
        local T = child.T or {}
        local x, y, w, h  = T.x or 0, T.y or 0, T.w or 0, T.h or 0
        l,   t,   r,   b  = min(l or x, x), min(t or y, y), max(r or x + w, x + w), max(b or y + h, y + h)
    end
    return l or 0, t or 0, r or 0, b or 0
end

--- Helper: align_delta
local function align_delta(children, box, align)
    align = align or {}
    local l, t, r, b = child_bounds(children)
    local dx, dy = 0, 0
    if align.x == "center" or align.x == "middle" then dx = 0.5 * ((box.w or 0) - (r - l)) - l end
    if align.x == "right" then dx = (box.w or 0) - (r - l) - l end
    if align.y == "center" or align.y == "middle" then dy = 0.5 * ((box.h or 0) - (b - t)) - t end
    if align.y == "bottom" then dy = (box.h or 0) - (b - t) - t end
    return dx, dy
end

--- Helper: align_children
local function align_children(self)
    local align = self.config.child_align;                      if not align then return end
    local dx, dy = align_delta(self.children, self.T, align);   if dx == 0 and dy == 0 then return end

    for _, child in ipairs(self.children or {}) do
        local T, ro  = child.T or {}, child.role and child.role.offset
        T.x,    T.y  = (T.x or 0) + dx, (T.y or 0) + dy
        if ro then ro.x, ro.y = T.x, T.y end
        if child.move_with_major then child:move_with_major(0) end
    end
end

--- Helper: init_textfx
local function init_textfx(self, gm)
    local textfxs = {}
    for _, textfx in ipairs(textfx_configs(self.config)) do textfxs[#textfxs + 1] = CardTextFx(gm, init_textfx_args(self, gm, textfx)) end
    self.conceptual_box_textfxs = textfxs
end

--- Helper: init_children
local function init_children(self, gm)
    self.page_child_widgets = {}
    for _, item in ipairs(child_items(self.config)) do
        local child_args  = copy(item)
        local T           = child_args.T or {}
        local child       = new_child(gm, child_args)
        child.parent = self
        child:set_role(child_role(gm, self, child_args, T))
        self.children[#self.children + 1] = child
        self.page_child_widgets[#self.page_child_widgets + 1] = child
    end
    align_children(self)
end

--- Helper: sync_textfx
local function sync_textfx(self, fx, src)
    if not (fx and src) then return end
    local T, ft = textfx_T(self, src), fx.T
    ft.x,    ft.y,    ft.w,    ft.h,    ft.r,    ft.scale     = T.x, T.y, T.w, T.h, T.r, T.scale
    fx.VT.x, fx.VT.y, fx.VT.w, fx.VT.h, fx.VT.r, fx.VT.scale  = T.x, T.y, T.w, T.h, T.r, T.scale

    fx.fx_mask, fx.fx_mask_dir = self.fx_mask, self.fx_mask_dir
    fx.draw_alpha   = self.draw_alpha
    fx.config.text  = tostring(src.text or "")
    fx.config.lang  = fx.config.lang or self.config.lang or self.gm.selected_lang
end

--- Helper: draw_textfx
local function draw_textfx(self)
    local textfxs, cfgs = self.conceptual_box_textfxs or {}, textfx_configs(self.config)
    for i, fx in ipairs(textfxs) do
        sync_textfx(self, fx, cfgs[i])
        fx:draw_cache(fx.config.text)
    end
end

---____________________________
--- main: init
---______________________________________
function M.init(self, gm)
    self.draw_alpha = self.draw_alpha or 1
    init_textfx(self, gm)
    init_children(self, gm)
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self) draw_textfx(self) end

---____________________________
--- main: hit_test
---______________________________________
function M.hit_test() return N end

return M
