local Y, N  = true, false
local M = {}

-----------------------------
--- victory
----------------------------------
--- Helper: set win
local function set_win(gm)
    local Fs, SET, I, EM    = gm.Fs, gm.SET, gm.R, gm.E_MANAGER
    local IC, win_layout    = I.CARD, Fs.win_layout
    local play_clip, _menu  = Fs.play_clip, Fs.open_menu

    for _, v in pairs(IC) do v.sticker_run = nil end
    play_clip(gm, "win");                   SET.pause = Y
    -- _menu(gm, { definition = win_layout(gm), config = { no_esc = Y } })
    return true
end

--- Helper: normal win
local function _normal_win(gm)
    local Fs, P, SET        = gm.Fs, gm.g_profile, gm.SET
    local _hscore, _unlock  = Fs.update_high_score, Fs.handle_unlock_request
    local Sp, _career       = SET.profile, Fs.update_career

    local streak = P[Sp].high_scores.current_streak.amt
    Fs.inc_joker_win(gm);           Fs.inc_deck_win(gm)
    local streaks = { "win_streak", "current_streak" }
    local wins    = { "win_no_hand", "win_no", "win_custom", "win_deck", "win_stake", "win" }
    for _, s in ipairs(streaks) do _hscore(gm, s, streak + 1) end
    for _, s in ipairs(wins)    do _unlock(gm, { type = s }) end
    _career(gm, "c_wins", 1)
end

--- Helper: challenge win
local function _challenge_win(gm)
    local Fs, P, SET, game  = gm.Fs, gm.g_profile, gm.SET, gm.GAME
    local Sp, _ch, _unlock  = SET.profile, game.challenge, Fs.handle_unlock_request
    local _ch_unlock        = Fs.inc_challenge_unlock
    P[Sp].challenge_progress.completed[_ch] = Y;          _ch_unlock(gm)
    _unlock(gm, { type = "win_challenge" })
    gm:save_settings()
end

function M.victory(gm)
    local Fs, game, P, SET    = gm.Fs, gm.GAME,   gm.g_profile, gm.SET
    local _ch, Sp, EM, stake  = game.challenge, SET.profile, gm.E_MANAGER, game.stake or 1
    local  _normal, set_pro   = not game.seeded and not _ch, Fs.set_progress   

    if _normal then _normal_win(gm) elseif _ch then _challenge_win(gm) end
    set_pro(gm)
    EM:enqueue_event({ func = function () return set_win(gm) end })
    if _normal then P[Sp].stake = math.max(P[Sp].stake or 1, stake + 1) end
    gm:save_progress()
    gm.f_handler.force = Y
end

return M
