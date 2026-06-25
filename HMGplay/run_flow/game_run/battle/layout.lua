local DeckPreviewZone = require("HMEng.entities.board.deckpreviewzone")
local HMPanel         = require("HMEng.ui_actors.hm_panel")
local Rewards         = require("HMGplay.run_flow.game_run.battle.rewards")
local Spritor         = require("HMEng.actors.spritor")
local TiledMap        = require("HMEng.entities.bg.tiledmap")
local BattleLog       = require("HMGplay.run_flow.game_run.battle.log")
local LogPanel        = require("HMGplay.run_flow.log_panel")
local C               = require("HMfns.animate.color.color_const")

local Y, N = true, false

local M = {}

-----------------------------
--- build_field
----------------------------------
--- Helper: detach from cardzone render
local function _detach_from_cardzone_render(gm, zone)
    local cardzones = gm.R and gm.R.CARDZONE
    if not cardzones then return end
    for idx = #cardzones, 1, -1 do
        if cardzones[idx] == zone then table.remove(cardzones, idx); break end
    end
end

--- Helper: attach under hand
local function _attach_under_hand(gm, battle, key, actor)
    if not (actor and battle.bg and battle.bg.children) then return actor end
    _detach_from_cardzone_render(gm, actor)
    battle.bg.children[key] = actor
    actor.parent = battle.bg
    return actor
end

--- Helper: room metrics
local function _room_metrics(gm)
    local T = gm._room and gm._room.T or {}
    return T.w or gm.rcfg.tile_w, T.h or gm.rcfg.tile_h
end

--- Helper: build background
local function _build_background(gm)
    local room_w, room_h = _room_metrics(gm)
    local tile           = 1.4
    local n_cols         = math.max(1, math.ceil(room_w/tile) + 2)
    local n_rows         = math.max(1, math.ceil(room_h/tile) + 2)
    local bg = TiledMap(gm, -tile, -tile, n_cols*tile, n_rows*tile, {
        type                      = "battle_bg",
        n_rows                    = n_rows,
        n_cols                    = n_cols,
        tile_w                    = tile,
        tile_h                    = tile,
        atlas_key                 = "grass",
        tile_shader               = "fblend",
        random_tiles              = N,
        tile_overdraw             = 0.02,
        tile_shader_uniforms_once = Y,
        tile_shader_opts          = { edge_pad = 2, send = { { name = "input_scale", val = 1 } } },
    })
    bg.draw_alpha = 0.82
    return bg
end

--- Helper: card quad
local function _card_quad(w, h) return { { x = 0, y = 0 }, { x = w, y = 0 }, { x = w, y = h }, { x = 0, y = h } } end

--- Helper: install vertical column layout
local function _install_vertical_column_layout(zone)
    zone.align_cards = function(self)
        local cards = self.cards
        if not cards or #cards == 0 then self.layout = nil; return end

        local cfg, T     = self.config, self.T
        local pad_x      = cfg.preview_pad_x or 0.08
        local pad_top    = cfg.preview_pad_top or 0.08
        local pad_bottom = cfg.preview_pad_bottom or 0.08
        local max_scale  = cfg.preview_max_scale or 0.82
        local slot_h     = math.max(0.01, (T.h - pad_top - pad_bottom)/cfg.card_limit)
        local scale      = math.min(max_scale, (T.w - 2*pad_x)/math.max(self.card_w, 0.01), slot_h/math.max(self.card_h, 0.01))
        local card_w, card_h = self.card_w*scale, self.card_h*scale

        self.layout = { cols = 1, rows = #cards, scale = scale, card_w = card_w, card_h = card_h }
        for idx, card in ipairs(cards) do
            local x = T.x + 0.5*(T.w - card_w)
            local y = T.y + pad_top + (idx - 1)*slot_h + 0.5*(slot_h - card_h)
            card.rank = idx
            card:hard_set_T(x, y, card_w, card_h)
            card:assign_field_quad(_card_quad(card_w, card_h))
        end
    end
end

--- Helper: new side zone
local function _new_side_zone(gm, battle, api, x, y, w, h, side, column)
    local zone = DeckPreviewZone(gm, x, y, w, h, {
        card_limit        = 4,
        highlighted_limit = 0,
        type              = "battle_" .. side,
        battle_side       = side,
        battle_column     = column,
        preview_pad_x     = 0.08,
        preview_pad_right = 0.08,
        preview_pad_top    = 0.08,
        preview_pad_bottom = 0.08,
        preview_overlap_x = 0.16,
        preview_overlap_y = 0.38,
        preview_max_scale = 0.82,
    })
    if side == "player" then
        zone.states.collide.can = Y
        zone.states.release_on.can = Y
        zone.release = function(_, card) return api.stage_card(battle, card, column) end
    end
    _install_vertical_column_layout(zone)
    return _attach_under_hand(gm, battle, "zone_" .. side .. "_" .. tostring(column), zone)
end

--- Helper: new reward
local function _new_reward(gm, battle, x, y, w, column)
    local atlas = gm.T_atlas and gm.T_atlas.icons
    if not atlas then return end

    local size   = math.min(0.82, 0.45*w)
    local data   = battle.reward_pool and battle.reward_pool[column] or {}
    local reward = Spritor(gm, x + 0.5*(w - size), y - 0.05, size, size, atlas, data.icon or "milk")
    reward.states.collide.can = N
    reward.states.hover.can   = N
    reward.states.click.can   = N
    reward.battle_reward_column = column
    if battle.bg and battle.bg.children then
        battle.bg.children["reward_" .. tostring(column)] = reward
        reward.parent = battle.bg
    end
    return reward
end

--- Helper: new reward score
local function _new_reward_score(gm, battle, x, y, w, column)
    local reward = battle.reward_pool and battle.reward_pool[column]
    local text = reward and reward.revealed and tostring(reward.score) or "?"
    return HMPanel(gm, {
        style = "paint_rect", T = { x = x + 0.5*w + 0.15, y = y + 0.54, w = 0.42, h = 0.30 },
        text = text, text_scale = 0.22, text_color = C.UI.TEXT_LIGHT, fill_color = { 0.02, 0.02, 0.02, 0.72 },
    })
end

--- Helper: pending zone
local function _pending_zone(gm, x, y, w)
    return DeckPreviewZone(gm, x, y, w, 1.45*gm.card_h, {
        card_limit        = 4,
        highlighted_limit = 0,
        type              = "battle_pending",
        preview_pad_x      = 0.10,
        preview_pad_right  = 0.10,
        preview_pad_top    = 0.08,
        preview_pad_bottom = 0.08,
        preview_overlap_x  = 0.10,
        preview_overlap_y  = 0,
        preview_max_scale  = 0.72,
    })
end

--- Helper: new FOE info zones
local function _new_foe_info_zones(gm, start_x, field_w, foe_y)
    local deck_w, hand_w = 1.25*gm.card_w, math.max(3.2*gm.card_w, 3.6)
    local y              = math.max(0.18, foe_y - 1.55*gm.card_h)
    return {
        deck = DeckPreviewZone(gm, start_x, y, deck_w, 1.35*gm.card_h, {
            card_limit         = 1, highlighted_limit = 0, type = "battle_foe_deck",
            preview_pad_x      = 0.06, preview_pad_right = 0.06, preview_pad_top = 0.06, preview_pad_bottom = 0.06,
            preview_max_scale = 0.62,
        }),
        hand = DeckPreviewZone(gm, start_x + deck_w + 0.28, y, hand_w, 1.35*gm.card_h, {
            card_limit        = 4, highlighted_limit = 0, type = "battle_foe_hand",
            preview_pad_x     = 0.06, preview_pad_right = 0.06, preview_pad_top = 0.06, preview_pad_bottom = 0.06,
            preview_overlap_x = 0.10, preview_overlap_y = 0, preview_max_scale = 0.62,
        }),
    }
end

--- Helper: attach FOE info zones
local function _attach_foe_info_zones(gm, battle)
    _attach_under_hand(gm, battle, "zone_foe_deck", battle.foe_deck_zone)
    _attach_under_hand(gm, battle, "zone_foe_hand", battle.foe_hand_zone)
end

--- Helper: make control
local function _make_control(gm, battle, args)
    local panel = HMPanel(gm, {
        style      = "paint_rect",
        T          = args.T,
        text       = args.text,
        text_scale = 0.38,
        text_color = C.UI.TEXT_LIGHT,
        fill_color = args.color,
        button     = Y,
        can_hover  = Y,
        can_click  = Y,
        hook_fn    = args.hook_fn,
    })
    local base_update = panel.update
    panel.update = function(self, dt)
        if base_update then base_update(self, dt) end
        if self.widget then
            self.widget.disable_button = not args.enabled(battle)
            if args.text_fn then self.widget.config.text = args.text_fn(battle) end
        end
    end
    panel:update(0)
    return panel
end

--- Helper: build controls
local function _build_controls(gm, battle, api, start_x, field_w, player_y, zone_h)
    battle.pending_zone = _pending_zone(gm, start_x, player_y + zone_h + 0.12, field_w - 4.8)
    _attach_under_hand(gm, battle, "zone_pending", battle.pending_zone)
    local x = start_x + field_w - 4.55
    local y = player_y + zone_h + 0.34
    battle.play_button = _make_control(gm, battle, {
        T       = { x = x, y = y, w = 2.15, h = 0.78 },
        text    = "Play",
        text_fn = function(b) return #b.placements > 0 and "Confirm" or "Play" end,
        color   = C.GREEN,
        enabled = function(b)
            if b.busy or b.turn ~= "player" then return N end
            if #b.pending_zone.cards > 0 then return N end
            return #b.placements > 0 or #(b.gm.hand.highlighted or {}) > 0
        end,
        hook_fn = function() api.play_or_confirm(battle); return Y end,
    })
    battle.undo_button = _make_control(gm, battle, {
        T       = { x = x + 2.35, y = y, w = 2.15, h = 0.78 },
        text    = "Undo",
        color   = C.RED,
        enabled = function(b) return not b.busy and b.turn == "player" and (#b.placements > 0 or #b.pending_zone.cards > 0) end,
        hook_fn = function() api.undo(battle); return Y end,
    })
    battle.log_button = _make_control(gm, battle, {
        T       = { x = x + 4.70, y = y, w = 1.60, h = 0.78 },
        text    = "Log",
        color   = C.BLUE,
        enabled = function() return Y end,
        hook_fn = function() BattleLog.toggle_panel(battle); return Y end,
    })
    battle.log_panel = LogPanel.create(gm, battle.log, {
        T          = { x = start_x + field_w + 0.42, y = math.max(0.25, player_y - 2.90), w = 3.90, h = 3.40 },
        text_scale = 0.25,
        text_color = C.UI.TEXT_LIGHT,
        fill_color = C.BLACK,
        visible    = battle.log_open,
    })
    battle.bonus_hint = _make_control(gm, battle, {
        T = { x = start_x + 0.5*field_w - 1.0, y = math.max(0.20, player_y - 1.04), w = 2.0, h = 0.50 },
        text = "Bonus", color = C.ORANGE, enabled = function() return N end,
        text_fn = function(b) return b.bonus_hint_text or "Bonus" end,
    })
    battle.bonus_hint.states.visible = N
end

function M.build_field(gm, battle, api)
    battle.bg = _build_background(gm)
    local room_w, room_h = _room_metrics(gm)
    local column_w, gap = math.max(2.15*gm.card_w, 2.45), 0.20
    local field_w       = battle.column_count*column_w + (battle.column_count - 1)*gap
    local start_x       = 0.5*(room_w - field_w) - 0.8
    local reward_y      = 0.5*room_h - 0.36
    local zone_h        = math.max(2.15*gm.card_h, 2.55)
    local foe_y         = reward_y - zone_h - 0.18
    local player_y      = reward_y + 0.90
    local foe_info      = _new_foe_info_zones(gm, start_x, field_w, foe_y)
    battle.foe_deck_zone, battle.foe_hand_zone = foe_info.deck, foe_info.hand
    _attach_foe_info_zones(gm, battle)

    for column = 1, battle.column_count do
        local x = start_x + (column - 1)*(column_w + gap)
        battle.columns[column] = {
            drop_T = { x = x, y = foe_y, w = column_w, h = (player_y + zone_h) - foe_y },
            reward = battle.reward_pool[column],
            player = { zone = _new_side_zone(gm, battle, api, x, player_y, column_w, zone_h, "player", column) },
            foe    = { zone = _new_side_zone(gm, battle, api, x, foe_y, column_w, zone_h, "foe", column) },
        }
        battle.columns[column].reward.actor = _new_reward(gm, battle, x, reward_y, column_w, column)
        battle.columns[column].reward.score_panel = _new_reward_score(gm, battle, x, reward_y, column_w, column)
    end
    Rewards.refresh_reveals(battle)
    _build_controls(gm, battle, api, start_x, field_w, player_y, zone_h)
end

return M
