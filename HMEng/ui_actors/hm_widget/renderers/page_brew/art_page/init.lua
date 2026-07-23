local TextFx       = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local ChildWidgets = require("HMEng.ui_actors.hm_widget.renderers.page_brew.art_page.child_widgets")
local Render       = require("HMEng.ui_actors.hm_widget.renderers.page_brew.art_page.render")

local Y = true

local M = {}

M.draws_children = Y
M.handles_child_widgets = Y

M.config_keys = {
    "card_textfx", "child_widgets", "i18n_type", "i18n_scope", "hover_dwell_desc",
    "draw_order", "switch_textfx_ordered_reveal", "widget_dist",
}

-----------------------------
--- main
----------------------------------
function M.init(self, gm)
    TextFx.init_card_textfx(self, gm)
    ChildWidgets.init(self, gm)
end

function M.draw(self) return Render.draw(self) end
function M.hit_test() return Y end

return M
