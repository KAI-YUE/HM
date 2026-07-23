local TabUtils, Common    = require("HMfns.utils.table_utils"), require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.shared.common")
local AttachedAnimations  = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.attached_panel")
local ChildAnimations     = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.child_widgets")
local TextDescription     = require("HMEng.ui_actors.hm_widget.renderers.page_brew.text_description")
local TextFxAnimations    = require("HMEng.ui_actors.hm_panel.prototype_ops.switch_stroked_page.textfx")

local copy = TabUtils.deep_copy

local Y = true

local T_pages = {
    "style",        "widget_style",      "renderer",         "quad_key",            "fill_color",   "stroke_color",
    "shadow",       "shadow_color",      "seam_shader",      "seam_feather",        "page_colors",
    "widget_dist",  "i18n_type",         "text",             "text_color",          "text_scale",   "text_wrap",
    "text_reveal",  "text_reveal_rate",  "text_align",       "text_line_spacing",
    "text_padding", "text_box_T",        "text_maxw",        "text_offset",
    "text_shadow",  "hover_dwell_desc",
}

local T_replace_pages  = { "scroll_target_id", "hit_area" }
local T_description_text_pages = {
    i18n_type    = Y,   text = Y,              text_color = Y,   text_scale = Y,        text_wrap = Y,
    text_reveal  = Y,   text_reveal_rate = Y,  text_align = Y,   text_line_spacing = Y,
    text_padding = Y,   text_box_T = Y,        text_maxw = Y,    text_offset = Y,  text_shadow = Y,
}
local T_split_timeline = {
    { at = 0.,     split = { "x" }, region = { "ox" }, stroke = { "ox" } },
    { at = 0.2,    split = { "y" }, region = { "oy" }, stroke = { "oy" } },
    { at = 0.45,   split = { "r" }, region = { "or" } },
}

return function (HMPanel)
-----------------------------
--- switch stroked_page: switch an existing stroked_page widget to another page prototype.
----------------------------------
--- Helper: page_data | _should_skip_text_copy
local function _page_data(page) if type(page) == "string" then return require("HMEng.ui_actors.hm_panel.prototype." .. page) end; return page end
local function _should_skip_text_copy(cfg, page, key) return T_description_text_pages[key] and cfg.description_fading == Y and (page.text == nil or page.text == "") end

--- Helper: _queue_description_text_config
local function _queue_description_text_config(cfg, page)
    if not (cfg and cfg.description_fading == Y and (page.text == nil or page.text == "")) then return end
    local pending = {}
    for key in pairs(T_description_text_pages) do if page[key] ~= nil then pending[key] = copy(page[key]) end end
    cfg.description_after_fade_text_config = pending
end

--- Helper: copy_page_keys | replace_page_keys
local function _copy_page_keys(cfg, page)    _queue_description_text_config(cfg, page); for _, key in ipairs(T_pages) do if page[key] ~= nil and not _should_skip_text_copy(cfg, page, key) then cfg[key] = copy(page[key]) end end end
local function _replace_page_keys(cfg, page) for _, key in ipairs(T_replace_pages) do cfg[key] = copy(page[key]) end end

--- Helper: own_color
local function _own_color(tab, key)
    local color = tab and tab[key];       if type(color) ~= "table" then return end
    local owned = {}
    for k, v in pairs(color) do owned[k] = v end
    tab[key] = owned
    return owned
end

--- Helper: fade_polygon_alpha | fade_polygons_alpha
local function _fade_polygon_alpha(gm, polygon, alpha, delay)   local color = _own_color(polygon, "color"); if not color then return end; Common.ease(gm, color, 4, alpha, delay) end
local function _fade_polygons_alpha(gm, polygons, alpha, delay) for _, polygon in ipairs(polygons or {}) do _fade_polygon_alpha(gm, polygon, alpha, delay) end end

--- Helper: switch_region_polygons
local function _switch_region_polygons(gm, panel, cfg, page, delay, token)
    local old_polygons  = cfg.page_region_polygons
    local new_polygons  = copy(page.page_region_polygons)

    if new_polygons     then  cfg.page_region_polygons = new_polygons; return end
    if not old_polygons then  cfg.page_region_polygons = nil;          return end

    _fade_polygons_alpha(gm, old_polygons, 0, delay)
    Common.after(gm, delay, function() if panel.stroked_page_switch_token == token then cfg.page_region_polygons = nil end; return Y; end )
end

--- Helper: next_switch_token
local function _next_switch_token(panel)
    panel.stroked_page_switch_token = (panel.stroked_page_switch_token or 0) + 1
    return panel.stroked_page_switch_token
end

--- Helper: release_cursor_target
local function _release_cursor_target(gm) if gm.CTRL.cursor_down then gm.CTRL.cursor_down.target = nil end end

--- Helper: _fade_switch_description
local function _fade_switch_description(widget)
    local cfg = widget and widget.config
    if not (cfg and (cfg.description_hover_key or cfg.description_fading or (cfg.text or "") ~= "")) then return end
    TextDescription.clear_hover_description(widget, nil, Y)
end

--- Helper: restore_old_value
local function _restore_old_value(dst, old, key)
    if not dst or not old then return end
    if old[key] ~= nil then dst[key] = old[key] end
end

--- Helper: ease_keys
local function _ease_keys(gm, dst, page_src, old_src, keys, delay, phase)
    if not dst or not page_src or not keys then return end
    for _, key in ipairs(keys) do
        local to = page_src[key]
        _restore_old_value(dst, old_src, key)
        Common.after(gm, phase, function() Common.ease(gm, dst, key, to, delay); return Y end)
    end
end

--- Helper: switch_split
local function _switch_split(gm, cfg, page, delay)
    local old_split  = cfg.split or {}
    cfg.split        = copy(page.split or {})

    local page_split                = page.split or {}
    local old_region, old_stroke    = old_split.region or {}, old_split.stroke or {}
    local page_region, page_stroke  = page_split.region or {}, page_split.stroke or {}

    for _, phase in ipairs(T_split_timeline) do
        local at = phase.at or 0
        _ease_keys(gm, cfg.split, page_split, old_split, phase.split, delay, at)
        _ease_keys(gm, cfg.split.region, page_region, old_region, phase.region, delay, at)
        _ease_keys(gm, cfg.split.stroke, page_stroke, old_stroke, phase.stroke, delay, at)
    end
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
--- main: switch_stroked_page
---____________________________
function HMPanel:switch_stroked_page(page, opts)
    local widget = self.widget;                  if not widget then return end
    local cfg = widget.config;                   if not cfg or cfg.renderer ~= "stroked_page" then return end
    page, opts = _page_data(page), opts or {};   if not page then return end

    local gm,   delay              =  self.gm, opts.delay or 1.2
    local child_control_lock_delay = _child_control_lock_delay(page, opts)
    self.stroked_page_child_control_lock_delay = child_control_lock_delay

    local token = _next_switch_token(self)
    _release_cursor_target(gm)
    _fade_switch_description(widget)

    _copy_page_keys(cfg, page)
    _replace_page_keys(cfg, page)
    _switch_region_polygons(gm, self, cfg, page, delay, token)
    _switch_split(gm, cfg, page, delay)

    local old_children, new_children  = ChildAnimations.start(self, widget, gm, page.child_widgets, delay, token)
    local old_list,     new_list      = TextFxAnimations.start(widget, gm, page, delay)
    local old_attached, new_attached  = AttachedAnimations.start(self, gm, page.attached_panel, delay)

    _run_switch_anim(gm, self, page, { old_children = old_children, new_children = new_children, text_old = old_list, text_new = new_list, old_attached = old_attached, new_attached = new_attached, delay = delay, token = token })
    ChildAnimations.queue_finish(self, gm, widget, old_children, new_children, token, delay, child_control_lock_delay)
    TextFxAnimations.queue_finish(self, gm, widget, old_list, new_list, token, delay)
    AttachedAnimations.queue_finish(self, gm, old_attached, new_attached, token, delay)

    return Y
end

end
