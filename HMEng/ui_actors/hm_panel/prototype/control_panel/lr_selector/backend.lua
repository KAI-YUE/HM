local TextFit = require("HMfns.utils.format.text_fit")

local Y = true

local M = {}

local _text_scale          = 0.4
local _arrow_w,    _gap    = 0.32, 0.14

---____________________________
--- main: option_label
---______________________________________
function M.option_label(option)
    if type(option) ~= "table" then return tostring(option or "") end
    return tostring(option.label or option.text or option.value or option.key or "")
end

---____________________________
--- main: option_value
---______________________________________
function M.option_value(option)
    if type(option) ~= "table" then return option end
    if option.value ~= nil then return option.value end
    if option.key   ~= nil then return option.key end
    return option.label or option.text
end

-----------------------------
--- option_lang | selected_index
----------------------------------
function M.option_lang(option) if type(option) ~= "table" then return end; return option.lang end
function M.selected_index(options, value) for i, option in ipairs(options or {}) do if M.option_value(option) == value or M.option_label(option) == value then return i end end; return 1 end

---____________________________
--- main: display_option
---______________________________________
function M.display_option(options, value)
    local option = (options or {})[M.selected_index(options, value)]
    return option or value or ""
end

---____________________________
--- main: value_fit_args
---______________________________________
function M.value_fit_args(args)
    args = args or {}
    return {
        text_scale     = args.value_text_scale or _text_scale,  char_w_factor = args.value_char_w_factor or 0.62,
        stretch_factor = args.value_stretch_factor,             min_w = args.value_min_w or 1.08,
        max_w = args.value_max_w or 2.35,                       w = args.value_w,
    }
end

---____________________________
--- main: widest_value_text
---______________________________________
function M.widest_value_text(value, args)
    local text = M.option_label(value)
    for _, option in ipairs(args.options or {}) do local label = M.option_label(option); if #label > #text then text = label end end
    return text
end

-----------------------------
---  value_layout | child_by_id | sync_value_chip
----------------------------------
function M.value_layout(text, args) return TextFit.layout(text, M.value_fit_args(args)) end
function M.child_by_id(parent, id)  for _, child in ipairs((parent and parent.children) or {}) do if child.config and child.config.id == id then return child end end end
function M.sync_value_chip(chip, option) if not (chip and chip.config) then return end; chip.config.text, chip.config.lang = M.option_label(option), M.option_lang(option) or chip.gm.selected_lang end

---____________________________
--- main: select_option
---______________________________________
function M.select_option(state, dir, on_change)
    return function(gm, arrow)
        if state.refresh and state.refresh(gm, state, arrow) == false then return Y end

        local options = state.options or {}
        if #options <= 0 then return Y end

        state.idx     = ((state.idx or 1) + dir - 1) % #options + 1
        local option  = options[state.idx]

        M.sync_value_chip(M.child_by_id(arrow and arrow.parent, state.value_id), option)
        if on_change then on_change(gm, arrow, M.option_value(option), option) end
        return Y
    end
end

return M
