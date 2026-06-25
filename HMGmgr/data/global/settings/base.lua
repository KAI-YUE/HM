local Y, N = true, false

return function (self)
-----------------------------
--- Settings
----------------------------------
    local selfF = self.F

    self.SET = {     sf = 1,     achms   = {}, col_blind = N,    language = "auto",   scr_jitter = Y,  run_stake_stickers = N,  rumble = selfF.rumble,
        user_name = "player",   slot_idx = 1,
        play_button_pos = 2,     g_speed = 4,  pause     = N,   C_static  = N,        fps_cap = "auto",
        save_data  = { slot_count = 9, root = "saves", shared = "shared.hm" }, screen_res = "auto",
        s_win      = { screenmode = "auto", vsync = 1, selected_display = 1, display_names = { "[NONE]" },
        s_disp     = { { name = "[NONE]", screen_res = { w = 1000, h = 650 } } } },
        s_graphics = { s_texture = 1, shadows = "On", bloom = 1, graphics_quality = "auto" } }

    self.s_metrics = { cards = { used = {}, bought = {}, appeared = {} }, decks = { chosen = {}, win = {}, lose = {} }, bosses = { faced = {}, win = {}, lose = {} } }
end
