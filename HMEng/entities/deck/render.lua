local I18N, CUtils = require("HMfns.utils.format.i18n_utils"), require("HMfns.animate.color.color_utils")
local C       = require("HMfns.animate.color.color_const")

local i18n, lerpc  = I18N.i18n, CUtils.lerp_colors

local cc = C.CLEAR
local _td, _tnt, _sO, _sV = "descriptions", "name_text", "Other", "Voucher"
local Y, N = true, false

return function (Deck)
-----------------------------------------------------------------------
--- generate_UI
-----------------------------------------------------------------------
--- Helper: deck layout
function Deck:_deck_layout(d, challenge, name, loc_nodes)
    local t = _root({ minw = 5*d, minh = 2.5*d, id = self.name, color = cc })
    local tn, content = t.nodes, nil
    if name == "Challenge Deck" then 
        local _b, label = "deck_view_challenge", { i18n(gm, challenge.id, "challenge_names") }
        content = _btn(gm, { button = "deck_view_challenge", label = label, minw = 2.2, minh = 1, scale = 0.6, id = challenge })
    else content = cat_rows(loc_nodes, Y, 5*d) end 
    
    t.nodes = { content };             return t
end

--- Main
function Deck:generate_UI(other, ui_scale, min_dims, challenge)
    local gm, min_dims, ui_scale, center    = self.gm,  min_dims or 0.7, ui_scale or 0.9, other or self.effect.template
    local name, ecfg, cond, _CH, _PC, PCP   = other and other.name or self.name, other and other.config or self.effect.config, center.unlock_condition, gm.CHALLENGES, gm.CMod, gm.P_CPools.Stake
    local loc_args, loc_nodes, challenge, F = nil, {}, _CH and _CH[get_challenge_int_from_id(challenge or "")], gm.Fs
    local c_type = cond and cond.type

    if not center.unlocked then
        if not cond then i18n(gm, { type = _td, key = "demo_locked", set = _sO, nodes = loc_nodes, vars = loc_args })
        elseif c_type == "win_deck" then
            local other_name = i18n(gm, "k_unknown")
            if _PC[cond.deck].unlocked then other_name = i18n(gm, { type = _tnt, set = "Deck", key = cond.deck }) end
            i18n(gm, { type = _td, key = "deck_locked_win", set = _sO, nodes = loc_nodes, vars = { other_name } })
        
        elseif c_type == "discover_amount" then i18n(gm, { type = _td, key = "deck_locked_discover", set = _sO, nodes = loc_nodes, vars = { tostring(cond.amount) } })
        
        elseif c_type == "win_stake"       then 
            local other_name = i18n(gm, { type = _tnt, set = "Stake", key = PCP[cond.stake].key })
            loc_args = { other_name, colors = { F.fetch_stake_col(cond.stake) } }
            i18n(gm, { type = "descriptions", key = "deck_locked_stake", set = _sO, nodes = loc_nodes, vars = loc_args })
        end
        return self:_deck_layout(min_dims, challenge, name, loc_nodes)
    end

    if name == "Red Deck"      then loc_args = { ecfg.discards } end 

    localize{ type = _td, key = center.key, set = "Deck", nodes = loc_nodes, vars = loc_args }
    return self:_deck_layout(min_dims, challenge, name, loc_nodes)
end

end