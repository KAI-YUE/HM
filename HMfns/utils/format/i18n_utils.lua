local C = require("HMfns.animate.color.color_const")

local err = "ERROR"

local M = {}

----------------------------------------------
-- Loc color: color lookup used in localized strings
----------------------------------------------
function M.loc_color(gm, _c, _default)
    local CS, SET = C.SUITS, C.SECONDARY_SET
    local loc_colors = gm.args and gm.args.LOC_COLORS
    loc_colors = loc_colors or {
        red     = C.RED,        mult         = C.MULT,         blue      = C.BLUE,            chips     = C.CHIPS,
        green   = C.GREEN,      money        = C.GOLD,         gold      = C.GOLD,            attention = C.FILTER,
        purple  = C.PURPLE,     white        = C.WHITE,        inactive  = C.UI.TEXT_INACTIVE,
        spades  = CS.spade,     hearts       = CS.heart,       clubs     = CS.club,           diamonds  = CS.diamond,
        tarot   = SET.Tarot,    planet       = SET.Planet,     spectral  = SET.Spectral,
        edition = C.EDITION,    dark_edition = C.DARK_EDITION, legendary = C.RARITY[4],       enhanced  = SET.Enhanced,
    }
    return loc_colors[_c] or _default or C.UI.TEXT_DARK
end

---------------------------------------------------
--- Raw lookup Helpers
---------------------------------------------------
--- Helper: _get_path
local function _get_path(root, path)
    local cur = root
    for key in tostring(path or ""):gmatch("[^%.]+") do
        if type(cur) ~= "table" then return end
        cur = cur[key]
    end
    return cur
end

--- Helper: _first
local function _first(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then return v end
    end
    return nil
end

--- Helper: _empty_for
local function _empty_for(_type)
    if _type == "raw_descriptions" then return {} end
    return ""
end

--- Helper: _lookup_scope
local function _lookup_scope(L, scope, key)
    if scope == "dictionary" or scope == "v_dictionary" or scope == "text" then
        return _get_path(L.ui and L.ui[scope], key)
    end
    return _first(
        _get_path(L[scope], key),
        _get_path(L.ui and L.ui[scope], key),
        _get_path(L.menu and L.menu[scope], key)
    )
end

function M.raw(gm, key, scope)
    local L = gm.T_I18N or {}
    if scope then return _lookup_scope(L, scope, key) end

    return _first(
        _get_path(L.ui and L.ui.dictionary, key),
        _get_path(L.dialogue, key),
        _get_path(L.menu, key),
        _get_path(L.ui, key)
    )
end

function M.interpolate(value, vars)
    if type(value) ~= "string" then return value end
    return (value:gsub("#(%d+)#", function(i) return tostring((vars and vars[tonumber(i)]) or err) end))
end

--________________________________________
--- Main: I18N, internationalization
--________________________________________
function M.i18n(gm, args, scope)
    if args and type(args) ~= "table" then return M.raw(gm, args, scope) or err end

    args = args or {}
    local _t, _k = args.type, args.key
    if _t == "ui"       then return M.raw(gm, _k, args.scope or "dictionary") or err end
    if _t == "dialogue" then return M.raw(gm, _k, "dialogue") or err end
    if _t == "menu"     then return M.raw(gm, _k, "menu") or err end

    if _t == "other"            then return _empty_for(_t) end
    if _t == "descriptions"     then return _empty_for(_t) end
    if _t == "unlocks"          then return _empty_for(_t) end
    if _t == "raw_descriptions" then return _empty_for(_t) end
    if _t == "text"             then return _empty_for(_t) end
    if _t == "variable"         then return _empty_for(_t) end
    if _t == "name_text"        then return _empty_for(_t) end
    if _t == "name"             then return _empty_for(_t) end

    return ""
end

--------------------------------------------------------
--- init i18n dict
-------------------------------------------------------
function M.init_i18n_dict(gm)
    gm.i18n_cache = {}
end

return M
