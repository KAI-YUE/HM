local TabTitle = require("HMEng.ui_actors.card_textfx.presets.tab_title")

local Y, N = true, false

local M = {}

M.keys = { "full_deck", "remaining", "discard" }

local labels = {
    full_deck  = "Full Deck",
    remaining  = "Remaining",
    discard    = "Discard",
}

local positions = {
    full_deck = { x = 0.34, y = 0.075, r = -0.04 },
    remaining = { x = 0.46, y = 0.065, r =  0.02 },
    discard   = { x = 0.58, y = 0.075, r = -0.03 },
}

--------------------------------------------------
--- deck preview tab helpers
--------------------------------------------------
local function page_tab(page_key, selected, switch_hook)
    local pos = positions[page_key]
    local tab = TabTitle.textfx({ key = page_key, x = pos.x, y = pos.y, r = pos.r }, {
        selected = selected,
        hook_fn = switch_hook,
        hover_icons = N,
    })
    tab.text_i18n_key = nil
    tab.text = labels[page_key]
    tab.deck_view_page_key = page_key
    tab.description_key = nil
    tab.text_hint, tab.paint_bg, tab.text_bg = N, N, N
    return tab
end

local function close_textfx(close_hook)
    return {
        key = "deck_view_close", text = "Close", room_ref = Y,
        x = 0.72, y = 0.075, r = 0.04,
        shadow = Y, button = Y, hook_fn = close_hook,
        text_align = { x = "center", y = "middle" },
        text_hint = N, paint_bg = N,
    }
end

--------------------------------------------------
--- build deck preview tabs
--------------------------------------------------
function M.build(selected, hooks)
    hooks = hooks or {}
    local tabs = {}
    for idx, page_key in ipairs(M.keys) do tabs[idx] = page_tab(page_key, page_key == selected, hooks.switch_page) end
    tabs[#tabs + 1] = close_textfx(hooks.close)
    return tabs
end

return M
