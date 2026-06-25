local TextFx   = require("HMEng.ui_actors.hm_widget.renderers.page_brew.textfx")
local Children = require("HMEng.ui_actors.hm_widget.renderers.page_brew.render_children")

local Y = true

local M = {}

-----------------------------
--- main: draw
----------------------------------
function M.draw(self)
    local card_textfx_first = self.config.draw_order == "card_textfx_first"
    local card_textfx_shadow_first = self.config.draw_order == "card_textfx_shadow_first"

    if card_textfx_first then TextFx.draw_card_textfx(self) end
    if card_textfx_shadow_first then TextFx.draw_card_textfx(self, { shadow_only = Y }) end

    Children.draw(self)

    if not card_textfx_first then TextFx.draw_card_textfx(self, { skip_shadow = card_textfx_shadow_first }) end
end

return M
