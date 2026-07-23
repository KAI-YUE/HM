local RNG = require("HMfns.utils.math.rng_utils")

local seeded_rand = RNG.seeded_random
local max         = math.max

local M = {}

--------------------------------------------------
--- unit: return seeded_rand [0, 1]
--------------------------------------------------
function M.unit(gm, seed, idx, tag) return seeded_rand(gm, table.concat({ tostring(seed), tostring(idx), tostring(tag) }, "|")) end

--------------------------------------------------
--- sort_keys
--------------------------------------------------
function M.sorted_keys(tab)
    local out = {}
    for k in pairs(tab or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end

--------------------------------------------------
--- filter known keys 
--------------------------------------------------
function M.filter_known_keys(keys, atlas)
    local out, quads = {}, atlas and atlas.quads or {}
    for _, key in ipairs(keys or {}) do if quads and quads[key] then out[#out + 1] = key end end
    return out
end

--------------------------------------------------
--- weighted choice
--------------------------------------------------
function M.pick_weighted_key(gm, keys, weights, seed, idx, default_weight)
    local total_w = 0
    for _, key in ipairs(keys or {}) do
        local cfg = (weights or {})[key] or {}
        total_w = total_w + max(cfg.spawn_pr or default_weight or 1, 0)
    end
    if total_w <= 0 then return end

    local roll, accum = M.unit(gm, seed, idx, "key") * total_w, 0
    for _, key in ipairs(keys) do
        local cfg = (weights or {})[key] or {}
        accum = accum + max(cfg.spawn_pr or default_weight or 1, 0)
        if roll <= accum then return key end
    end
    return keys[#keys]
end

--------------------------------------------------
--- sign Helpers
--------------------------------------------------
function M.flip_sign(gm, seed, idx, tag, enabled)
    if not enabled then return 1 end
    return M.unit(gm, seed, idx, tag) < 0.5 and -1 or 1
end

return M
