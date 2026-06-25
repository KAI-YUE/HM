local HMPanel = require("HMEng.ui_actors.hm_panel")

local Y, N = true, false

return function (DeckZone)
--------------------------------------------------
--- panel tree state helpers
--------------------------------------------------
local function set_widget_tree_visible(widget, visible)
    if not widget then return end
    widget.states.visible = visible
    widget.disable_button = not visible
    if not visible and widget.states.hover then widget.states.hover.is = N end
    for _, child in pairs(widget.children or {}) do set_widget_tree_visible(child, visible) end
end

--------------------------------------------------
--- deck hover button panel
--------------------------------------------------
local function hover_control_T(self)
    local cfg, T = self.config, self.T
    local bw = cfg.hover_control_button_w or 1.8
    local bh = cfg.hover_control_button_h or 0.42
    local gap = cfg.hover_control_gap or 0.12
    local w = cfg.hover_control_w or bw
    local h = cfg.hover_control_h or (2*bh + gap)
    local x = T.x + T.w + (cfg.hover_control_x_offset or 0.28)
    local y = T.y + 0.5*T.h - 0.5*h + (cfg.hover_control_y_offset or 0)
    return { x = x, y = y, w = w, h = h }
end

local function set_panel_visible(panel, visible)
    if not panel then return end

    panel.states.visible = visible
    if not visible and panel.states.hover then panel.states.hover.is = N end
    set_widget_tree_visible(panel.widget, visible)
end

function DeckZone:_set_panel_visible(panel, visible)
    set_panel_visible(panel, visible)
end

--------------------------------------------------
--- panel hover helpers
--------------------------------------------------
local function panel_hovered(panel)
    if not panel then return N end
    if panel.states.hover.is then return Y end
    if panel.widget.states.hover.is then return Y end
    for _, child in ipairs((panel.widget and panel.widget.children) or {}) do if child.states and child.states.hover and child.states.hover.is then return Y end; end
    return N
end

--------------------------------------------------
--- helper: close_hover_controls
--------------------------------------------------
function DeckZone:close_hover_controls()
    self.hover_controls_open = N
    self:_set_panel_visible(self.hover_controls, N)
end

--------------------------------------------------
--- helper: ensure_hover_controls
--------------------------------------------------
function DeckZone:_ensure_hover_controls()
    if self.hover_controls then return self.hover_controls end

    local cfg   = self.config
    local panel = HMPanel(self.gm, {
        style = "empty_container",
        T = hover_control_T(self),
        child_widgets = self:_hover_control_widgets(cfg),
    })

    self.hover_controls = panel
    return panel
end

--------------------------------------------------
--- helper: position_hover_controls
--------------------------------------------------
function DeckZone:_position_hover_controls(panel)
    local T = hover_control_T(self)
    panel:hard_set_T(T.x, T.y, T.w, T.h)
    if panel.widget then panel.widget:hard_set_T(T.x, T.y, T.w, T.h) end
end

function DeckZone:_hover_controls_visible(panel)
    return panel_hovered(panel)
end

end
