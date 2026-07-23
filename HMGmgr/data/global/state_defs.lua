local M = {}

M.g_states = {
    idle          = 0,
    select_hand   = 1,
    hand_played   = 2,
    draw_hand     = 3,
    draw_unsorted = 4,
    game_over     = 5,
    shop          = 6,
    viewing_deck  = 7,
    round_eval    = 8,
    menu          = 11,
    new_round     = 12,
    splash        = 13,
}

M.stages = {
    title_page = 1,
    run_game   = 2,
    run_tut    = 3,
}

function M.new_stage_objs() return { {}, {}, {} } end
function M.new_profiles() return { {}, {}, {} } end

return M
