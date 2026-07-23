local C, Hud   = require("HMfns.animate.color.color_const"), require("HMGplay.run_flow.game_run.mod_hud")
local HMPanel  = require("HMEng.ui_actors.hm_panel")
local Attach   = require("HMEng.ui_actors.common.actor_attachment")
local IconBtn  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Language = require("HMGmgr.interactions.debug.language")

local Y, N = true, false

local M = {}

local _panel_w, _panel_pad_bottom = 3.72, 1

-----------------------------
--- hooks
----------------------------------
--- Helper: debug hud hook | debug foe hook
local function debug_hud_hook(stat, delta) return function(gm) gm:_debug_hud_mod(stat, delta); return Y end end
local function debug_foe_hook(gm) gm:_debug_hud_toggle_foe(); return Y end

-----------------------------
--- widgets
----------------------------------
--- Helper: debug icon button
local function debug_icon_btn(id, label, icon, x, y, hook_fn, args)
    args = args or {}
    local btn = {
        id = id,                         T = { x = x, y = y, w = args.w or 1.52, h = args.h or 0.48 },

        label = label,                   icon_quad_key = icon,
        button = Y,                      can_hover = Y,
        can_click = Y,                   hook_fn = hook_fn,

        bg_w = args.w or 1.52,           bg_h = args.h or 0.48,
        bg_style = "round_rect",         bg_fill_color = args.bg_fill_color or { 0.12, 0.105, 0.095, 0.92 },
        bg_round_radius = 0.08,          bg_shadow = Y,
        bg_shadow_color = { 0, 0, 0, 0.30 },

        icon_x = 0.12,                   icon_y = 0.10,
        icon_w = 0.30,                   icon_tint = args.icon_tint or C.CREAM,
        icon_hover_color = args.hover_color or C.ORANGE,

        label_x = 0.50,                  label_y = 0.09,
        label_w = 0.88,                  label_h = 0.30,
        label_text_scale = 0.32,         label_color = C.UI.TEXT_LIGHT,
        label_hover_color = args.hover_color or C.ORANGE,

        widget_dist = 0.72,              hover_tint = 0,
        hover_arrow = N,
    }
    btn.style = IconBtn(btn)
    return btn
end

--- Helper: debug tool widgets
local function debug_tool_widgets(gm)
    local x1, x2, y0, gap = 0.24, 1.88, 0.62, 0.58
    return {
        Language.selector(gm, x1, y0),
        debug_icon_btn("debug_hp_down",    "-HP",    "heart",  x1, y0+gap,   debug_hud_hook("hp", -10),   { hover_color = C.RED }),
        debug_icon_btn("debug_hp_up",      "+HP",    "heart",  x2, y0+gap,   debug_hud_hook("hp", 10),    { hover_color = C.RED }),
        debug_icon_btn("debug_full_down",  "-Full",  "muffin", x1, y0+2*gap, debug_hud_hook("full", -10), { hover_color = C.GREEN }),
        debug_icon_btn("debug_full_up",    "+Full",  "muffin", x2, y0+2*gap, debug_hud_hook("full", 10),  { hover_color = C.GREEN }),
        debug_icon_btn("debug_money_down", "-Money", "coin",   x1, y0+3*gap, debug_hud_hook("money", -5), { hover_color = C.ORANGE }),
        debug_icon_btn("debug_money_up",   "+Money", "coin",   x2, y0+3*gap, debug_hud_hook("money", 5),  { hover_color = C.ORANGE }),
        debug_icon_btn("debug_foe_toggle", "FOE",    "chat",   x1, y0+4*gap, debug_foe_hook,              { w = 3.16, hover_color = C.ORANGE }),
    }
end

-----------------------------
--- layout
----------------------------------
--- Helper: widget bottom | panel box
local function widget_bottom(widget)
    local T = widget and widget.T or {}
    return (T.y or 0) + (T.h or 0)
end

local function panel_box(gm, widgets)
    local RT, max_y = gm._room and gm._room.T or { w = 24 }, 0
    for _, widget in ipairs(widgets or {}) do max_y = math.max(max_y, widget_bottom(widget)) end
    return { x = RT.w - (_panel_w + 0.33), y = 3.05, w = _panel_w, h = max_y + _panel_pad_bottom }
end

--- Helper: mark tree created on pause
local function mark_created_on_pause(node)
    if not node then return end
    node.created_on_pause = Y
    mark_created_on_pause(node.widget)
    mark_created_on_pause(node.attached_panel)
    for _, child in ipairs(node.children or {}) do mark_created_on_pause(child) end
end

--- Helper: make debug tools panel
local function make_debug_tools(gm)
    local widgets = debug_tool_widgets(gm)
    local box = panel_box(gm, widgets)
    local panel = HMPanel(gm, {
        style         = "round_rect",
        T             = box,
        fill_color    = { 0.055, 0.05, 0.045, 0.88 },
        round_radius  = 0.14,
        shadow        = Y,
        shadow_color  = { 0, 0, 0, 0.36 },
        can_hover     = N,
        can_collide   = N,
        child_widgets = widgets,
    })
    mark_created_on_pause(panel)
    Attach.hard_set_panel_tree(panel, box)
    return panel
end

-----------------------------
--- install
----------------------------------
function M.install(GMgr)
--- Helper: toggle debug
function GMgr:_toggle_debug()
    if self.debug_tools then return self:_reset_debug() end
    self.debug_tools = make_debug_tools(self)
end

--- Helper: reset debug
function GMgr:_reset_debug() if not self.debug_tools then return end; self.debug_tools:remove(); self.debug_tools = nil end

--- Helper: remake debug tools
function GMgr:_debug_remake_tools()
    if self.debug_tools then self.debug_tools:remove() end
    self.debug_tools = make_debug_tools(self)
end

--- Helper: debug hud mod
function GMgr:_debug_hud_mod(stat, delta) return Hud.debug_mod(self, stat, delta) end

--- Helper: debug hud toggle foe
function GMgr:_debug_hud_toggle_foe() return Hud.toggle_foe(self) end
end

return M
