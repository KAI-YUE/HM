local ShaderFX      = require("HMEng.actors.shader_fx")
local IntroTimeline = require("HMfns.animate.start.intro_timeline")

local Y, N = true, false

local M = {}

--- Helper: enqueue_ease | enqueue_after  | set deck alpha
local function _enqueue_ease(EM, delay, ease,  ref_table, ref_value, ease_to, func) EM:enqueue_event({ trigger = "ease", delay = delay, ease = ease, blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to, func = func }) end
local function _enqueue_after(EM, delay, func) EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, func = func }) end
local function _set_deck_alpha(deck, alpha)    deck.draw_alpha = alpha; return alpha end

------------------------------------------------
--- main: animate deck fade in
------------------------------------------------
--- Helper: place deck sandstorm fx 
local function _place_deck_sandstorm_fx(gm, deck, timeline)
    local dT,    rT     = deck.T,   gm._room.T
    local pad_x, pad_y  = 1.3*rT.w, 1.2*rT.h
    local fx            = ShaderFX(gm, 0-dT.w, 0, pad_x, pad_y)

    fx.shader_code, fx.fx_mask, fx.draw_alpha = "sand_storm", 0, 1
    fx:set_render_layer(timeline.sand_layer or "above_hand")
    return fx
end

---_______________________________________
--- animate deck fade in 
---_______________________________________
function M.animate_deck_fade_in(gm)
    local deck, EM = gm.deck, gm.E_MANAGER;     if not deck or not EM then return end

    local timeline = IntroTimeline.deck
    local alpha    = { value = 0 }
    local sand_fx  = _place_deck_sandstorm_fx(gm, deck, timeline)

    _set_deck_alpha(deck, 0)
    _enqueue_after(EM, timeline.field_spawn, function()
        _enqueue_ease(EM, timeline.fade_in, "sine", alpha, "value", 1, function(t) return _set_deck_alpha(deck, t) end)
        if sand_fx and not sand_fx.REMOVED then  _enqueue_ease(EM, timeline.sand_erase, "sine", sand_fx, "draw_alpha", 0) end
        return Y
    end)

    _enqueue_after(EM, timeline.sand_erase + 2, function() if sand_fx and not sand_fx.REMOVED then sand_fx:remove() end; return Y end)
end

return M
