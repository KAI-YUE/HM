local Actor = require("HMEng.actors.actor")
local TabUtils = require("HMfns.utils.table_utils")

local deep_copy = TabUtils.deep_copy

local fields = { "sort_id", "params", "no_ui", "base_cost", "extra_cost", "cost", "sell_cost", "facing", "sprite_facing", "seal", 
    "highlighted", "debuff", "rank", "added_to_deck", "label", "playing_card", "base", "ability", "pinned", "edition", 
    "bypass_discovery_center", "bypass_discovery_ui", "bypass_lock" }

return function (Card)
--- Helper: copy_card_front
local function copy_card_front(card) if type(card) == "table" then return deep_copy(card) end end

--- Helper: resolve_saved_front
local function resolve_saved_front(card_tab)
    local sf = card_tab.save_fields or {}
    return copy_card_front(sf.front or sf.card_front or sf.card_data or (type(sf.card) == "table" and sf.card) or card_tab.base)
end

--- Helper: resolve_saved_center_key
local function resolve_saved_center_key(card_tab)
    local sf = card_tab.save_fields or {}
    return sf.template or sf.center or "c_base"
end

---------------------------------------------
--- Save 
---------------------------------------------
function Card:save()
    local cfg = self.config
    local card_tab = { save_fields = { center = cfg.center_key, card = cfg.card_key, front = copy_card_front(cfg.card) }, flipping = nil}
    for _, f in ipairs(fields) do card_tab[f] = self[f] end
    card_tab.sprite_facing = self.facing  -- overwrite sprite_facing
    return card_tab
end

---------------------------------------------
--- Load 
---------------------------------------------
function Card:load(gm, card_tab, other_card)
    self.config = {};                                           local cfg = self.config
    cfg.center_key   = resolve_saved_center_key(card_tab)
    cfg.template     = gm.CMod[cfg.center_key] or gm.CMod.c_base
    
    self.sticker_run   = nil;                                   local center = cfg.template
    local cname, T, VT = center.name, self.T, self.VT
    for _, f in ipairs(fields) do self[f] = card_tab[f] end 

    VT.h, VT.w   = T.h, T.w
    cfg.card_key = card_tab.save_fields and card_tab.save_fields.card
    cfg.card     = resolve_saved_front(card_tab)

    self:set_sprites(cfg.template, cfg.card)
end

end
