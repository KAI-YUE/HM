local Common       = require("HMui.menu.data.pages._3_opt_menu_page.tabs._3_4_system.widgets.common")
local ControlState = require("HMEng.ui_actors.hm_panel.prototype.control_panel.state")
local TextDesc     = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")

local min, max = math.min, math.max

local Y, N = true, false

local M = {}

--- Helper: slider_value
local function slider_value(gm, entry)
    local min_val, max_val  = entry.min_val, entry.max_val
    local value             = tonumber(gm.SET[entry.key]) or entry.default or min_val or 0
    if min_val then value = max(min_val, value) end
    if max_val then value = min(max_val, value) end
    return value
end

--- Helper: slider_fields
local function slider_fields(args, entry) for _, key in ipairs({ "min_val", "max_val", "steps", "decimals" }) do args[key] = entry[key] end end

--- Helper: active_description_widget
local function active_description_widget(gm)
    local UI     = gm and gm.UI
    local OM     = UI and (UI.overlay_menu or (UI.title_page_options and UI.title_page_panel))
    local widget = OM and OM.widget; if widget and widget.config and widget.config.renderer == "stroked_page" then return widget end
end

--- Helper: refresh_active_description
local function refresh_active_description(gm, entry)
    local widget = active_description_widget(gm);         if not (widget and widget.config) then return end
    local source = widget.config.description_hover_source; if not (source and source.config) then return end
    if widget.config.description_hover_key ~= (entry.description_key or entry.key) then return end
    TextDesc.set_hover_description(widget, source, { refresh = true })
end

-----------------------------
--- instant refresh helpers
----------------------------------
--- Helper: description_refresh_target
local function description_refresh_target(gm, entry)
    local widget = active_description_widget(gm);         if not (widget and widget.config) then return end
    local source = widget.config.description_hover_source; if not (source and source.config) then return end
    if widget.config.description_hover_key ~= (entry.description_key or entry.key) then return end
    return widget, source
end

--- Helper: refresh_instant_description
local function refresh_instant_description(gm, entry)
    local widget, source = description_refresh_target(gm, entry); if not widget then return refresh_active_description(gm, entry) end
    local cfg, EM        = widget.config, gm and gm.E_MANAGER;    if not EM then return refresh_active_description(gm, entry) end
    cfg.text_speed_refresh_token = (cfg.text_speed_refresh_token or 0) + 1
    local token = cfg.text_speed_refresh_token

    TextDesc.clear_hover_description(widget, Y)
    cfg.description_hover_lock = Y
    EM:enqueue_event({ trigger = "after", delay = EM.queue_dt or (1/60), blockable = N, blocking = N,
        func = function()
            if widget.REMOVED or cfg.text_speed_refresh_token ~= token then return Y end
            cfg.description_hover_lock = N
            TextDesc.set_hover_description(widget, source, { refresh = true })
            return Y
        end })
end

--- Helper: set_pending_slider_value
local function set_pending_slider_value(gm, entry, value)
    local min_val, max_val  = entry.min_val or 0, entry.max_val or 1
    local out               = min_val + (max_val - min_val)*value
    local prev              = tonumber(gm.SET and gm.SET[entry.key])
    
    if not entry.decimals or entry.decimals <= 0 then out = math.floor(out + 0.5) end
    ControlState.set_preview(gm, entry.key, out)
    if entry.key == "text_speed" and out == max_val and prev and prev < out then return refresh_instant_description(gm, entry) end
    refresh_active_description(gm, entry)
end

---________________________________
--- main: args
---________________________________
function M.args(gm, entry)
    local args      = Common.base_args(gm, entry)
    args.value      = slider_value(gm, entry)
    args.on_change  = function(_gm, _, value) return set_pending_slider_value(_gm, entry, value) end
    slider_fields(args, entry)
    return args
end

return M
