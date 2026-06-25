local FileIO   = require("core.io.fileio")
local HMPanel  = require("HMEng.ui_actors.hm_panel")
local C        = require("HMfns.animate.color.color_const")
local IconBtn  = require("HMEng.ui_actors.hm_panel.prototype.icon_btn.default")
local Hud      = require("HMGplay.run_flow.game_run.mod_hud")
local Intents  = require("HMGmgr.interactions.intents")

local unpickle = FileIO.unpickle
local Y, N     = true, false

return function (GMgr)
-----------------------------
--- debug related
----------------------------------
--- Helper: quick load data
function GMgr:_dt_load()
    self.saved_game = unpickle(self:slot_save_path(self.SET.profile)) or unpickle(self.SET.profile .. "/" .. "save.hm")
    self.Fs.transition_to_run(self, nil, { savetext = self.saved_game })
end

--- Helper: profile game
function GMgr:_profile_game()
    if not self.prof then self.prof = require "HMEng.my_io.profile"; self.prof.start(); return end
    self.prof:stop();                      local r = self.prof.report()
    self.debugger.save_table({r}, "p.hm"); self.prof = nil
end

-----------------------------
--- _toggle_debug
----------------------------------
--- Helper: debug hud hook
local function _debug_hud_hook(stat, delta) return function(gm) gm:_debug_hud_mod(stat, delta); return Y end end

--- Helper: debug foe hook
local function _debug_foe_hook(gm) gm:_debug_hud_toggle_foe(); return Y end

--- Helper: debug icon button
local function _debug_icon_btn(id, label, icon, x, y, hook_fn, args)
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
local function _debug_tool_widgets()
    local x1, x2, y0, gap = 0.24, 1.88, 0.62, 0.58
    return {
        _debug_icon_btn("debug_hp_down",    "-HP",    "heart",  x1, y0,       _debug_hud_hook("hp", -10),   { hover_color = C.RED }),
        _debug_icon_btn("debug_hp_up",      "+HP",    "heart",  x2, y0,       _debug_hud_hook("hp", 10),    { hover_color = C.RED }),
        _debug_icon_btn("debug_full_down",  "-Full",  "muffin", x1, y0+gap,   _debug_hud_hook("full", -10), { hover_color = C.GREEN }),
        _debug_icon_btn("debug_full_up",    "+Full",  "muffin", x2, y0+gap,   _debug_hud_hook("full", 10),  { hover_color = C.GREEN }),
        _debug_icon_btn("debug_money_down", "-Money", "coin",   x1, y0+2*gap, _debug_hud_hook("money", -5), { hover_color = C.ORANGE }),
        _debug_icon_btn("debug_money_up",   "+Money", "coin",   x2, y0+2*gap, _debug_hud_hook("money", 5),  { hover_color = C.ORANGE }),
        _debug_icon_btn("debug_foe_toggle", "FOE",    "chat",   x1, y0+3*gap, _debug_foe_hook,              { w = 3.16, hover_color = C.ORANGE }),
    }
end

--- Helper: make debug tools panel
local function _make_debug_tools(gm)
    local RT = gm._room and gm._room.T or { w = 24 }
    return HMPanel(gm, {
        style         = "round_rect",
        T             = { x = RT.w - 4.05, y = 3.05, w = 3.72, h = 3.16 },
        fill_color    = { 0.055, 0.05, 0.045, 0.88 },
        round_radius  = 0.14,
        shadow        = Y,
        shadow_color  = { 0, 0, 0, 0.36 },
        can_hover     = N,
        can_collide   = N,
        child_widgets = _debug_tool_widgets(),
    })
end

function GMgr:_toggle_debug()
    if self.debug_tools then return self:_reset_debug() end
    self.debug_tools = _make_debug_tools(self)
end

--- Helper: debug hud mod
function GMgr:_debug_hud_mod(stat, delta) return Hud.debug_mod(self, stat, delta) end

--- Helper: debug hud toggle foe
function GMgr:_debug_hud_toggle_foe() return Hud.toggle_foe(self) end

-----------------------------
--- _handle_controller_callback
----------------------------------
--- Helper: reset debug
function GMgr:_reset_debug() if not self.debug_tools then return end; self.debug_tools:remove(); self.debug_tools = nil;  end

--- Helper: handle controller intent
function GMgr:_handle_controller_intent(intent)
    if not intent then return end
    local intent_type = type(intent) == "table" and intent.type or intent
    local handler     = Intents[intent_type]
    if handler then handler(self, intent.payload) end
end

--- Helper: handle controller intents
function GMgr:_handle_controller_intents(intents)
    if not intents then return end
    for _, intent in ipairs(intents) do self:_handle_controller_intent(intent) end
end

function GMgr:_handle_controller_callback(intent) self:_handle_controller_intent(intent) end

end
