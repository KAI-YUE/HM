local TabUtils = require("HMfns.utils.table_utils")
local RNG      = require("HMfns.utils.math.rng_utils")

local seeded_rand    = RNG.seeded_random
local weighted_pick  = RNG.weighted_pick
local weighted_refs  = RNG.weighted_refs
local random_pick    = TabUtils.random_pick
local floor, min, max = math.floor, math.min, math.max

local Y, N = true, false

--- Helper: clamp | char rule value
local function clamp(v, lo, hi) if lo > hi then return 0.5*(lo + hi) end; return max(lo, min(hi, v)) end
local function _is_digit(char) return type(char) == "string" and char:match("^%d$") ~= nil end

--- Helper: _positive_int
local function _positive_int(v)
    v = tonumber(v)
    if not v or v <= 0 then return end
    return max(1, floor(v))
end

--- Helper: _sampling_group_limit
local function _sampling_group_limit(sampling, group_key)
    sampling = sampling or {}
    if group_key == "ransom" then return _positive_int(sampling.max_allowable_ransom_fonts or sampling.ransom_max_allowable_fonts or sampling.max_allowable_fonts) end
    return _positive_int(sampling.max_allowable_normal_fonts or sampling.normal_max_allowable_fonts or sampling.max_allowable_fonts)
end

--- Helper: _limited_group_weights
local function _limited_group_weights(group, state)
    local out = {}
    for _, font in ipairs(weighted_refs(group)) do if state and state.seen and state.seen[font] then out[font] = group[font] end end
    return out
end

--- Helper: _sampling_bool
local function _sampling_bool(sampling, key, default)
    if sampling and sampling[key] ~= nil then return sampling[key] end
    return default
end

return function (CardTextFx)
function CardTextFx:_ransom_sampling_rate(sampling)  local rate =  sampling and sampling.ransom_sampling_rate or 0.1; return clamp(rate, 0, 1) end

--- Helper: _avoid_successive_ransom
function CardTextFx:_avoid_successive_ransom(sampling, rate, cache)
    if not cache or not cache.font_sampling_prev_is_ransom or rate >= 1 then return N end
    return _sampling_bool(sampling, "avoid_successive_ransom", _sampling_bool(sampling, "avoid_successive_ransom_letters", N)) == Y
end

--- Helper: _font_sampling_group_state
function CardTextFx:_font_sampling_group_state(cache, group_key, sampling)
    local limit = _sampling_group_limit(sampling, group_key)
    if not limit or not cache then return end
    cache.font_sampling_limits = cache.font_sampling_limits or {}
    local state = cache.font_sampling_limits[group_key]
    if not state then
        state = { limit = limit, refs = {}, seen = {} }
        cache.font_sampling_limits[group_key] = state
    end
    state.limit = limit
    return state
end

--- Helper: _limited_font_pick
function CardTextFx:_limited_font_pick(group, seed, group_key, sampling, cache)
    if not group then return end

    local state = self:_font_sampling_group_state(cache, group_key, sampling)
    if state and #state.refs >= state.limit then
        return weighted_pick(self.gm, _limited_group_weights(group, state), seed)
    end

    local font = weighted_pick(self.gm, group, seed)
    if font and state and not state.seen[font] then
        state.seen[font] = Y
        state.refs[#state.refs + 1] = font
    end
    return font
end

function CardTextFx:_sample_font(seed, cache)
    local gm = self.gm
    local sampling = self:_font_sampling_cfg()
    if sampling.normal or sampling.ransom then
        local rate        = self:_ransom_sampling_rate(sampling)
        local use_ransom  = seeded_rand(gm, seed) < rate
        if use_ransom and self:_avoid_successive_ransom(sampling, rate, cache) then use_ransom = N end
        local group_key   = use_ransom and "ransom" or "normal"
        local other_key   = use_ransom and "normal" or "ransom"
        local group       = use_ransom and sampling.ransom or sampling.normal
        local other       = use_ransom and sampling.normal or sampling.ransom
        local font        = self:_limited_font_pick(group, seed + 1, group_key, sampling, cache) or self:_limited_font_pick(other, seed + 2, other_key, sampling, cache)
        if font then return font, sampling.ransom and sampling.ransom[font] ~= nil end
    end

    local fonts = self:_default_fonts()
    local font  = random_pick(fonts, seed + 1)
    return font, self:_font_ref_is_ransom(font), fonts
end

function CardTextFx:_sample_ransom_font(seed, cache)
    local gm       = self.gm
    local sampling = self:_font_sampling_cfg()
    local data_sampling = self:_data_fonts().card_font_sampling or {}

    if sampling.ransom then
        local font = self:_limited_font_pick(sampling.ransom, seed + 1, "ransom", sampling, cache)
        if font then return font end
    end
    if data_sampling.ransom then
        local font = weighted_pick(gm, data_sampling.ransom, seed + 2)
        if font then return font end
    end

    for _, font in ipairs(self:_default_fonts() or {}) do
        if self:_font_ref_is_ransom(font) then return font end
    end
end

function CardTextFx:_force_ransom_number(char)
    local cfg      = self.config or {}
    local sampling = self:_font_sampling_cfg()
    local force    = cfg.ransom_numbers or cfg.number_ransom or cfg.force_ransom_numbers
        or sampling.ransom_numbers or sampling.number_ransom or sampling.force_ransom_numbers
    return force == Y and _is_digit(char)
end

function CardTextFx:_sample_font_for_char(char, seed, cache)
    local max_attempts, fallback = 12, nil

    if self:_force_ransom_number(char) then
        local font = self:_sample_ransom_font(seed, cache)
        local rule = font and self:_font_char_rule(font, char)
        if font and type(rule) == "table" and rule.fallback_font then return rule.fallback_font.name or rule.fallback, rule, N end
        if font and not rule then return font, nil, Y end
        fallback = font
    end

    for i = 0, max_attempts do
        local font, is_ransom = self:_sample_font(seed + i*13, cache)
        local rule = font and self:_font_char_rule(font, char)
        if font and type(rule) == "table" and rule.fallback_font then return rule.fallback_font.name or rule.fallback, rule, N end
        if font and not rule then return font, nil, is_ransom end
        fallback = fallback or font
    end

    local fonts = self:_font_fallbacks()
    for _, font in ipairs(fonts or {}) do
        local rule = self:_font_char_rule(font, char)
        if type(rule) == "table" and rule.fallback_font then return rule.fallback_font.name or rule.fallback, rule, N end
        if not rule then return font, nil, self:_font_ref_is_ransom(font) end
    end
    return fallback, nil, self:_font_ref_is_ransom(fallback)
end

end
