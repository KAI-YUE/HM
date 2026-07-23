local ParticleEmitter  = require("HMEng.actors.particle_emitter")
local SoundUtils, C    = require("HMfns.utils.sound_utils"), require("HMfns.animate.color.color_const")
local I18N             = require("HMfns.utils.format.i18n_utils")
local Factory, Econ    = require("HMGplay.cards.factory"), require("HMGplay.economy")

local add_money        = Econ.add_money
local spawn_card       = Factory.spawn_card
local rand, i18n       = math.random, I18N.i18n
local play_clip        = SoundUtils.play_clip

local cp, cf, cg, cc, cg, cR, cSS = C.PURPLE, C.FILTER, C.GREEN, C.CLEAR, C.GREEN, C.RARITY, C.SECONDARY_SET
local _ta, _te, _tb, tT = "after", "ease", "before", "game_s"
local Y, N = true, false

return function (Card)
---------------------------------------------
--- Set edition
---------------------------------------------
--- Helper: check edition 
function Card:_check_ed()  if not self.edition then self.edition = {} end end

--- Helper: jitter edition
function Card:_jitter_ed(gm)
    self:jitter_me(1, 0.5);      local ed = self.edition 
    if ed.foil  then return play_clip(gm, "foil1", 1.2, 0.4) end
    if ed.glow  then return play_clip(gm, "foil1", 2, 0.4) end
    if ed.test  then return play_clip(gm, "foil1", 3, 0.4) end
    return Y
end

--________________________________
--- Main 
--________________________________
function Card:set_edition(edition, immediate, silent)
    self.edition = nil
    if not edition then return end

    local gm, zone = self.gm, self.zone;             local _PC, F = gm.CMod, gm.Fs

    if edition.foil   then self:_check_ed(); local ed = self.edition; ed.foil, ed.type = Y, "foil" end
    if edition.glow   then self:_check_ed(); local ed = self.edition; ed.glow, ed.type = Y, "glow" end
    if edition.test   then self:_check_ed(); local ed = self.edition; ed.test, ed.type = Y, "test" end

    local ed = self.edition

    if ed and not silent then
        local EM, Ctrl = gm.E_MANAGER, gm.CTRL;                     Ctrl.locks.edition = Y
        local _d, _b = not immediate and 0.2 or 0, not immediate
        EM:enqueue_event({ trigger = _ta, delay = _d, blockable = _b, func = function() return self:_jitter_ed(gm) end })
        EM:enqueue_event({ trigger = _ta, delay = 0.1, func = function() Ctrl.locks.edition = N; return Y end })
    end
    self:set_cost()
end

---------------------------------------------------
--- Set seal 
---------------------------------------------------
function Card:set_seal(_seal, silent, immediate)
    self.seal = nil
    if not _seal then return self:_handle_gold_card() end
    
    self.seal = _seal
    if silent then return self:_handle_gold_card() end

    local gm = self.gm;             local EM, Ctrl = gm.E_MANAGER, gm.CTRL
    Ctrl.locks.seal = Y
    if immediate then 
        self:jitter_me(0.3, 0.3);   play_clip(gm, "gold_seal", 1.2, 0.4)
        Ctrl.locks.seal = N;        return self:_handle_gold_card()
    end
    EM:enqueue_event({ trigger = _ta, delay = 0.3,  func = function() self:jitter_me(0.3, 0.3); return play_clip(gm, "gold_seal", 1.2, 0.4) end })
    EM:enqueue_event({ trigger = _ta, delay = 0.15, func = function() Ctrl.locks.seal = N; return true end })
    return self:_handle_gold_card()
end

-----------------------------------------------
--- Set debuff
-----------------------------------------------
function Card:set_debuff(should_debuff)
    local ab, gm = self.ability, self.gm
    if ab.perishable and ab.perish_tally <= 0 then 
        if self.debuff then return end
        self.debuff = Y;        if self.zone == gm.jokers then self:remove_from_deck(Y) end
        return
    end
    if should_debuff == self.debuff then return end 
    if self.zone == gm.jokers then if should_debuff then self:remove_from_deck(Y) else self:add_to_deck(Y) end end
    self.debuff = should_debuff
end

--------------------------------------------------
--- Start materialize 
--------------------------------------------------
--- fx_mask color 
local function _fetch_fx_mask_color(gm, set, center, color) if color then return color end; return { cg } end

--- Helper: play materialize clips
function Card:_play_materialize_clips(gm)
    local _lm, _T = gm.last_materialized, gm._T;        local now = _T.real_s
    if not _lm then return end 
    if now >= _lm or now <= _lm + 0.01 then return end
    gm.last_materialized = now
    gm.E_MANAGER:enqueue_event({ blockable = N, func = (function() play_clip(gm, "whoosh1", rand()*0.1 + 0.6, 0.3); return play_clip(gm, "crumple"..rand(1, 5), rand()*0.2 + 1.2, 0.8) end) })
end

--________________________________
--- Main 
--________________________________
function Card:start_materialize(fx_mask_colors, silent, timefac)
    local gm, st, fx_mask_time = self.gm, self.states, 0.6*(timefac or 1)
    st.visible, st.hover.can    = Y, N;                                     self.fx_mask = 1
    local ab, cfg, ch = self.ability, self.config, self.children;           local EM = gm.E_MANAGER
    self.fx_mask_colors = _fetch_fx_mask_color(gm, ab.set, cfg.template, fx_mask_colors)
    
    self:jitter_me();                              local _t, _lf, _c = 0.025*fx_mask_time, 0.7*fx_mask_time, self.fx_mask_colors
    ch.particles = ParticleEmitter(gm, 0, 0, 0, 0, { timer_type = tT, timer = _t, scale = 0.25, speed = 3, lifespan = _lf, attach = self, colors = _c, fill = Y })
    if not silent then self:_play_materialize_clips(gm) end

    EM:enqueue_event({ trigger = _ta, blockable = N, delay =  0.5*fx_mask_time, func = (function() if ch.particles then ch.particles.max = 0 end; return Y end) })
    EM:enqueue_event({ trigger = _te, blockable = N, ref_table = self, ref_value = "fx_mask", ease_to = 0, delay = fx_mask_time, func = (function(t) return t end) })
    EM:enqueue_event({ trigger = _ta, blockable = N, delay = fx_mask_time, func = (function() st.hover.can = Y; if ch.particles then ch.particles:remove(); ch.particles = nil end; return Y end) })
end

-----------------------------------------
--- calculate perishable
-----------------------------------------
function Card:calculate_perishable()
    local gm, ab = self.gm, self.ability
    if not ab.perishable or ab.perish_tally <= 0 then return end 
    if ab.perish_tally == 1 then
        ab.perish_tally = 0;                local _str = { message = i18n(gm, "k_disabled_ex"), color = cf, delay = 0.45 }
        show_card_status(gm, self, "extra", nil, nil, nil, _str)
        self:set_debuff();                  return 
    end

    ab.perish_tally = ab.perish_tally - 1;  local _str = { message = i18n(gm, { type = "variable", key = "a_remaining", vars = { ab.perish_tally }}), color = cf, delay = 0.45 }
    show_card_status(gm, self, "extra", nil, nil, nil, _str)
end

-----------------------------------------
--- calculate rental
-----------------------------------------
function Card:calculate_rental()
    local gm, ab = self.gm, self.ability;       if not ab.rental then return end
    local rate = gm.GAME.rental_rate
    add_money(gm, -rate)
    show_card_status(gm, self, "dollars", -rate)
end

end
