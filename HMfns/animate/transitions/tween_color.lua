local C, CUtils = require("HMfns.animate.color.color_const"), require("HMfns.animate.color.color_utils")
local TabUtils  = require("HMfns.utils.table_utils")

local te, ck, cb       = "ease", C.BLACK, C.BLUE
local cw, co, crd      = C.WHITE, C.ORANGE, C.RED
local lerpc, contains  = CUtils.lerp_colors, TabUtils.contains 
local nblinds, ablinds = { "Small Blind", "Big Blind" }, { "Boss", "Small", "Big" }
local sd_act           = { "Skipped", "Defeated" }
local Y, N   = true, false

local color  = {}
----------------------------------------------------------
--- Tween value
----------------------------------------------------------
function color.tween_field_by(gm, t, v, mod, floored, t_type, not_blockable, delay, ease_type)
	local EM, mod, b = gm.E_MANAGER, mod or 0, (not_blockable == N)
    local e, d, et   = t[v] + mod, delay or 0.3, ease_type
	EM:enqueue_event({ trigger = te, blockable = b, blocking = N, ref_table = t, ref_value = v, ease_to = e, timer = t_type, delay = d, type = et, func = function(t) return floored and math.floor(t) or t end })
end

----------------------------------------------------------
--- Tween color 
----------------------------------------------------------
function color.tween_color_to(gm, old_color, new_color, delay) for i = 1, 4 do color.tween_field_by(gm, old_color, i, new_color[i] - old_color[i], false, "real_s", nil, delay) end end

----------------------------------------------------------
--- Tween background Palette 
----------------------------------------------------------
function color.tween_background_palette(gm, args)
    local tween_field, contains = color.tween_field_by, gm.Fs.contains
    local B, bg_code            = C.BACKGROUND, {"C", "L", "D"}
    local sp_color, te_color    = args.special_color, args.tertiary_color
    local contrast, new_color   = args.contrast, args.new_color

	for k, v in pairs(B) do
        if not (args.new_color and contains(bg_code, k)) then goto continue end
        if sp_color and te_color then
            local col_key = (k == "L" and "new_color") or (k == "C" and "special_color") or "tertiary_color"
            for i = 1, 3 do tween_field(gm, v, i, args[col_key][i] - v[i], N, nil, Y, 0.6) end
        else
            local brightness = (k == "L" and 1.3) or (k == "D" and (sp_color and 0.4 or 0.7)) or 0.9
            if k == "C" and sp_color  then for i = 1, 3 do tween_field(gm, v, i, sp_color[i] - v[i], N, nil, Y, 0.6) end
            else                           for i = 1, 3 do tween_field(gm, v, i, new_color[i]*brightness - v[i], N, nil, Y, 0.6) end end
        end
        ::continue::
	end
	if not contrast then return end
	tween_field(gm, B, "contrast", contrast - B.contrast, N, nil, Y, 0.6)
end

----------------------------------------------------------
--- Tween background blind 
----------------------------------------------------------
-- Helper: handle the boss
local function handle_boss_state(gm, bname, tween_bg, shade, tint)
    local boss_col = ck
    for _, v in pairs(gm.P_BLINDS) do
        if v.name ~= bname then goto continue end
        if v.boss.showdown then
            tween_bg(gm, {new_color = C.BLUE, special_color = crd, tertiary_color = shade(ck, 0.4), contrast = 3})
            return
        end
        boss_col = v.boss_color or ck
        ::continue::
    end
    local new_c = tint(lerpc(boss_col, ck, 0.3), 0.1)
    tween_bg(gm, { new_color = new_c, special_color = boss_col, contrast = 2 })
end

--__________________________________________
-- Main: Tween background blind 
--_____________________________________________
function color.tween_background_blind(gm, state, blind_override)
    local game, st  = gm.GAME,  gm.g_states
    local Fs, blind = gm.Fs, game.blind
	local blindname = blind_override or (blind and blind.name ~= "" and blind.name) 

    local cd_main, c2        = C.DYN_UI.MAIN, C.SECONDARY_SET
    local filter, blind      = C.FILTER, C.BLIND
    local tween_color, tint  = color.tween_color_to,  Fs.tint
    local tween_bg,    shade = color.tween_background_palette, Fs.shade
    
	if not blindname or blindname == "" then bname = "Small Blind" end                   -- default value for blind name 
	if     state == st.shop          then tween_color(gm, cd_main, lerpc(crd, ck, 0.9))  -- Blind-related colors
	elseif state == st.tarot_pack    then tween_color(gm, cd_main, lerpc(cw, ck, 0.9))
	elseif state == st.spectral_pack then tween_color(gm, cd_main, lerpc(c2.Spectral, ck, 0.9))
	elseif state == st.std_pack then tween_color(gm, cd_main, crd)
	elseif state == st.buff_pack  then tween_color(gm, cd_main, filter)
	elseif state == st.planet_pack   then tween_color(gm, cd_main, lerpc(c2.Planet, ck, 0.9))
	elseif game.blind                then game.blind:change_color() end

	if     state == st.tarot_pack    then tween_bg(gm, { new_color = C.PURPLE, special_color = shade(ck, 0.2), contrast = 1.5 }) -- Background color
	elseif state == st.spectral_pack then tween_bg(gm, { new_color = c2.Spectral, special_color = shade(ck, 0.2), contrast = 2 })
	elseif state == st.std_pack then tween_bg(gm, { new_color = darken(ck, 0.2), special_color = crd, contrast = 3 })
	elseif state == st.buff_pack  then tween_bg(gm, { new_color = filter, special_color = ck, contrast = 2 })
	elseif state == st.planet_pack   then tween_bg(gm, { new_color = ck, contrast = 3 })
	elseif game.won                  then tween_bg(gm, { new_color = blind.won, contrast = 1 })
	elseif contains(nblinds, bname)  then tween_bg(gm, {new_color = blind.Small, contrast = 1})
    else                                  handle_boss_state(gm, bname, tween_bg, shade, tint) end
end

-----------------------------------------------
--- Card Color 
-----------------------------------------------
local function is_locked(c, card) return c.unlocked == false and not (card and card.bypass_lock) end

local function is_undiscovered_playable(gm, c)
	if c.unlocked == false then return false end
	local is_playable = (c.set == "Joker" or c.consumable or c.set == "Voucher")
	local in_area     = not ((c.zone ~= gm.jokers and c.zone ~= gm.consumables and c.zone) or not c.zone)
	return is_playable and not c.discovered and in_area
end

function color.resolve_card_color(gm, c, card)
	local set = c.set
    if     is_locked(c, card)              then return ck 
	elseif is_undiscovered_playable(gm, c) then return C.SPGRAY 
    elseif card and card.debuff            then return lerpc(crd, C.GRAY, 0.7) 
	elseif set == "Joker"                  then return C.RARITY[c.rarity] 
    elseif set == "Edition"                then return C.DARK_EDITION
	elseif set == "Booster"                then return C.BOOSTER end
	return C.SECONDARY_SET[set] or {0, 1, 1, 1}
end

-----------------------------------------------
--- Blind Main Color 
-----------------------------------------------
function color.resolve_blind_color(gm, blind)
	local disabled, blind = N, blind or ""
    local game, PB = gm.GAME, gm.P_BLINDS;          local rr = game.round_resets

	if contains(ablinds, blind) then
		rr.blind_states = rr.blind_states or {}
        local bstates   = rr.blind_states
        local b         = bstates[blind]
		if contains(sd_act, b) then disabled = Y end
		blind = rr.blind_choices[blind]
	end
    local Pb = PB[blind]
	if (disabled or not Pb) then return ck end
	if Pb.boss_color        then return Pb.boss_color end

	if blind == "bl_small" then return lerp_colors(cb, ck, 0.6) end
	if blind == "bl_big"   then return lerp_colors(co, ck, 0.6) end
	return ck
end

return color
