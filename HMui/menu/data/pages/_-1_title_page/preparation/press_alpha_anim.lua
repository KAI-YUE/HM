local Common = require("HMui.menu.data.pages._-1_title_page.anims.common")
local Layout = require("HMui.menu.data.pages._-1_title_page.preparation.layout")

local _after = Common.after
local _ease  = Common.ease

local Y = true

local M = {}

local _key = "_press_any_alpha"

local cfg = {
    high_alpha = 1.0,    low_alpha = 0.54,
    letter_step = 0.0,   fade_down_t = 0.5,
    hold_t = 0.5,        fade_up_t = 1,
    cycle_rest_t = 0.62,
    ease = "sine",
}

--- Helper: _letter_id
local function _letter_id(i) return "press_any_letter_" .. i end

--- Helper: _letter_alive
local function _letter_alive(letter, token) return letter and not letter.REMOVED and letter[_key .. "_token"] == token end

--- Helper: _collect_letters
local function _collect_letters(root)
    local out = {}
    for i = 1, #Layout.letters do out[i] = Common.find(root, _letter_id(i)) end
    return out
end

--- Helper: _prime_letter
local function _prime_letter(letter, token)
    Common.cache_widget(letter, _key)
    letter[_key .. "_token"] = token
    letter.draw_alpha = cfg.high_alpha
end

--- Helper: _pulse_letter
local function _pulse_letter(gm, letter, token, delay)
    _after(gm, delay, function()
        if not _letter_alive(letter, token) then return Y end
        _ease(gm, letter, "draw_alpha", cfg.low_alpha, cfg.fade_down_t, cfg.ease)
        _after(gm, cfg.fade_down_t + cfg.hold_t, function()
            if _letter_alive(letter, token) then _ease(gm, letter, "draw_alpha", cfg.high_alpha, cfg.fade_up_t, cfg.ease) end
            return Y
        end)
        return Y
    end)
end

--- Helper: _cycle_time
local function _cycle_time(count) return (count - 1)*cfg.letter_step + cfg.fade_down_t + cfg.hold_t + cfg.fade_up_t + cfg.cycle_rest_t end

----------------------------------------------
--- main: run cycle
----------------------------------------------
local function _run_cycle(gm, letters, token)
    if not _letter_alive(letters[1], token) then return Y end

    for i, letter in ipairs(letters) do if _letter_alive(letter, token) then _pulse_letter(gm, letter, token, (i - 1)*cfg.letter_step) end end
    _after(gm, _cycle_time(#letters), function() return _run_cycle(gm, letters, token) end)
    return Y
end

----------------------------------------------
--- main: start
----------------------------------------------
function M.start(gm, root)
    local letters = _collect_letters(root);       if not letters[1] then return end
    local token = (letters[1][_key .. "_token"] or 0) + 1

    for _, letter in ipairs(letters) do if letter then _prime_letter(letter, token) end end
    return _run_cycle(gm, letters, token)
end

return M
