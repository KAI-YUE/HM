local Common = require("HMEng.ui_actors.card_textfx.in_factory.build.common")

local abs, cos, floor, max, min, sin = math.abs, math.cos, math.floor, math.max, math.min, math.sin
local Y, N = true, false

--- Helper: _include_point
local function _include_point(b, x, y)
    b.x0, b.y0 = min(b.x0 or x, x), min(b.y0 or y, y)
    b.x1, b.y1 = max(b.x1 or x, x), max(b.y1 or y, y)
end

--- Helper: _letter_y_radius | bounds_violation
local function _letter_y_radius(letter) return 0.5*(abs(sin(letter.r))*letter.paper_w + abs(cos(letter.r))*letter.paper_h) end
local function _bounds_violation(center, radius, upper, lower) return max(0, upper - (center - radius), (center + radius) - lower) end

return function (CardTextFx)
-----------------------------
--- bounds
----------------------------------
--- Helper: _include_letter_bounds
function CardTextFx:_include_letter_bounds(cache, letter)
    local pad,  b    = letter.paper_pad,            cache.bounds
    local s_pw, s_ph  = letter.letter_s_pw or 1.2,  letter.letter_s_ph or 0.62
    local o_px, o_py  = letter.letter_bg_o_px or 0, letter.letter_bg_o_py or 0.5

    local x0,   y0    = min(pad.x, o_px), min(pad.y, o_py)
    local x1,   y1    = max(pad.x + letter.w, o_px + s_pw*letter.paper_w), max(pad.y + letter.h, o_py + s_ph*letter.paper_h)

    local cx,   cy    = 0.5*letter.paper_w, 0.5*letter.paper_h
    local cr,   sr    = cos(letter.r), sin(letter.r)
    local px,   py    = letter.x + letter.ox, letter.y + letter.oy

    for _, p in ipairs({ { x0, y0 }, { x1, y0 }, { x1, y1 }, { x0, y1 } }) do
        local dx, dy = p[1] - cx, p[2] - cy
        _include_point(b, px + cx + dx*cr - dy*sr, py + cy + dx*sr + dy*cr)
    end
    local abs_r = abs(letter.r)
    if abs_r > (cache.max_abs_r or 0) then cache.max_abs_r = abs_r; cache.r = letter.r end
end

--- Helper: _finalize_bounds
function CardTextFx:_finalize_bounds(cache)
    local b = cache.bounds
    if not b.x0 then b.x0, b.y0, b.x1, b.y1 = 0, 0, cache.w or 0, cache.h or 0 end
    b.x, b.y, b.w, b.h = b.x0, b.y0, b.x1 - b.x0, b.y1 - b.y0
    cache.r = cache.r or 0
end

--- Helper: _rebuild_letter_bounds
function CardTextFx:_rebuild_letter_bounds(cache)
    cache.bounds, cache.max_abs_r, cache.r = {}, 0, nil
    for _, letter in ipairs(cache.letters or {}) do self:_include_letter_bounds(cache, letter) end
end

-----------------------------
--- post build
----------------------------------
--- Helper: _guard_letter_jitter
function CardTextFx:_guard_letter_jitter(cache)
    local cfg = self.config or {};          if cfg.textfx_jitter_guard == N then return end
    local letters = cache.letters or {}
    local first   = letters[1];             if not first then return end

    local cr         = cos(first.r)
    local slope      = abs(cr) < 0.001 and 0 or sin(first.r)/cr
    local first_cx   = first.x + first.ox + 0.5*first.paper_w
    local first_cy   = first.y + (first.base_oy or first.oy or 0) + 0.5*first.paper_h
    local bias       = cfg.textfx_jitter_guard_bias or 0.025
    local half_band  = _letter_y_radius(first) + bias
    local changed    = N

    for _, letter in ipairs(letters) do
        local jitter_oy = letter.jitter_oy or 0
        if jitter_oy == 0 then goto continue end

        local cx,     center     = letter.x + letter.ox + 0.5*letter.paper_w, letter.y + letter.oy + 0.5*letter.paper_h
        local line_y, radius     = first_cy + slope*(cx - first_cx), _letter_y_radius(letter)
        local upper,  lower      = line_y - half_band, line_y + half_band
        local violation          = _bounds_violation(center, radius, upper, lower)
        local fixed_violation    = _bounds_violation(center - jitter_oy, radius, upper, lower)

        if violation > 0 and fixed_violation < violation then letter.oy, letter.jitter_oy = letter.oy - jitter_oy, 0; changed = Y end
        ::continue::
    end

    if changed then self:_rebuild_letter_bounds(cache) end
end

--- Helper: _apply_auto_bounds
function CardTextFx:_apply_auto_bounds(cache)
    local cfg, b  = self.config, cache.bounds;       if not b then return end
    local T, VT   = self.T, self.VT
    local anchor  = cfg.textfx_anchor or { x = T.x, y = T.y, ax = 0.5, ay = 0.5 }

    if cfg.textfx_auto_w then T.x, VT.x, T.w, VT.w = anchor.x - anchor.ax*b.w, anchor.x - anchor.ax*b.w, b.w, b.w end
    if cfg.textfx_auto_h then T.y, VT.y, T.h, VT.h = anchor.y - anchor.ay*b.h, anchor.y - anchor.ay*b.h, b.h, b.h end
end

--- Helper: _assign_idle_flippers
function CardTextFx:_assign_idle_flippers(cache)
    local cfg = self.config or {}
    if cfg.letter_flip == N or cfg.textfx_static == Y then return end

    local letters = cache.letters
    local n = #letters;                              if n <= 0 then return end
    local target = min(2, max(1, floor(n/4 + 0.5)))
    local ranked = {}

    for i, letter in ipairs(letters) do
        letter.idle_flippable = N
        ranked[#ranked + 1] = { index = i, score = Common.cache_sampling_unit(cache, i, "idle_flippable") }
    end

    table.sort(ranked, function(a, b) return a.score < b.score end)
    for i = 1, target do letters[ranked[i].index].idle_flippable = Y end
end

end
