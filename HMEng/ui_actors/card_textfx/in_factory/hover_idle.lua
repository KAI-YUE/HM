local rand = math.random
local max  = math.max

local Y, N = true, false

local HoverIdle = {}
-----------------------------
--- idle progress
----------------------------------
--- Helper: flip wave
local function _flip_wave(t, dur)
    if t <= 0    then return 0 end
    if t < dur   then return t / dur end
    if t < 2*dur then return 1 - (t - dur) / dur end
    return 0
end

--- Helper: idle role handoff
local function _handoff_idle_role(ctx, cache, letter, now)
    local rate = 0.35;          if rate <= 0 or rand() >= rate then return end

    local candidates = {}
    for _, other in ipairs(cache.letters or {}) do if other ~= letter and not other.idle_flippable then candidates[#candidates + 1] = other end end
    if #candidates <= 0 then return end

    local next_letter = candidates[rand(#candidates)]
    letter.idle_flippable,  next_letter.idle_flippable, next_letter.next_idle      = N, Y, now + 1.25 + 2*rand()
    next_letter.idle_start, next_letter.idle_flip_dur,  next_letter.idle_hold_dur  = nil, nil, nil
end

-----------------------------
--- idle_progress
----------------------------------
local function _idle_progress(ctx, cache, letter, now)
    if not letter.idle_flippable then return 0 end

    local cfg = ctx.config or {}
    if not letter.idle_start and (cfg.textfx_hover_active or cfg.textfx_hover_pending) then return 0 end
    if not letter.idle_start and now < (cfg.textfx_idle_resume_at or 0) then return 0 end
    if not letter.idle_start and now >= letter.next_idle then
        letter.idle_start     = now
        letter.idle_flip_dur  = rand() + 1
        letter.idle_hold_dur  = 0.5*rand() + 0.1
    end
    if not letter.idle_start then return 0 end

    local flip_dur   = letter.idle_flip_dur or 1
    local hold_dur   = letter.idle_hold_dur or 0.1
    local total_dur  = 2*flip_dur + hold_dur
    local t          = now - letter.idle_start

    if t < flip_dur            then return t / flip_dur end
    if t < flip_dur + hold_dur then return 1 end
    if t < total_dur           then return 1 - (t - flip_dur - hold_dur) / flip_dur end

    letter.idle_start, letter.idle_flip_dur, letter.idle_hold_dur = nil, nil, nil
    letter.next_idle = now + 8*rand() + 5 + 3.5 * ((letter.idle_phase + now * 0.137) % 1)
    _handoff_idle_role(ctx, cache, letter, now)
    return 0
end

-----------------------------
--- Update
----------------------------------
local function _delay_idle_flips(cache, resume_at)  for _, letter in ipairs(cache.letters or {}) do letter.next_idle = max(letter.next_idle or 0, resume_at) end end
local function _can_flip(ctx)
    local cfg = ctx.config or {}
    local selected = cfg.options_tab_visual_state == "selected"
    return (selected or cfg.letter_flip ~= N) and cfg.textfx_static ~= Y and cfg.textfx_reveal_lock ~= Y
end

--- Helper: _hovering
local function _hovering(cfg) return cfg.text_hint_hover == Y or (cfg.options_tab_visual_state == "selected" and cfg.opt_tab_hovered == Y) or (cfg.textfx_hover_event ~= N and cfg.opt_tab_hovered == Y) end

--- Helper: mark hover letters
local function _mark_hover_letters(cache, token)
    local last_delay = 0
    for _, letter in ipairs(cache.letters or {}) do
        letter.hover_token = token
        if letter.idle_start then
            letter.hover_skip = Y
            letter.hover_delay = nil
            goto continue
        end

        letter.hover_skip, letter.hover_delay = N, letter.delay or 0
        last_delay = letter.hover_delay
        ::continue::
    end
    return last_delay
end

--- Helper: hover event total
local function _hover_event_total(cache, token, dur) local last_delay = _mark_hover_letters(cache, token); return last_delay + 2*dur end

--- Helper: begin hover wave
local function _begin_hover_wave(ctx, cache, token)
    local cfg = ctx.config or {}
    local EM  = ctx.gm and ctx.gm.E_MANAGER;        if not EM then return end

    local dur   = 1.2
    local total = _hover_event_total(cache, token, dur)

    cfg.textfx_hover_pending                         = N
    cfg.textfx_hover_active, cfg.textfx_hover_t      = Y,     0
    cfg.textfx_hover_dur,    cfg.textfx_hover_total  = dur,   total

    EM:enqueue_event({   trigger   = "ease",            ease    = "sine",  blockable = N,
        ref_table = cfg, ref_value = "textfx_hover_t",  ease_to = total,   delay = total,
        func = function(v)
            if cfg.textfx_hover_token ~= token or cfg.textfx_hover_key ~= cache.key then return cfg.textfx_hover_t or 0 end
            if v < total then return v end
            local resume_at = ctx._T.real_s + 1
            cfg.textfx_hover_active, cfg.textfx_hover_t, cfg.textfx_idle_resume_at = N, nil, resume_at
            _delay_idle_flips(cache, resume_at)
            return nil
        end,
    })
end

--- Helper: schedule hover event
local function _schedule_hover_event(ctx, cache)
    local cfg = ctx.config or {}
    local EM = ctx.gm and ctx.gm.E_MANAGER;        if not EM then return end

    local token = (cfg.textfx_hover_token or 0) + 1

    cfg.textfx_hover_token,   cfg.textfx_hover_key     = token, cache.key
    cfg.textfx_hover_pending, cfg.textfx_hover_active  = Y, N
    _begin_hover_wave(ctx, cache, token)
end

---____________________________
--- main: update
---______________________________________
function HoverIdle.update(ctx, cache, now)
    if not _can_flip(ctx) then return N end

    local cfg = ctx.config or {}
    local hovering = _hovering(cfg)

    if cfg.textfx_hover_key ~= cache.key then cfg.textfx_hover_active, cfg.textfx_hover_pending, cfg.textfx_hover_t, cfg.textfx_hover_key = N, N, nil, nil end
    if hovering and not cfg.textfx_hover_was_hovering and not cfg.textfx_hover_active and not cfg.textfx_hover_pending then _schedule_hover_event(ctx, cache) end

    cfg.textfx_hover_was_hovering = hovering
    return cfg.textfx_hover_active
end

---____________________________
--- main: progress
---______________________________________
function HoverIdle.progress(ctx, cache, letter, now)
    if not _can_flip(ctx) then return 0 end

    local cfg = ctx.config or {}
    if cfg.textfx_hover_active then
        if letter.hover_token == cfg.textfx_hover_token and letter.hover_skip then return _idle_progress(ctx, cache, letter, now) end
        return _flip_wave((cfg.textfx_hover_t or 0) - (letter.hover_delay or letter.delay or 0), cfg.textfx_hover_dur or 0.18)
    end
    return _idle_progress(ctx, cache, letter, now)
end

return HoverIdle
