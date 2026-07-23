local RNG = require("HMfns.utils.math.rng_utils")

local max, min = math.max, math.min
local Y, N = true, false

local Common = {}

--- Helper: xy_pair | cache_key | clamp | rotation_enabled | random_case_char
function Common.xy_pair(v, d) if type(v) == "number" then return { x = v, y = v } end; v = v or {}; return { x = v.x or d, y = v.y or d } end
function Common.cache_key(text, scale, seed, rotate) return ""..text..scale..":"..tostring(seed or "")..":"..tostring(rotate) end
function Common.clamp(v, lo, hi)              return min(hi, max(lo, v)) end
function Common.rotation_enabled(cfg)         return not (cfg and (cfg.letter_rotation == N or cfg.rotate_letters == N or cfg.disable_rotation == Y)) end
function Common.random_case_char(char, unit)  if type(char) ~= "string" or not char:match("^%a$") then return char end; return unit < 0.5 and char:upper() or char:lower() end

--- Helper: sampling_seed | sampling_seed_key
function Common.sampling_seed(self)      local cfg = self.config or {}; return cfg.sampling_seed or cfg.textfx_seed or self.ID; end
function Common.sampling_seed_key(self)  local seed = Common.sampling_seed(self); return type(seed) .. ":" .. tostring(seed or "") end

--- Helper: sampling_seed_number
function Common.sampling_seed_number(self, salt, numeric_mul)
    local seed = Common.sampling_seed(self)
    if type(seed) == "number" and type(salt) == "number" then return (numeric_mul or 1)*seed + salt end
    return RNG.string32(tostring(seed or "") .. ":" .. tostring(salt or ""), Y)
end

--- Helper: sampling_unit | cache_sampling_unit
function Common.sampling_unit(self, salt) return RNG.hash_string32(Common.sampling_seed_key(self) .. ":" .. tostring(salt or "")) end
function Common.cache_sampling_unit(cache, index, salt) return RNG.hash_string32(tostring(cache.sampling_seed_key or "") .. ":" .. tostring(index or 0) .. ":" .. tostring(salt or "")) end

return Common
