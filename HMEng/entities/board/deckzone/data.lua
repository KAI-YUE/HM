local TabUtils = require("HMfns.utils.table_utils")

local deep_copy, random_pick = TabUtils.deep_copy, TabUtils.random_pick

local M = {}

M.projected_quad_candidates = {
    { row = 4, col = 9 },
    
    { row = 5, col = 9 },
    { row = 5, col = 10 },

    { row = 6, col = 9 },
    { row = 6, col = 10 },
    { row = 6, col = 11 },
    
    { row = 7, col = 9 },
    { row = 7, col = 10 },
}

------------------------------------------
--- pick projected_quad_candidates
------------------------------------------
function M:pick_projected_quad_candidate(fallback)
    local candidates = M.projected_quad_candidates
    if #candidates == 0 then return fallback or { row = 6, col = 10 } end
    return random_pick(candidates)
end

return M
