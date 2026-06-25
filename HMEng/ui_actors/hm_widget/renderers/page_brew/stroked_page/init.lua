local StrokeBrush = require("HMEng.visual.stroked_brush")
local TextFx      = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local Render      = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.render")
local Split       = require("HMEng.ui_actors.hm_widget.renderers.page_brew.stroked_page.split")
local Tree        = require("HMEng.ui_actors.common.tree")

local Y, N = true, false

local M = {}

M.draws_children        = Y
M.handles_child_widgets = Y

M.config_keys = {
    "atlas_key",      "split",          "page_regions",      "page_region_polygons", "page_colors", "strokes", "stroke_color",
    "shadow",         "shadow_color",   "seam_shader",       "_0_seam_feather",
    "fx_mask_shader", "fx_mask_ref",    "fx_mask_dir",       "fx_mask_seed",
    "hover_color",    "hover_tint",     "click_visual_time", "widget_dist",
    "card_textfx",    "child_widgets",  "i18n_type",         "i18n_scope", "hover_dwell_desc",
    "draw_order",
    "scroll_target_id",
}

--- Helper: init child widgets
local function _child_role(gm, self, item, T)
    local major = item.room_ref and gm._room_r or self
    return { role_type = "Minor", major = major, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" }
end

--- Helper: _new_child
local function _new_child(gm, item)
    local T = item.T or {}
    if item.actor == "anim_decorator" then local AnimDecorator = require("HMEng.ui_actors.anim_decorator.init"); return AnimDecorator(gm, T.x, T.y, T.w, T.h or T.w, item); end
    local HMWidget = require("HMEng.ui_actors.hm_widget")
    return HMWidget(gm, item)
end

--- Helper: _init_child_widgets
local function _init_child_widgets(self, gm)
    local cfg   = self.config.child_widgets;       if not cfg then return end
    local items = cfg[1] and cfg or { cfg }

    self.page_child_widgets = {}
    for _, item in ipairs(items) do
        local T      = item.T or {}
        local child  = _new_child(gm, item)
        child.parent = self

        child:set_role(_child_role(gm, self, item, T))
        self.children[#self.children + 1] = child
        self.page_child_widgets[#self.page_child_widgets + 1] = child
    end
end

---____________________________
--- main: init
---______________________________________
function M.init(self, gm)
    local cfg   = self.config
    local atlas = gm.T_atlas[cfg.atlas_key];        if not atlas then return end

    cfg.page_regions, cfg.strokes = Split.regions(gm, cfg.split), Split.strokes(cfg.split)

    self.page_stroke_sprites = {}

    for _, stroke in ipairs(cfg.strokes or {}) do
        local brush = StrokeBrush(gm, stroke, cfg.atlas_key or "ui")
        if brush.quad then self.page_stroke_sprites[#self.page_stroke_sprites + 1] = brush end
    end

    TextFx.init_card_textfx(self, gm)
    _init_child_widgets(self, gm)
end

---____________________________
--- main: draw
---______________________________________
function M.draw(self) return Render.draw(self) end

---____________________________
--- main: hit_test
---______________________________________
function M.hit_test() return Y end

---____________________________
--- main: scroll
---______________________________________
function M.scroll(self, Ctrl, dir, count)
    local target_id = self.config.scroll_target_id;        if not target_id then return N end
    local target = Tree.find_child_by_id(self, target_id); if not target or not target.scroll then return N end
    return target:scroll(Ctrl, dir, count)
end

return M
