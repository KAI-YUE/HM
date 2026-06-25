local TextFX = require("HMEng.ui_actors.card_textfx")
local ParticleEmitter = require("HMEng.actors.particle_emitter")
local C = require("HMfns.animate.color.color_const")

local ck, co, crd = C.BLACK, C.ORANGE, C.RED 
local cc, cb, cw  = C.CLEAR, C.BLUE,   C.WHITE
local cbg         = ck
local ta, tb, tR  = "after", "before", "real_s"
local push = table.insert
local Y, N = true, false

local M = {}

-----------------------------------------------------------
--- Start wipe effect: sEmit the screenwipe effect
-----------------------------------------------------------
-- Helper: build the screenwipe card
local function _screenwipe_card(gm)
    local Fs, Card    = gm.Fs, require("HMEng.entities.card")
    local w, h, pc    = gm.card_w, gm.card_h, gm.P_CARDS
    local base, _pick = gm.CMod.c_base,  Fs.random_pick
    gm.screenwipecard = Card(gm, 1, 1, w, h, _pick(pc), base)
    -- Build the card
    local card = gm.screenwipecard;         card.sprite_facing, card.facing = "back", "back"
    card.states.hover.can = N;              card:jitter_me(0.5, 1)
end

-- Helper: build the message
local function _message(gm, message)
    local message_t = {}
    for k, v in ipairs(message) do
        local t, str, c, s   = _row(), v or "", (k ~= 1)
        if math.min(cbg[1], cbg[2]) > 0.5 then c = ck end
        local txt = TextFX(gm, { string = str, colors = c, shadow = Y, silent = s, float = Y, scale = 1.3, pop_in = 0, pop_in_rate = 2, rotate = 1 })
        t.nodes = _obj(txt);                    push(message_t, t)
    end
end

-- Helper: pulse the text 
local function _pulse_txt(sw)
    local item = sw:get_UI_by_ID("text").children
    for _, v in ipairs(item) do v.children[1].config.object:pulse() end
end

-- Helper: flip the wipe_screen flip card
local function _flip_card(gm)
    if no_card then return true end
    gm.screenwipecard:flip()
    gm.Fs.play_clip(gm, "cardFan2")
    return Y
end

-- main: screenwipe effect
function M.start_wipe_fx(gm, message, no_card, timefac, alt_color)
    local EM, Ctrl, RA = gm.E_MANAGER, gm.CTRL, gm._room_r
    local _card, t     = not no_card, _root({ minw = 0, minh = 0, padding = 0.15, r = 0.1, color = cc })
    local tf, colors   = timefac or 1, { black = cb, white = cw }
    
    if gm.screenwipe then return end
    Ctrl.locks.trans, gm._stage_suspend = Y, Y

    if _card    then _screenwipe_card(gm)  end
    if message  then _message(gm, message) end

    local tn, offset = t.nodes, { x = 0, y = 0 };                    push(tn, _row())     -- root layer 
    local tnn, scard = tn[1].nodes, gm.screenwipecard
    if message then local l1 = _row({ id = "text", padding = 0.7 }); push(tnn, l1) end
    if _card   then local l2 = _obj(scard, { role_type = "Major" }); push(tnn, l2) end

    gm.screenwipe = UIPanel(gm, { definition = t, config = { align="cm", offset = offset, major = RA } })
    local sw, c   = gm.screenwipe, alt_color or cbg
    sw.colors     = colors
    local pcfg    = { timer = 0, max = 1, scale = 40, speed = 0, lifespan = 1.7*tf, attach = sw, colors = {c} }
    local _pe     = ParticleEmitter(gm, 0, 0, 0, 0, pcfg)

    sw.children.particles     = _pe
    gm._stage_suspend         = nil
    sw.alignment.offset.y     = 0
    if message then _pulse_txt(sw) end
    EM:enqueue_event({ trigger = tb, delay = 0.7, no_delete = Y, blockable = N, func = function() return _flip_card(gm) end })
    EM:enqueue_event({ trigger = ta, delay = 1, no_delete = Y, blockable = N, func = function() Ctrl.locks.trans = false; return true; end })
end

-----------------------------------------------------------
--- Finish Screen Wipe Effect: Exit the screenwipe effect
-----------------------------------------------------------
--- Helper: _cut_out setup
local function _cut_out(gm)
    gm.Fs.sleep(gm, 0.5)
    gm.screenwipe.children.particles.max = 0
    return true
end

--- Helper: apply fx_mask to the screenwipe card
local function _fx_mask_card(gm) if gm.screenwipecard then gm.screenwipecard:start_fx_mask({ ck, co, C.GOLD, crd }) end; return Y end

--- Helper: remove the screenwipe
local function _remove_sw(gm)
    local sw = gm.screenwipe
    sw.children.particles:remove();             sw:remove()
    sw.children.particles = nil;                gm.screenwipe = nil
    gm.screenwipecard = nil;                    return Y
end

-- Helper: create the "After" event configuration
local function _after_cfg(gm, delay, fn) return { trigger = ta, delay = delay, no_delete = Y, blocking = N, timer = tR, func = function() return fn(gm) end } end

--___________________________________________________
--- Main: finish the wipe effect
--___________________________________________________
function M.finish_wipe_fx(gm)
    local EM = gm.E_MANAGER
    EM:enqueue_event({ no_delete = true, func = function() return _cut_out(gm) end })
    EM:enqueue_event(_after_cfg(gm, 0.6, _fx_mask_card))
    EM:enqueue_event(_after_cfg(gm, 1.1, _remove_sw))
end

return M
