local TabTextfx        = require("HMui.menu.data.pages._3_opt_menu_page.tabs.tab_ops.tab_textfx")
local Tabs, TabHit     = require("HMui.menu.data.pages._3_opt_menu_page.tabs"), require("HMui.menu.data.pages._3_opt_menu_page.tabs.tab_ops.tab_hit")
local TabSwitchAnims   = require("HMui.menu.data.pages._3_opt_menu_page.anims.anim_tab_switch")
local ChildAnimations  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")
local Tree             = require("HMEng.ui_actors.common.tree")
local TextDescription  = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")

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
    if panel then panel.opt_tab_state = state end
    return state
end

--- Helper: _source_pick
local function _source_pick(gm, mini, source)
    local cfg = source and source.config
    if cfg and cfg.options_tab_step then return Tabs.step_key(_tab_state(gm, _overlay_panel(gm)), cfg.options_tab_step), Y end
    if cfg and cfg.options_tab_key then return cfg.options_tab_key end
    return TabHit.cursor_tab_key(gm, mini, source), N
end

--- Helper: _switch_children
local function _switch_children(gm, panel, widget, state, token)
    local children            = Tabs.selected_child_widgets(state, gm)
    local control_lock_delay  = Tabs.child_control_lock_delay(children, panel.stroked_page_child_control_lock_delay)
    
    panel.stroked_page_child_control_lock_delay = control_lock_delay
    local old_children, new_children = ChildAnimations.start(panel, widget, gm, children, TabSwitchAnims.switch_delay, token)
    ChildAnimations.queue_finish(panel, gm, widget, old_children, new_children, token, TabSwitchAnims.switch_delay, control_lock_delay)
end

--- Helper: _tab_header_mini
local function _tab_header_mini(panel) return Tree.find_child_by_id(panel and panel.attached_panel, "opt_menu_mini_page") end

--- Helper: active tab textfx
local function _active_tab_textfx(mini, state)
    local key = state and state.active_key
    for _, fx in ipairs((mini and mini.page_card_textfx) or {}) do if fx.config and fx.config.options_tab_key == key then return fx end end
end

---____________________________
--- main: opt_tab_switch
---____________________________
function M.opt_tab_switch(gm, source)
    local panel   = _overlay_panel(gm);                       if not panel  then return end
    local widget  = panel.widget;                             if not widget then return end
    local mini    = _tab_header_mini(panel);                  if not mini   then return end
    local state   = _tab_state(gm, panel)
    local key, ordered = _source_pick(gm, mini, source);      if not key or key == state.active_key then return Y end
    TextDescription.clear_hover_description(mini, Y, Y)

    local old_state = { active_key = state.active_key, queue = state.queue }
    panel.opt_tab_state = ordered and Tabs.select_ordered(state, key) or Tabs.select(state, key)
    gm.opt_menu_tab_state = panel.opt_tab_state

    local token = _next_token(panel)
    TabTextfx.replace(gm, panel, mini, old_state, panel.opt_tab_state, key, token)
    _switch_children(gm, panel, widget, panel.opt_tab_state, token)
    return Y
end

---_________________________________
--- main: show_active_tab_info
---_________________________________
function M.show_active_tab_info(gm)
    local panel = _overlay_panel(gm);                         if not panel then return end
    local mini  = _tab_header_mini(panel);                    if not mini then return end
    local fx    = _active_tab_textfx(mini, _tab_state(gm, panel)); if not fx then return end
    TextDescription.set_hover_description(mini, fx, { pinned = Y })
    return Y
end

function M.opt_tab_step(gm, step)
    if type(step) == "table" then step = step.step or (step.config and step.config.options_tab_step) end
    return M.opt_tab_switch(gm, { config = { options_tab_step = step or 1 } })
end

return M
