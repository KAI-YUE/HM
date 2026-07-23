local M = {}

-------------------------------------------------
--- Helper: Add money
-------------------------------------------------
function M._add_money(gm, delta)
    local C, HUD, Fs  = gm.C, gm.HUD, gm.Fs
    local game, delta = gm.GAME, delta or 0
    local i18n, _career, _unlock  = Fs.i18n, Fs.update_career, Fs.handle_unlock_request
    local _score, play_clip       = Fs.update_high_score, Fs.play_clip

    local dollar_UI = HUD:get_UI_by_ID("dollar_text_UI")
    local text, col = "+"..i18n(gm, "$"), C.GOLD

    if delta < 0 then text, col = "-"..i18n(gm, "$"), C.RED
    else _career(gm, "c_dollars_earned", delta) end

    game.dollars = game.dollars + delta
    _score(gm, "most_money", game.dollars)
    _unlock(gm, {type = "money"})

    dollar_UI.config.object:update()
    gm.HUD:recalculate()

    local txt, cover = text..tostring(math.abs(delta)), dollar_UI.parent
    Fs.toast_attention(gm, { text = txt,  scale = 0.8, hold = 0.7, cover = cover, cover_color = col, align = "cm" })
    play_clip(gm, "coin1")
    return true
end

function M.add_money(gm, delta, instant)
    if instant then M._add_money(gm, delta); return end 
    gm.E_MANAGER:enqueue_event({ func = function() return M._add_money(gm, delta) end })
end

return M