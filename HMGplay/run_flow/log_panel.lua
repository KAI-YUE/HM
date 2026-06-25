local HMPanel = require("HMEng.ui_actors.hm_panel")
local RunLog  = require("HMGplay.run_flow.log")
local C       = require("HMfns.animate.color.color_const")

local Y = true

local M = {}

-----------------------------
--- create
----------------------------------
--- Helper: set panel text
local function _set_panel_text(panel, log, args)
    if not (panel and panel.widget and panel.widget.config) then return end
    panel.widget.config.text = RunLog.text(log, args)
end

function M.create(gm, log, args)
    args = args or {}
    local panel = HMPanel(gm, {
        style      = args.style or "paint_rect",
        T          = args.T,
        text       = RunLog.text(log, args),
        text_scale = args.text_scale or 0.25,
        text_color = args.text_color or C.UI.TEXT_LIGHT,
        fill_color = args.fill_color or C.BLACK,
    })
    panel.states.visible = args.visible == Y
    panel.run_log        = log
    panel.run_log_args   = args
    return panel
end

-----------------------------
--- refresh
----------------------------------
function M.refresh(panel)
    if not panel then return end
    _set_panel_text(panel, panel.run_log, panel.run_log_args)
end

-----------------------------
--- set_visible
----------------------------------
function M.set_visible(panel, visible)
    if panel and panel.states then panel.states.visible = visible == Y end
end

-----------------------------
--- toggle
----------------------------------
function M.toggle(panel)
    if not (panel and panel.states) then return end
    panel.states.visible = not panel.states.visible
    M.refresh(panel)
    return panel.states.visible
end

return M
