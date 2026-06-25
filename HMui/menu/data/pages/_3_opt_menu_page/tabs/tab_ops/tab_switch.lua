local Tabs             = require("HMui.menu.data.pages._3_opt_menu_page.tabs")
local TabHit           = require("HMui.menu.data.pages._3_opt_menu_page.tabs.tab_ops.tab_hit")
local TabTextfx        = require("HMui.menu.data.pages._3_opt_menu_page.tabs.tab_ops.tab_textfx")
local TabSwitchAnims   = require("HMui.menu.data.pages._3_opt_menu_page.anims.anim_tab_switch")
local ChildAnimations  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")

local Y = true

local M = {}

-------------------------------------------------
--- opt_tab_switch
-------------------------------------------------
--- Helper: _overlay_panel
local function _overlay_panel(gm)
    local gUI    = gm.UI
    local panel  = (gUI.overlay_menu or (gUI.title_page_options and gUI.title_page_panel))
    local widget = panel and panel.widget
    if widget and widget.config and widget.config.id ~= "opt_menu_mini_page" then return panel end
end

--- Helper: _next_token
local function _next_token(panel)
    panel.stroked_page_switch_token = (panel.stroked_page_switch_token or 0) + 1
    return panel.stroked_page_switch_token
end

--- Helper: _tab_state
local function _tab_state(gm, panel)
    local state = panel and panel.opt_tab_state or gm.opt_menu_tab_state or Tabs.default_state()
    gm.opt_menu_tab_state = state
    if panel  then panel.opt_tab_state   = state   end
    return state
end

--- Helper: _source_key
local function _source_key(gm, mini, source)
    local cfg = source and source.config
    if cfg and cfg.options_tab_step then return Tabs.step_key(_tab_state(gm, _overlay_panel(gm)), cfg.options_tab_step) end
    if cfg and cfg.options_tab_key then return cfg.options_tab_key end
    return TabHit.cursor_tab_key(gm, mini, source)
end

--- Helper: _switch_children
local function _switch_children(gm, panel, widget, state, token)
    local children            = Tabs.selected_child_widgets(state, gm)
    local control_lock_delay  = Tabs.child_control_lock_delay(children, panel.stroked_page_child_control_lock_delay)
    
    panel.stroked_page_child_control_lock_delay = control_lock_delay
    local old_children, new_children = ChildAnimations.start(panel, widget, gm, children, TabSwitchAnims.switch_delay, token)
    ChildAnimations.queue_finish(panel, gm, widget, old_children, new_children, token, TabSwitchAnims.switch_delay, control_lock_delay)
end

---____________________________
--- main: opt_tab_switch
---____________________________
function M.opt_tab_switch(gm, source)
    local panel   = _overlay_panel(gm);                       if not panel  then return end
    local widget  = panel.widget;                             if not widget then return end
    local mini    = panel.attached_panel;                     if not mini   then return end
    local state   = _tab_state(gm, panel)
    local key     = _source_key(gm, mini, source);            if not key or key == state.active_key then return Y end

    local old_state = { active_key = state.active_key, queue = state.queue }
    panel.opt_tab_state = Tabs.select(state, key)
    gm.opt_menu_tab_state = panel.opt_tab_state

    local token = _next_token(panel)
    TabTextfx.replace(gm, panel, mini, old_state, panel.opt_tab_state, key, token)
    _switch_children(gm, panel, widget, panel.opt_tab_state, token)
    return Y
end

function M.opt_tab_step(gm, step) return M.opt_tab_switch(gm, { config = { options_tab_step = step or 1 } }) end

return M
