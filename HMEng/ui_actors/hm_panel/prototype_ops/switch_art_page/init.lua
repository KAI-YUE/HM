local TabUtils         = require("HMfns.utils.table_utils")
local ChildAnimations  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")
local TextDescription  = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")
local TextFxAnimations = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.textfx")

local copy = TabUtils.deep_copy

local Y = true

local T_pages = {
    "style",        "widget_style",      "renderer",         "widget_dist",
    "i18n_type",    "text",              "text_color",       "text_scale",
    "text_wrap",    "text_reveal",       "text_reveal_rate", "text_align",
    "text_line_spacing",
    "text_padding", "text_box_T",        "text_maxw",        "text_offset",
    "text_shadow",  "hover_dwell_desc",  "draw_order",
}

local T_replace_pages = { "hit_area" }
local T_description_text_pages = {
    i18n_type    = Y,   text = Y,              text_color = Y,   text_scale = Y,
    text_wrap    = Y,   text_reveal = Y,       text_reveal_rate = Y,
    text_align   = Y,   text_line_spacing = Y,
    text_padding = Y,   text_box_T = Y,        text_maxw = Y,    text_offset = Y,
    text_shadow  = Y,
}

return function(HMPanel)

-----------------------------
--- switch_art_page (replacement for generic pages beyond stroked_page_switch_token)
----------------------------------
--- Helper: page data | _should_skip_text_copy
local function _page_data(page) if type(page) == "string" then return require("HMEng.ui_actors.hm_panel.prototype." .. page) end; return page end
local function _should_skip_text_copy(cfg, page, key) return T_description_text_pages[key] and cfg.description_fading == Y and (page.text == nil or page.text == "") end

--- Helper: _queue_description_text_config
local function _queue_description_text_config(cfg, page)
    if not (cfg and cfg.description_fading == Y and (page.text == nil or page.text == "")) then return end
    local pending = {}
    for key in pairs(T_description_text_pages) do if page[key] ~= nil then pending[key] = copy(page[key]) end end
    cfg.description_after_fade_text_config = pending
end

--- Helper: _copy_page_keys
local function _copy_page_keys(cfg, page)
    _queue_description_text_config(cfg, page)
    for _, key in ipairs(T_pages) do if page[key] ~= nil and not _should_skip_text_copy(cfg, page, key) then cfg[key] = copy(page[key]) end; end
end

--- Helper: _replace_page_keys
local function _replace_page_keys(cfg, page) for _, key in ipairs(T_replace_pages) do cfg[key] = copy(page[key]) end end

--- Helper: next_switch_token
local function _next_switch_token(panel)
    panel.stroked_page_switch_token = (panel.stroked_page_switch_token or 0) + 1
    return panel.stroked_page_switch_token
end

--- Helper: _release_cursor_target
local function _release_cursor_target(gm) if gm.CTRL.cursor_down then gm.CTRL.cursor_down.target = nil end end

--- Helper: _fade_switch_description
local function _fade_switch_description(widget)
    local cfg = widget and widget.config
    if not (cfg and (cfg.description_hover_key or cfg.description_fading or (cfg.text or "") ~= "")) then return end
    TextDescription.clear_hover_description(widget, nil, Y)
end

--- Helper: run_switch_anim
local function _run_switch_anim(gm, panel, page, ctx)
    local fn = page.switch_anim and page.switch_anim.enter
    if type(fn) == "function" then return fn(gm, panel, page, ctx or {}) end
end

--- Helper: _child_control_lock_delay
local function _child_control_lock_delay(page, opts)
    if opts.child_control_lock_delay ~= nil then return opts.child_control_lock_delay end
    return page.child_control_lock_delay
end

---____________________________
--- main: switch_art_page
---______________________________________
function HMPanel:switch_art_page(page, opts)
    local widget = self.widget;                  if not widget then return end
    local cfg = widget.config;                   if not cfg or cfg.renderer ~= "art_page" then return end
    page, opts = _page_data(page), opts or {};   if not page then return end

    local gm, delay                = self.gm, opts.delay or 0.55
    local child_control_lock_delay = _child_control_lock_delay(page, opts)
    self.stroked_page_child_control_lock_delay = child_control_lock_delay

    local token = _next_switch_token(self)
    _release_cursor_target(gm)
    _fade_switch_description(widget)

    _copy_page_keys(cfg, page)
    _replace_page_keys(cfg, page)

    local old_children, new_children = ChildAnimations.start(self, widget, gm, page.child_widgets, delay, token)
    local old_list,     new_list     = TextFxAnimations.start(widget, gm, page, delay)

    _run_switch_anim(gm, self, page, { old_children = old_children, new_children = new_children, text_old = old_list, text_new = new_list, delay = delay, token = token })
    ChildAnimations.queue_finish(self, gm, widget, old_children, new_children, token, delay, child_control_lock_delay)
    TextFxAnimations.queue_finish(self, gm, widget, old_list, new_list, token, delay)

    return Y
end

end
