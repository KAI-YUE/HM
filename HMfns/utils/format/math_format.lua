local M = {}
local _format = string.format
local eps, _f, _log  = 1e-12, math.floor, math.log
local E_SWITCH_POINT = 1e11

-----------------------------------------------
--- format: number 2 string 
-----------------------------------------------
-- Helper: format the num to human-readable 
local function format_with_commas(n, fmt)
	local s = _format(fmt, n)
	s = s:reverse():gsub("(%d%d%d)", "%1,"):gsub(",$",""):reverse()
	return s
end

-- Main: format the input number to string
function M.format_num(num)
    if not num then return "" end
    if type(num) == "string" then return num end
	if num >= E_SWITCH_POINT then
		local x   = string.format("%.4g", num)
		local fac = _f(_log(tonumber(x) + eps, 10))
		return _format("%.3f", x/(10^fac)).."e"..fac
	end

    local fmt = "%.0f"
    if     num == _f(num) then fmt = "%.0f"
    elseif num >= 100     then fmt = "%.0f"
    elseif num >= 10      then fmt = "%.1f"
    else                       fmt = "%.2f" end
    return format_with_commas(num, fmt)
end

---------------------------------------------------------------
--- scale param to display a score 
---------------------------------------------------------------
function M.scale4score(scale, amt)
    local scale = scale or 1
    if type(amt) ~= "number" or amt >= E_SWITCH_POINT then return 0.7*scale end
    if amt >= 1e6 then return 14*0.75/(_f(_log(amt)) + 4)*scale
    else               return 0.75*scale end
end

---------------------------------------------------------------
--- Make time stamp
---------------------------------------------------------------
function M.make_timestamp()	return os.date("%Y%m%d_%H%M%S", os.time()) end


return M