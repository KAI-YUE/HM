local Color = require("HMfns.animate.color.color_utils")

local tint_color = Color.tint

local Y, N = true, false

return function(HMWidget)

--- Helper: _focus_is | _hover_is
local function _focus_is(w)  local st = w and w.states and w.states.focus; return st and st.is end
local function _hover_is(w)  local st = w and w.states and w.states.hover; return st and st.is end

--- Helper: _ancestor_hover_or_focus
local function _ancestor_hover_or_focus(w)
    local p = w and w.parent
    if _hover_is(p) or _focus_is(p) then return Y end
    while p do
        local fargs = p.config and p.config.focus_args
        if fargs and fargs.type and fargs.type:match("_row$") and fargs.type ~= "switch_row" and _focus_is(p) then return Y end
        p = p.parent
    end
end

--- Helper: _idle_visual_color
local function _idle_visual_color(cfg, key, color)
    local idle = cfg["idle_" .. key];       if idle then return idle end
    local idle_color = cfg.idle_color;      if not idle_color then return color end

    if idle_color[key] then return idle_color[key] end
    if idle_color[1] then return idle_color end
    return color
end

---____________________________
--- main: resolve_visual_color
---______________________________________
function HMWidget:resolve_visual_color(key)
    local cfg           = self.config
    local color         = cfg[key]
    local parent_hover  = cfg.parent_hover_tint and _ancestor_hover_or_focus(self)
    local self_hover    = _hover_is(self)
    local self_focus    = _focus_is(self)

    if not (parent_hover or (cfg.button and (self:button_visual_active() or self_hover or self_focus))) then return _idle_visual_color(cfg, key, color) end
    if not color then return end

    local hover_color = cfg.hover_color
    if hover_color then if hover_color[key] then return hover_color[key] elseif hover_color[1] then return hover_color end end

    if (cfg.hover_tint or 0) ~= 0 then return tint_color(color, cfg.hover_tint) end
    return color
end

---____________________________
--- main: button_visual_active
---______________________________________
function HMWidget:button_visual_active()
    local cfg, gm = self.config, self.gm;       if not cfg.button then return N end

    local Ctrl   = gm.CTRL
    local cdown  = Ctrl.cursor_down
    if Ctrl.is_cursor_down and cdown and cdown.target == self then return Y end

    local lc = self.last_clicked
    return lc and gm._T.real_s < lc + (cfg.click_visual_time or 0.1)
end

---____________________________
--- main: button_press_distance
---______________________________________
function HMWidget:button_press_distance()
    local dist = self.config.widget_dist or 1
    if self:button_visual_active() then return Y, dist end
    return N, dist
end

end
