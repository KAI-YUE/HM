local Y, N = true, false

local LW, LG = love.window, love.graphics
local push = table.insert

local display_utils = {}

-----------------------------------------------------------------------------
--- fetch_display_info: Updates all display information for all displays for a given screenmode
--------------------------------------------------------------------------------
--- Helper: _full_screen 
local function _full_screen(i, display, res, _SW, _SWD)
    local res_option, dpi_s, m_dims, s_res = 1, _SWD[i].DPI_scale, _SWD[i].MONITOR_DIMS, _SWD[i].screen_resolutions
    for _, v in ipairs(LW.getFullscreenModes(i)) do
        
        local _w, _h = v.width*dpi_s, v.height*dpi_s
        if _w > m_dims.width or _h > m_dims.height then goto continue end
        
        local strings, values = s_res.strings, s_res.values
        push(strings, v.width .. " X " .. v.height)
        push(values, { w = v.width, h = v.height })
        if i == _SW.selected_display and i == display and res.w == v.width and res.h == v.height then res_option = #values end
        ::continue::
    end
    return res_option
end

--- Helper: _resolved_screenmode
local function _resolved_screenmode(screenmode) return screenmode == "auto" and "Borderless" or screenmode end

--______________________________
--- Main 
--______________________________
function display_utils.fetch_display_info(gm, screenmode, display)
    local SET = gm.SET;            local _SW = SET.s_win

	display, screenmode = display or _SW.selected_display or 1, _resolved_screenmode(screenmode or _SW.screenmode or "auto")

	local display_count, res_option = LW.getDisplayCount(), 1
	local realw, realh = LW.getMode()
	local curr_res     = { w = realw, h = realh }

	_SW.display_names = {}
	for i = 1, display_count do
        local _SWD = _SW.s_disp;           _SWD[i] = {}
		_SWD[i].screen_resolutions = { strings = {}, values = {} }
		_SW.display_names[i] = tostring(i)

		local render_w, render_h  = LW.getDesktopDimensions(i)
		local unscaled_dims, _SWr = LW.getFullscreenModes(i)[1], _SWD[i].screen_resolutions

		_SWD[i].DPI_scale, _SWD[i].MONITOR_DIMS = 1, unscaled_dims
		if     screenmode == "Fullscreen" then res_option = _full_screen(i, display, curr_res, _SW, _SWD)
		elseif screenmode == "Windowed"   then _SWr.strings[1], _SWr.values[1] = "-",  { w = 1280, h = 720 }
		elseif screenmode == "Borderless" then local md, scale = _SWD[i].MONITOR_DIMS, _SWD[i].DPI_scale; _SWr.strings[1], _SWr.values[1] = (md.width / scale) .. " X " .. (md.height / scale), curr_res end
	end
	return res_option
end

return display_utils
