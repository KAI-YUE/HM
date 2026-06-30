local M = {}

local MoonKeys = {
    ["1"]  = "_11_moon_v1",
    ["2"]  = "_11_moon_v1",
    ["3"]  = "_3_moon",
    ["4"]  = "_3_moon",
    ["5"]  = "_13_moon_v3",
    ["6"]  = "_12_moon_v2",
    ["7"]  = "_12_moon_v2",
    ["8"]  = "_12_moon_v2",
    ["9"]  = "_12_moon_v2",
    ["10"] = "_13_moon_v3",
    V      = "_13_moon_v3",
    X      = "_13_moon_v3",
}

-----------------------------
--- main: get
----------------------------
function M.get(suit, rank, suit_code)
    if suit == "R" then return { [32] = "_14_mys", [64] = "_14_mys", [128] = "_14_mys" } end
    if suit ~= "M" then return { [32] = suit_code, [64] = suit_code, [128] = suit_code } end

    local key = MoonKeys[rank] or suit_code
    local key128 = (rank == "6" or rank == "7" or rank == "8" or rank == "9") and "_13_moon_v3" or key
    return { [32] = key, [64] = key, [128] = key128 }
end

return M
