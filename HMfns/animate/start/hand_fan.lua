local DD, SND    = require("HMGplay.cards.draw_deal"), require("HMfns.utils.sound_utils")
local TabUtils   = require("HMfns.utils.table_utils")
local IntroTime  = require("HMfns.animate.start.intro_timeline")

local rand       = math.random
local draw2hand  = DD.draw_deck2hand 
local swap_at    = TabUtils.swap_at
local play_clip  = SND.play_clip

local Y, N = true, false
 
local M = {}

-------------------------------------
--- animate_hand_fan_out
-------------------------------------
function M.animate_hand_fan_out(gm)
    local EM,          hand,   deck    = gm.E_MANAGER, gm.hand,   gm.deck
    local hand_cfg,    room,   ctrl    = hand.config,  gm._room,  gm.CTRL
    local room_center, room_T, hand_T  = room.center,  room.T,    hand.T
    
    local timeline = IntroTime.hand
    local function hand_delay(at) return math.max(0, at - timeline.field_spawn) end
    local draw_delay_max, draw_delay_bias = timeline.delay_max, timeline.delay_bias
    draw_delay_max = (0.03*hand_cfg.card_limit)^(2) * draw_delay_max  -- quadratic fn of hand_sz
    local draw_group_gap = timeline.draw_group_gap or (draw_delay_max*rand() + draw_delay_bias)
    local draw_start_delay = timeline.draw_start_delay or 0.3

    --- Helpers: enqueue_ease | enqueue_after
    local function enqueue_ease(delay, ease, ref_table, ref_value, ease_to) EM:enqueue_event({ trigger = "ease", delay = delay, ease = ease, blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to }) end
    local function enqueue_after(delay, func)  EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, func = func }); return Y end
    ctrl.locks.hand_anim = Y
    hand_cfg.live_layout = Y
    local settle_pad = 0.08*rand() + 0.01

    enqueue_after(timeline.field_spawn, function ()
        enqueue_after(0,                       function() draw2hand(gm, N, Y, draw_group_gap, Y, draw_start_delay); return Y end)
        enqueue_after(hand_delay(timeline.clear_jitter),   function() hand:clear_fan_grab_jitter(); hand_cfg.fan_grab_jitter_deg = 0; hand_cfg.fan_grab_pad = 0; return Y end)
        enqueue_after(hand_delay(timeline.restore_jitter), function() hand_cfg.fan_grab_jitter_deg = 0.11; hand_cfg.fan_grab_pad = settle_pad; return Y end)

        enqueue_after(hand_delay(timeline.open_fan),       function() enqueue_ease(0.8, "sine", hand_cfg, "palm_offset", 40); enqueue_ease(0.8, "sine", hand_cfg, "step_deg", (#hand.cards < 15) and 2 or 1); return Y end)
        enqueue_after(hand_delay(timeline.unlock),         function() ctrl.locks.hand_anim = N; return Y end)
        enqueue_after(hand_delay(timeline.drag_sort),      function() hand_cfg.enable_drag_sort, hand_cfg.live_layout = Y, N; hand:mark_card_layout_dirty(); return Y end)
        return Y
    end)

end

return M
