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
local max, min    = math.max, math.min

local Y, N = true, false
local PAWN_ARROW_KEYS = { left = Y, up = Y, down = Y, right = Y }
local FIELD_CELL_NUDGE = { i = { r = -1, c = 0 }, k = { r = 1, c = 0 }, j = { r = 0, c = -1 }, l = { r = 0, c = 1 } }
local FIELD_FOCUS_NUDGE = { i = { x = 0, y = -1 }, k = { x = 0, y = 1 }, j = { x = -1, y = 0 }, l = { x = 1, y = 0 } }

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

------------------------------------------------------
--- Debug field projection helpers
------------------------------------------------------
--- Helper: debug toggle field focus projection
function Controller:_debug_toggle_field_focus_projection(key)
    if key ~= "q" then return end
    local gm = self.gm or G
    local zone = gm and gm.gridzone;                         if not (zone and zone.projector and zone.align_cards) then return end
    local cfg = zone._focus_projection_cfg and zone:_focus_projection_cfg(); if not cfg then return end

    local committed = N
    if zone.focus_projection_active then
        zone.focus_projection_active, zone.focus_projection_pending = N, N
        zone.focus_projection_key, zone.focus_projection_weight_last = nil, nil
    else
        local pawn, cell = gm.field_pawn, nil
        cell = pawn and pawn.zone == zone and pawn.cell or zone.field_view_anchor_cell
        if cell and cell.row and cell.col then zone.field_view_anchor_cell = { row = cell.row, col = cell.col } end
        zone.focus_projection_active, zone.focus_projection_pending = Y, Y
        committed = zone.commit_field_view_projection and zone:commit_field_view_projection()
    end

    if not committed then zone:align_cards({ dt = 0 }) end
    zone:align_pawns()
    zone.card_layout_dirty = N
    return Y
end

--- Helper: debug field focus point
local function _debug_field_focus_point(gm, zone, cam)
    if zone.debug_focus_point then return zone.debug_focus_point end
    local fp = cam and cam.focus_point
    if fp then zone.debug_focus_point = { x = fp.x, y = fp.y }; return zone.debug_focus_point end
    local cell = zone.field_view_anchor_cell or (gm.field_pawn and gm.field_pawn.cell)
    local p = cell and zone.field_view_cell_point and zone:field_view_cell_point(cell.row, cell.col)
    if p then zone.debug_focus_point = { x = p.x, y = p.y }; return zone.debug_focus_point end
end

--- Helper: debug nudge field anchor cell
function Controller:_debug_nudge_field_anchor_cell(key)
    local dir = FIELD_CELL_NUDGE[key];                       if not dir then return end
    if self.held_keys and (self.held_keys.lshift or self.held_keys.rshift) then return end
    local gm = self.gm or G;                                  if not (gm and gm.debug and gm.debug.on) then return end
    local zone = gm.gridzone;                                 if not (zone and zone.set_field_view_anchor) then return end
    local cfg = zone._focus_projection_cfg and zone:_focus_projection_cfg(); if not cfg or cfg.enabled == N then return end
    local cell = zone.field_view_anchor_cell or (gm.field_pawn and gm.field_pawn.cell); if not (cell and cell.row and cell.col) then return end

    local row = min(max(1, cell.row + dir.r), zone.n_rows or cell.row)
    local col = min(max(1, cell.col + dir.c), zone.n_cols or cell.col)
    local p = zone:set_field_view_anchor(row, col);           if not p then return end
    if zone.focus_projection_active then if zone.commit_field_view_projection then zone:commit_field_view_projection() else zone:align_cards({ dt = 0 }) end; zone:align_pawns(); p = zone:field_view_cell_point(row, col) or p end
    zone.debug_focus_point = { x = p.x, y = p.y }
    return Y
end

--- Helper: debug nudge field focus point
function Controller:_debug_nudge_field_focus_point(key)
    local dir = FIELD_FOCUS_NUDGE[key]
    if not dir and key ~= "u" and key ~= "o" then return end
    local gm = self.gm or G;                                  if not (gm and gm.debug and gm.debug.on) then return end
    local zone, cam = gm.gridzone, gm.camera;                  if not (zone and cam and cam.set_focus_point) then return end
    local cfg = zone._focus_projection_cfg and zone:_focus_projection_cfg() or {}
    if cfg.enabled == N then return end
    local step = zone.debug_focus_step or cfg.debug_focus_step or 1

    if key == "u" or key == "o" then zone.debug_focus_step = (key == "u") and max(0.05, 0.5*step) or 2*step; return Y end
    if not (self.held_keys and (self.held_keys.lshift or self.held_keys.rshift)) then return end

    local p = _debug_field_focus_point(gm, zone, cam);         if not p then return end
    p.x, p.y = p.x + dir.x*step, p.y + dir.y*step
    zone.debug_focus_point = p
    cam:set_focus_point(p.x, p.y)
    return Y
end

--_________________________________________________
--- Main: _debug panel
--_________________________________________________
function Controller:_debug_panel(key)
    if ModeSwitch.handle(self, key) then return end
    if self.debug_gamepad_mode then return end
    if self:_debug_nudge_field_anchor_cell(key) then return end
    if self:_debug_nudge_field_focus_point(key) then return end
    if self:_debug_toggle_field_focus_projection(key) then return end
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
