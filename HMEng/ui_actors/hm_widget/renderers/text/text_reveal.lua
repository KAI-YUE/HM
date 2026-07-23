local UTF8 = require("HMfns.utils.format.utf8_utils")

local Y, N = true, false

local M = {}

local floor = math.floor

--- Helper: char_count
local function _char_count(text) local n = 0; for _ in UTF8.chars(text or "") do n = n + 1 end; return n end

--- Helper: text_speed | text_speed_scale
local function text_speed(gm)
    local speed = math.floor((tonumber(gm and gm.SET and gm.SET.text_speed) or 3) + 0.5)
    if speed < 1 then speed = 1 elseif speed > 5 then speed = 5 end
    return speed
end
local function text_speed_scale(gm) return text_speed(gm) / 3 end

-----------------------------
--- visible_text
----------------------------------
--- Helper: _slice_chars
local function _slice_chars(text, count)
    if count <= 0 then return "" end
    local out, n = {}, 0
    for _, c in UTF8.chars(text or "") do n = n + 1; if n > count then break end; out[#out + 1] = c end
    return table.concat(out)
end

---____________________________
--- main: visible_text
---______________________________________
function M.visible_text(text, cfg, now, gm)
    if cfg.text_reveal ~= Y then return text end

    local total = cfg.text_reveal_total or _char_count(text)
    cfg.text_reveal_total = total
    if cfg.text_reveal_done then cfg.text_reveal_visible = total; return text end
    if text_speed(gm) >= 5 then cfg.text_reveal_visible, cfg.text_reveal_done = total, Y; return text end

    local rate, started_at  = (cfg.text_reveal_rate or 45) * text_speed_scale(gm), cfg.text_reveal_started_at or now or 0
    local visible           = floor(((now or started_at) - started_at) * rate)

    if visible >= total then cfg.text_reveal_visible, cfg.text_reveal_done = total, Y; return text end

    cfg.text_reveal_visible = visible
    cfg.text_reveal_done = N
    return _slice_chars(text, visible)
end

---____________________________
--- main: reset
---______________________________________
function M.reset(cfg, now, text)
    cfg.text_reveal_started_at, cfg.text_reveal_done     = now or 0, N
    cfg.text_reveal_total,      cfg.text_reveal_visible  = _char_count(text or ""), 0
end

-----------------------------
--- Misc fns: is_complete | skip to end
----------------------------------
function M.is_complete(cfg) return cfg.text_reveal ~= Y or cfg.text_reveal_done end
function M.skip_to_end(cfg) cfg.text_reveal_visible, cfg.text_reveal_done = cfg.text_reveal_total or 0, Y end

return M
