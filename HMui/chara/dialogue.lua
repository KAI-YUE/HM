local HMPanel   = require("HMEng.ui_actors.hm_panel")
local I18N      = require("HMfns.utils.format.i18n_utils")
local TabUtils  = require("HMfns.utils.table_utils")
local BoxData   = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.dialogue_box.three_dots")

local i18n = I18N.i18n
local copy = TabUtils.deep_copy

local Y, N = true, false

local M = {}

local FIRST_MEETING = "ch01.alice.first_meeting"

--------------------------------------------
--- show_dialogue_box
-------------------------------------------
local function _dialogue_T(gm)
    local T     = gm._room.T
    local x, y  = T.x, T.y 
    local w, h  = 0.8*T.w, T.h

    return { x = x, y = y + 0.75*h, w = w, h = h }
end

---________________________________
--- main: show dialogue box
---________________________________
function M.show_dialogue_box(gm, chara)
    local UI = gm.UI
    if UI.hm_dialogue_box_test then UI.hm_dialogue_box_test:remove() end

    local args = copy(BoxData)
    local d    = i18n(gm, { type = "dialogue", key = FIRST_MEETING })
    local ptr  = gm.dialogue_line_ptr and gm:dialogue_line_ptr(FIRST_MEETING)
    local line = ptr and ptr.line or 1
    if not d.lines[line] then line = 1 end

    args.T,    args.style       = _dialogue_T(gm), "dialogue_box"
    args.text, args.text_align  = d.lines[line], { x = "left", y = "top" }
    args.modal_cursor_context   = Y

    UI.hm_dialogue_box_test = HMPanel(gm, args)

    return UI.hm_dialogue_box_test
end

return M
