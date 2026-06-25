local C = require("HMfns.animate.color.color_const")
local M = {}

function M.fetch_stake_col(_stake)
    local _cstake = { C.WHITE, C.RED, C.GREEN, C.BLACK, C.BLUE, C.PURPLE, C.ORANGE, C.GOLD }
    return _cstake[_stake]
end

return M