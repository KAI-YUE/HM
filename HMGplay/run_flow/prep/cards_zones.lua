local CardZone  = require("HMEng.entities.board.cardzone")
local DeckZone  = require("HMEng.entities.board.deckzone")
local DeckData  = require("HMEng.entities.board.deckzone.data")
local HandZone  = require("HMEng.entities.board.handzone")
local DeckIntro = require("HMfns.animate.start.deck")
local HandFan   = require("HMfns.animate.start.hand_fan")

local rand = math.random

local Y, N = true, false

local M = {}

-----------------------------
--- init_cardzones
----------------------------------
--- Helper: load saved cardzones
local function load_saved_cardzones(gm, cardzones)
    if type(cardzones) ~= "table" then return N end
    local loaded = 0
    for key, zone_tab in pairs(cardzones) do
        local zone = gm[key]
        if zone and zone.load then zone:load(gm, zone_tab); loaded = loaded + 1 end
    end
    return loaded > 0
end

function M.init_cardzones(gm, opts)
    opts = opts or {}
    local gG, Fs, R, Ccfg = gm.GAME, gm.Fs, gm.R, gm.Ccfg

    gm.discard = DeckZone(gm, 0, 0, Ccfg.discard_W, Ccfg.discard_H, { card_limit = 500, type = "discard", shuffle_amt = 0.005*rand() + 0.001 })
    gm.deck    = DeckZone(gm, 0, 0, Ccfg.deck_W, Ccfg.deck_H, { card_limit = 50, type = "deck", shuffle_amt = 0.005*rand() + 0.001 })
    gm.hand    = HandZone(gm, 0, 0, Ccfg.hand_W, Ccfg.hand_H, { card_limit = gG.starting_params.hand_size, highlighted_limit = gm.run_loop and 1 or nil, type = "hand", palm_offset = 2, step_deg = 2.9, max_spread_deg = 30, fan_grab_jitter_deg = 0.12, fan_grab_pad = 0.05*rand() + 0.05 })
    gm.play    = CardZone(gm, 0, 0, Ccfg.play_W, Ccfg.play_H, { card_limit = 5, type = "play" })

    local deck_quad_coords    = DeckData:pick_projected_quad_candidate()
    local discard_quad_coords = DeckData:pick_projected_quad_candidate()
    gm.deck:wire_to_field(gm.gridzone, { quad_coords = deck_quad_coords })
    gm.discard:wire_to_field(gm.gridzone, { quad_coords = discard_quad_coords })

    gm.run_card_id = {}
    Fs.init_screen_pos(gm)  -- The actual pos is set here
    local restored = load_saved_cardzones(gm, opts.cardzones)
    if not restored then Fs.init_deck(gm) end

    for _, v in pairs(R.CARD)     do if v.playing_card then table.insert(gm.run_card_id, v) end end
    for _, v in pairs(R.CARDZONE) do v:align_cards(); v:hard_set_cards() end

    table.sort(gm.run_card_id, function(a, b) return a.playing_card > b.playing_card end)

    local _deck = gm.deck
    if not restored then _deck:shuffle() end

    _deck:hard_set_T()
    _deck:align_cards()
    _deck:hard_set_cards()

    if opts.silent_start then return end
    DeckIntro.animate_deck_fade_in(gm)
    HandFan.animate_hand_fan_out(gm)
end

return M
