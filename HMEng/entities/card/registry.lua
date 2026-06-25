local Actor       = require("HMEng.actors.actor")
local TableUtils  = require("HMfns.utils.table_utils")
local Rranks      = require("HMGplay.cards.card_data.hand_ranks")

local rand_pick     = TableUtils.random_pick
local destroy_tree  = TableUtils.destroy_tree
local rand, push    = math.random, table.insert

local Tst     = { "collide", "hover", "drag", "click", "dealing" }
local Tbypass = { "bypass_discovery_center", "bypass_discovery_ui", "bypass_lock" }
local Tm      = { "base_cost", "extra_cost", "cost", "sell_cost", "sell_cost_label" }
local Tatt    = { "edition", "zoom", "flipping", "zone", "highlighted", "debuff", "rank", "added_to_deck", "drag_mass", "drag_response", "drag_release_smooth_time", "drag_release_max_speed" }
local Tdv     = {  nil,         Y,    nil,        nil,      N,             N,       nil,     nil,           5,           18,              nil,                        70 }
local Y, N    = true, false

return function (Card)
-----------------------------------------------------------------------
--- init card attributes
-----------------------------------------------------------------------
--- Helper: format card 
local function _format_card(card)
    if not card then return end 
    card.rank = tostring(card.rank)
    if card.rank_label ~= nil then card.rank_label = tostring(card.rank_label) end
    if not card.value then card.value = Rranks.values[card.rank] end 
end

--- Helper: init children
function Card:_init_children(gm)
    local ch = self.children;                     ch.shadow = Actor(gm)
    if ch.front then ch.front.VT.w = 0 end
    
    local chb, chc, chf = ch.back, ch.template, ch.front
    chb.VT.w, chc.VT.w  = 0, 0

    if ch.front then chf.parent, chf.layered_parallax = self, nil end
    chb.parent, chc.parent = self, self 
    chb.layered_parallax, chc.layered_parallax = nil, nil
end

--- Helper: init misc params 
function Card:_init_misc_params(gm)
    local params, cfg, Fs = self.params, self.config, gm.Fs

    self.no_ui, self.children = cfg.card and cfg.card.no_ui, {}
    self.unique_val = Fs.hash_unit32(gm, self.ID)

    local st = self.states
    st.dealing = { is = N }                         -- dealing is a special state for card
    for _, v in ipairs(Tst) do st[v].can = Y end
    st.shader_visible      = st.shader_visible      or { can = Y, is = Y }
    st.suit_shader_visible = st.suit_shader_visible or { can = Y, is = Y }
    st.hide_shadow         = st.hide_shadow         or { can = Y, is = N }

    self.playing_card = params.playing_card
    gm.sort_id = (gm.sort_id or 0) + 1
    self.sort_id = gm.sort_id
    if params.viewed_back then self.back = "viewed_back" else self.back = "selected_back" end
    
    for _, b  in ipairs(Tbypass)  do self[b] = params[b] end
    for _, _m in ipairs(Tm)  do self[_m] = 0 end
    for i, v  in ipairs(Tatt) do self[v] = Tdv[i] end

    local _facing = params.facing or "front"
    self.facing, self.sprite_facing   = _facing, _facing
    self.click_timeout, self.T.scale  = 0.3, 0.95
end

--- Helper: init render params
function Card:init_render_params(card, center)
    local T,         params     = self.T, self.params
    local h_idle,    h_active   = params.shadow_height_idle or 0.05, params.shadow_height_active or 0.18
    local h_hover,   h_dealing  = params.shadow_height_hover or 0.15, params.shadow_height_dealing or 0.12
    local fh_idle               = params.field_shadow_height_idle or 0.05
    local fh_active, fh_hover   = params.field_shadow_height_active or 0.1, params.field_shadow_height_hover or 0.08

    self.idle_tilt,      self.zoom      = 0, Y
    self.config,         self.tilt_var  = { card = card or {}, center = center }, { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 }
    self.hover_tilt,     self.offset    = 1, { x = 0, y = 0, wo = nil, ro = nil }
    
    self.template_shader       = params.template_shader or "generic"
    self.shadow_heights        = { idle = h_idle, active = h_active, hover = h_hover, dealing = h_dealing }
    self.field_shadow_heights  = { idle = fh_idle, active = fh_active, hover = fh_hover }
    self.shadow_height         = h_idle

end

--_________________________________
--- Main
--_________________________________
function Card:init_card_attributes(gm, x, y, w, h, card, center, params)
    self.params, self.gm = params or {}, gm
    Actor.init(self, gm, x, y, w, h)

    _format_card(card)
    self:init_render_params(card, center)
    self:_init_misc_params(gm)
    
    self:set_ability(center, Y)
    self:set_base(card, Y)
    self.discard_pos = { r = 3.6*(rand() - 0.5), x = rand(), y = rand() }

    self:_init_children(gm)
    self:set_cost()
    
    local gR = gm.R;                   local RCARD = gR.CARD
    if getmetatable(self) == Card then push(RCARD, self) end
    self.RCARD = RCARD
end

------------------------------------------
--- Remove 
------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function Card:remove()
    self.removed = Y
    local gm, ab = self.gm, self.ability;       local gUI, pc = gm.UI, gm.run_card_id

    if self.zone then self.zone:remove_card(self) end

    self:remove_from_deck()
    if pc then cleanup(pc, self); for k, v in ipairs(gm.run_card_id) do v.playing_card = k end end

    destroy_tree(self.children)
    cleanup(self.RCARD, self)
    Actor.remove(self)
end

end
