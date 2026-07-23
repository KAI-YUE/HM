local M = {}

local idle_layout = {
    x_start = 0.16,    --- left edge for the first idle tab slot
    gap     = 0.02,    --- horizontal space after each idle tab text bound
    char_w  = 0.032,   --- width estimate per text character
    fake_chars = 7,    --- fake-alignment width for padded idle tab text
    base_h = 0.18,     --- base textfx height before character scaling
    char_h = 0.012,    --- height added per text character
    y_lift = 0.05,     --- vertical lift factor from estimated textfx height
}

--- Helpers: text | text_w | idle_tab_y
local function _text(tab)        return tab and (tab.text or tab.text_i18n_key or tab.key) or "" end
local function _text_w(tab)      return #tostring(_text(tab))*idle_layout.char_w end
local function _idle_tab_y(tab)  local h = idle_layout.base_h + #tostring(_text(tab))*idle_layout.char_h; return (tab.y or 0) - h*idle_layout.y_lift end

--- Helpers: text_mid | align_middle_tab
local function _text_mid(pos, tab)       return (pos and pos.x or 0) + _text_w(tab)*0.5 end
local function _align_middle_tab(out, tabs)
    local l, m, r = out[1], out[2], out[3]; if not (l and m and r) then return end
    local target_mid = (_text_mid(l, tabs[1]) + _text_mid(r, tabs[3]))*0.5
    m.x = m.x + target_mid - _text_mid(m, tabs[2])
end

--------------------------------
--- line_positions
--------------------------------
function M.line_positions(tabs)
    local out, x_start = {}, idle_layout.x_start
    for i, tab in ipairs(tabs or {}) do
        if i >= 4 then break end
        local w = idle_layout.fake_chars * idle_layout.char_w
        out[i] = { x = x_start, y = _idle_tab_y(tab), r = tab.r, anchor_x = 0, text_align = { x = "left", y = "middle" }, text_fake_align_width = idle_layout.fake_chars, textfx_space_bounds = true }
        x_start = x_start + w + idle_layout.gap
    end
    _align_middle_tab(out, tabs or {})
    return out
end

--- Helper: middle_x
function M.middle_x(tabs)
    local out = M.line_positions(tabs); if not (out[2] and tabs and tabs[2]) then return end
    return _text_mid(out[2], tabs[2])
end

return M
