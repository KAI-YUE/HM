local SoundUtils      = require("HMfns.utils.sound_utils")
local TabUtils        = require("HMfns.utils.table_utils")
local Rsuits          = require("HMGplay.cards.card_data.suits")
local Dialogue        = require("HMui.chara.dialogue")
local SkyPrep         = require("HMGplay.run_flow.prep.sky")
local FieldCardDebug  = require("HMEng.controller.debug.field_card")
local BattleDebug     = require("HMEng.controller.debug.battle")
local ModeSwitch      = require("HMEng.controller.debug.mode_switch")

local random_pick = TabUtils.random_pick
local play_clip   = SoundUtils.play_clip

local Y, N = true, false
local PAWN_ARROW_KEYS = { left = Y, up = Y, down = Y, right = Y }

return function (Controller)
------------------------------------------------------
--- For debug purpose 
------------------------------------------------------
--- Helper: card action 
function Controller:_card_action(key)
    local _card = self.hovering.target
    if key == "q" then
        local _e       = _card.edition 
        local _f, _g   = not _e, _e and _e.test
        local _edition = { test = _f, foil = _g  }
        _card:set_edition(_edition, Y, N)
        return
    end
    if key == "d" then _card:start_fx_mask() end
    if key == "+" then play_clip(G, "foil1", 1.2, 0.4); _card:mod_rank(1) end 
    if key == "-" then play_clip(G, "foil1", 1., 0.4); _card:mod_suit(random_pick(Rsuits.abbrev)) end
end

--- Helper: chara action 
function Controller:_chara_action(key)
    local _chara = self.hovering.target
    if key == "d" then Dialogue.show_dialogue_box(_chara.gm, _chara) end
    if key == "e" then _chara:emit_talking("_0_voice/2") end
    if key == "s" then _chara:interrupt_talking() end
    if key == "-" then _chara:clear_expressions() end 
end

--- Helper: chara action 
function Controller:_pawn_action(key)
    local _pawn = self.hovering.target
    if key == "left"  then _pawn:move_left() end
    if key == "up"    then _pawn:move_up() end
    if key == "down"  then _pawn:move_down() end
    if key == "right" then _pawn:move_right() end
end

--- Helper: debug page tunnel probe
function Controller:_debug_page_tunnel_blank(key) end

--- Helper: debug sky decorator
function Controller:_debug_sky_decorator(key)
    if key ~= "9" then return end
    SkyPrep.debug_spawn_bird(self.gm or G)
    return Y
end

------------------------------------------------------
--- Debug title page helpers
------------------------------------------------------
--- Helper: debug begin new run without page transition
function Controller:_debug_begin_new_run(key)
    if key ~= "s" then return end
    local gm = self.gm or G
    gm.SET.current_setup = "New Run"
    gm.Fs.begin_new_run(gm)
    return Y
end

--- Helper: debug title page back to preparation
function Controller:_debug_title_page_back_to_preparation(key)
    if key ~= "b" then return end
    local gm = self.gm or G
    if not (gm and gm.stages and gm.g_stage == gm.stages.title_page) then return end
    if not (self.UI and self.UI.title_page_panel) or self.UI.title_page_press_any then return end
    self:emit_intent("title_page_back_to_preparation")
    return Y
end

------------------------------------------------------
--- Debug HUD helpers
------------------------------------------------------
--- Helper: debug HUD action
function Controller:_debug_hud_action(key)
    local gm = self.gm or G
    if not (gm and gm.debug_tools) then return end
    if     key == "1" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "hp", delta = -10 } }); return Y
    elseif key == "2" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "hp", delta =  10 } }); return Y
    elseif key == "3" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "full", delta = -10 } }); return Y
    elseif key == "4" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "full", delta =  10 } }); return Y
    elseif key == "5" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "money", delta = -1 } }); return Y
    elseif key == "6" then self:emit_intent({ type = "debug_hud_mod", payload = { stat = "money", delta =  1 } }); return Y
    elseif key == "7" then self:emit_intent("debug_hud_toggle_foe"); return Y end
end

--_________________________________________________
--- Main: _debug panel
--_________________________________________________
function Controller:_debug_panel(key)
    if ModeSwitch.handle(self, key) then return end
    if self.debug_gamepad_mode then return end
    if PAWN_ARROW_KEYS[key] then
        local ht, Pawn = self.hovering.target, require("HMEng.entities.pawn")
        if ht and ht:is(Pawn) then self:_pawn_action(key); return end
    end
    if self:_debug_hud_action(key) then return end
    if self:_debug_begin_new_run(key) then return end
    if BattleDebug.handle(self, key) then return end
    if self:_debug_title_page_back_to_preparation(key) then return end
    if FieldCardDebug.handle(self, key) then return end

    local ht, Card     = self.hovering.target, require("HMEng.entities.card")
    local Chara, Pawn  = require("HMEng.chara"), require("HMEng.entities.pawn")

    if     ht and ht:is(Card)  then  self:_card_action(key) -- ad-hoc actors for fine-tuning
    elseif ht and ht:is(Chara) then  self:_chara_action(key) 
    elseif ht and ht:is(Pawn)  then  self:_pawn_action(key) end 
    
    if     key == "tab"   then self:emit_intent("toggle_debug")
    elseif key == "h"     then self:emit_intent("revert_toggle")
    elseif key == "l"     then self:emit_intent("load_data")
    elseif key == "8"     then love.mouse.setVisible(not love.mouse.isVisible()) end
    if key == "v"         then self:emit_intent("profile_game") end
    if key == "p"         then self:emit_intent("revert_perf")  end
    if self:_debug_sky_decorator(key) then return end
    if self:_debug_page_tunnel_blank(key) then return end
end

end
