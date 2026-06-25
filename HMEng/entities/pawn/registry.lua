local Actor      = require("HMEng.actors.actor")
local TableUtils = require("HMfns.utils.table_utils")

local destroy_tree = TableUtils.destroy_tree
local push         = table.insert

local Tst     = { "collide", "hover", "click", "drag" }
local Tshader = { "generic" }

--- toddle config 
local Tdt     = { "dur", "min_dur", "bob", "sway", "noise_x", "noise_y", "noise_r", "noise_dur", "noise_sway" }
local Tdv     = {  0.82,  0.35,      0.10,  0.12,   0.04,      0.02,      0.02,       1.0,             0.4  }

--- bounce config
local Tbt     = { "target_sy", "appear_dur", "total_dur", "squash_sy", "squash_sx", "first_peak_sy", "spring_k", "spring_damp", "pop_velocity", "launch_boost", "width_gain", "settle_speed", "min_cycles" }
local Tbv     = {  1.0,         0.05,         2,           0.98,        1.32,        1.2,             250,        1.0,           4.5,            2,              0.38,         4,              1 }

--- cast shadow config (height is for h in draw_shadow)
local Tcst    = { "height", "scale_x", "scale_y", "shear_x", "shear_y", "offset_x", "offset_y", "alpha" }
local Tcsv    = {  0.01,        0.8,      0.62,      0.6,     0.,         0.05,       -0.1,      0.82   }

local Y, N    = true, false

local function _orig() return { x = 0, y = 0, r = 0 } end  

return function (Pawn)
-------------------------------------------------------
--- init pawn attributes
-------------------------------------------------------
--- Helper: init toddle
function Pawn:init_toddle(p, x, y)
    local td = { active = N, t = 0, offset = _orig(), from_offset = _orig(), target_offset = _orig(), anchor = { x = x or 0, y = y or 0, r = 0 } }

    for i, key in ipairs(Tdt) do td[key] = p["toddle_" .. key] or Tdv[i] end
    td.base_dur, td.base_sway = td.dur, td.sway
    self.toddle = td
end

--- Helper: init bounce 
function Pawn:init_bounce(p)
    local bn = { active = N,  phase = "idle",  t = 0, alpha = 1,  sx = 1, sy = 1, vy = 0 }
    for i, key in ipairs(Tbt) do bn[key] = p["bounce_" .. key] or Tbv[i] end
    self.bounce = bn
end

--- Helper: init cast shadow
function Pawn:init_cast_shadow(p)
    local src = (type(p.cast_shadow) == "table") and p.cast_shadow or {}
    local cfg = { enabled = (p.cast_shadow ~= N) }

    for i, key in ipairs(Tcst) do cfg[key] = src[key] or Tcsv[i] end
    self.cast_shadow = cfg
end

--- Helper: init shadow heights
function Pawn:init_shadow_heights(p)
    local idle, hover, active  = p.shadow_height_idle or 0.05, p.shadow_height_hover or 0.10, p.shadow_height_active or 0.15
    self.shadow_heights = { idle = idle, hover = hover, active = active }
    self.shadow_height  = idle
end

---_________________________________________
--- Main: init pawn 
---_________________________________________
function Pawn:init_pawn_attributes(gm, x, y, w, h, params)
    self.params, self.gm = params or {}, gm
    Actor.init(self, gm, x, y, w, h)

    local p = self.params

    self:init_toddle(p, x, y)
    self:init_bounce(p)
    self.zone,                 self.children          =  p.zone, self.children or {}
    self.cell,                 self.static            =  { row = p.row or p.r, col = p.col or p.c }, p.static

    self.selected,             self.highlighted       =  N,   N
    self.idle_tilt,            self.tilt_var          =  0,   { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 }
    self.hover_tilt,           self.tilt_shadow       =  1,   Y 
    self.draw_anchor_x,        self.draw_anchor_y     =  0.5, 1
    self.ground_contact_x,     self.ground_contact_y  =  p.ground_contact_x or 0.5, p.ground_contact_y or 1
    self.position_shader_mode, self.template_shader   =  1,   p.template_shader or Tshader[1]
    self.scale_mode,           self.fixed_scale       =  p.scale_mode or "cell", p.fixed_scale or p.scale or self.T.scale or 1
    
    self:init_cast_shadow(p)
    self:init_shadow_heights(p)

    local st = self.states
    for _, k in ipairs(Tst) do st[k].can = Y end
    st.shader_visible = st.shader_visible or { can = Y, is = Y }
    st.hide_shadow    = st.hide_shadow    or { can = Y, is = N }
    st.hide_cast      = st.hide_cast      or { can = Y, is = Y }

    local gR = gm.R
    if getmetatable(self) == Pawn then push(gR.PAWN, self) end
    self.RPAWN = gR.PAWN
end

-------------------------------------------------------
--- remove
-------------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function Pawn:remove()
    if self.zone then self.zone:remove_pawn(self) end

    destroy_tree(self.children)
    cleanup(self.RPAWN, self)
    Actor.remove(self)
end

end
