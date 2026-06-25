local M = {}

----------------------------------------
--- Timeline for field spawn
----------------------------------------
M.field = {
    cards_start    = 0.12,   cards_step   = 0.2,  reveal_t     = 2.4,   settle_start = 1,
    row_delay_comp = 0.06,   pawn_reveal  = 1.2,  cloud_reveal = 3.2,
    suit_shader_start = 8,

    camera_intro_zoom  = 1.6,    camera_target_zoom = 1.6,
    camera_zoom_time   = 3,      camera_zoom_speed  = .6,
}

----------------------------------------
--- Timeline for hand dealing
----------------------------------------
M.hand = {
    field_spawn     = 1.,   clear_jitter    = 1.6, 
    restore_jitter  = 1.61,
    open_fan       = 1.8,    
     
    drag_sort   = 3.4,      unlock         = 0.01
}

----------------------------------------
--- Timeline for deck spawn
----------------------------------------
M.deck = { field_spawn    = 2,   fade_in = 2,   sand_erase = 9.6  }

local T_hand, deck_spawn = M.hand, 0.58*M.deck.field_spawn  --- offsets 
for k, v in pairs(M.hand) do T_hand[k] = v + deck_spawn end 

M.hand.delay_max, M.hand.delay_bias = 1, 0.5

----------------------------------------
--- Timeline for field spawn
----------------------------------------
M.bg_decor = {
    field_spawn = 0.55,   fade_in = 1.55,
}

----------------------------------------
--- Timeline for cloud fx
----------------------------------------
M.cloud = {
    field_spawn = 10.55,    
    min_dur     = 16,    max_dur = 20,   radius = 2,   
    fade_dur    = 4,     fade_in_dur = 4
}

return M
