local SND, C  = require("HMfns.utils.sound_utils"), require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local play_clip       = SND.play_clip
local randomize_alpha = CUtils.randomize_alpha
local pick_fx_color   = CUtils.pick_fx_color
local rand            = math.random

local CFX          = C.FX_MASK
local cbd, cbh     = CFX.FX_DARK, CFX.FX_HOT
local _ta, _te, tT, tR = "after", "ease", "game_s", "real_s"
local Y, N = true, false

return function (Card)
---------------------------------------
--- shatter 
---------------------------------------
function Card:shatter()
    local gm, fx_mask_time = self.gm, 0.7
    self.shattered, self.fx_mask, self.fx_mask_colors = Y, 0, { { 1, 1, 1, 0.8} }

    self:jitter_me();                  local _t, _ls, _c = 0.007*fx_mask_time, 0.5*fx_mask_time, self.fx_mask_colors
    local childParts = ParticleEmitter(gm, 0, 0, 0, 0, { timer_type = tT, timer = _t, scale = 0.3, speed = 4, lifespan = _ls, attach = self, colors = _c, fill = Y })
    
    local EM, _d = gm.E_MANAGER, 0.15*fx_mask_time
    EM:enqueue_event({ trigger = _ta, blockable = N, delay = _ls, func = function() childParts:fade(_d); return Y end })
    EM:enqueue_event({ blockable = N, func = function() play_clip(gm, "glass"..rand(1, 6), rand()*0.2 + 0.9, 0.5); return play_clip(gm, "generic1", rand()*0.2 + 0.9, 0.5) end })
    EM:enqueue_event({ trigger = _te, blockable = N, ref_table = self, ref_value = "fx_mask", ease_to = 1, delay = _ls, func = (function(t) return t end) })
    EM:enqueue_event({ trigger = _ta, blockable = N, delay = 0.55*fx_mask_time, func = (function() self:remove(); return Y end) })
end

---------------------------------------
--- start fx_mask 
---------------------------------------
function Card:start_fx_mask(fx_mask_colors, silent, fx_mask_time, no_jitter)
    local gm,     fx_mask_time         = self.gm, (fx_mask_time or 1)
    self.fx_mask, self.fx_mask_colors  = 0, fx_mask_colors or { cbd, pick_fx_color() or cbh }
    self.fx_mask_colors[1]             = randomize_alpha(self.fx_mask_colors[1], 0.2)

    if not no_jitter then self:jitter_me() end
    
    local EM = gm.E_MANAGER
    EM:enqueue_event({ trigger = _te, blockable = N, timer = tR, ref_table = self, ref_value = "fx_mask", ease_to = 1, delay = fx_mask_time, func = (function(t) return t end) })
    EM:enqueue_event({ trigger = _ta, blockable = N, timer = tR, delay = fx_mask_time, func = (function() self:remove(); return Y end) })
end

end
