local TabUtils = require("HMfns.utils.table_utils")

local rand   = math.random
local _pick  = TabUtils.random_pick

local Y, N = true, false

local color_utils = {}
--------------------------------------
--- convert hex code to {r, g, b, a}
--------------------------------------
function color_utils.hex_to_rgba(hex)
	local hex, out = hex:gsub("^#", ""), {}
	if #hex <= 6 then hex = hex .. "FF" end
	for i = 1, 4 do
		local idx   = (i - 1) * 2 + 1
		local pair  = hex:sub(idx, idx + 1)
		local v     = tonumber(pair, 16) or (i == 4 and 255 or 0)
		out[i] = v / 255
	end
	return out
end

-----------------------------------------
--- linear interpolation between C1 & C2 
-----------------------------------------
function color_utils.lerp_colors(C1, C2, propC1)
    local color = {}
    for i = 1, 4 do table.insert(color, (C1[i] or 0.5)*propC1 + (C2[i] or 0.5)*(1-propC1)) end
    return color
end

-----------------------------------------
--- shade | tint with alpha | tint: slightly fine-tune the color 
-----------------------------------------
function color_utils.shade(color, percent)          local q = 1 - percent; return { color[1]*q, color[2]*q, color[3]*q, color[4] } end
function color_utils.tint_with_alpha(color, alpha)  alpha = alpha or 1; return { color[1], color[2], color[3], (color[4] or 1) * alpha } end
function color_utils.tint(color, percent)           local p, q = percent, 1-percent; return { color[1]*q + p, color[2]*q + p, color[3]*q + p, color[4] } end

------------------------------------------------------
--- set alpha & random_alpha
------------------------------------------------------
function color_utils.set_alpha(color, new_alpha)  return { color[1], color[2], color[3], new_alpha } end
function color_utils.randomize_alpha(color, base_alpha)
    local base_alpha = base_alpha or 0.5
    local new_alpha  = base_alpha + (1 - base_alpha)*rand()
    return {  color[1], color[2], color[3], new_alpha } 
end

------------------------------------------------------
--- pick fx color
------------------------------------------------------
function color_utils.pick_fx_color() local C = require("HMfns.animate.color.color_const"); return _pick(C.FX_MASK.HOT_CANDIDATES) end

return color_utils
