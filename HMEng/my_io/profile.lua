local clock = os.clock

--- Simple profiler written in Lua.
local profile = {}

-- function labels, defs, time_of_last_calls, total_execution_time, num_of_calls, internal_profile_fns
local _labeled, _defined, _tcalled, _telapsed, _ncalls, _internal = {}, {}, {}, {}, {}, {}
-- function definitions

-------------------------------------------
--- Hooker 
-------------------------------------------
-- @tparam string event Event type; @tparam number line Line number; @tparam[opt] table info Debug info table
function profile.hooker(event, line, info)
	info = info or debug.getinfo(2, "fnS");               
    local f, _def, _tc = info.func, info.short_src .. ":" .. info.linedefined, "tail_call"
    
	if _internal[f] or info.what ~= "Lua" then return end                          -- ignore the profiler itself
	if info.name       then _labeled[f] = info.name end                            -- get the function name if available
	if not _defined[f] then _defined[f], _ncalls[f], _telapsed[f] = _def, 0, 0 end -- find the line definition
	if _tcalled[f]     then local dt = clock() - _tcalled[f]; _telapsed[f], _tcalled[f] = _telapsed[f] + dt, nil end
	if event == _tc    then local prev = debug.getinfo(3, "fnS"); profile.hooker("return", line, prev); profile.hooker("call", line, info); return end
	if event == "call" then _tcalled[f] = clock(); return end
    _ncalls[f] = _ncalls[f] + 1
end

---------------------------------------------------------------
--- Set_clock: Sets a clock function to be used by the profiler
---------------------------------------------------------------
-- @tparam function func Clock function that returns a number
function profile.setclock(f) assert(type(f) == "function", "clock must be a function"); clock = f end

---------------------------------------------------------------
--- Start: Starts collecting data
---------------------------------------------------------------
function profile.start()
	if rawget(_G, "jit") then jit.off(); jit.flush() end
	debug.sethook(profile.hooker, "cr")
end

-----------------------------------------------------------------
--- Stop: Stops collecting data
-----------------------------------------------------------------
function profile.stop()
	debug.sethook()
	for f in pairs(_tcalled) do local dt = clock() - _tcalled[f]; _telapsed[f], _tcalled[f] = _telapsed[f] + dt, nil end
	
	local lookup = {} -- merge closures
	for f, d in pairs(_defined) do
		local id  = (_labeled[f] or "?") .. d
		local f2  = lookup[id]
		if not f2  then lookup[id] = f; goto continue end
        _ncalls[f2], _telapsed[f2] = _ncalls[f2] + (_ncalls[f] or 0), _telapsed[f2] + (_telapsed[f] or 0)
        _defined[f], _labeled[f], _ncalls[f], _telapsed[f] = nil, nil, nil, nil
        ::continue::
	end
	collectgarbage("collect")
end

-----------------------------------------
--- Reset: Resets all collected data
----------------------------------------
function profile.reset()
	for f in pairs(_ncalls)   do _ncalls[f]   = 0   end
	for f in pairs(_telapsed) do _telapsed[f] = 0   end
	for f in pairs(_tcalled)  do _tcalled[f]  = nil end
	collectgarbage("collect")
end

------------------------------------------------
--- Compare 
------------------------------------------------
function profile.comp(a, b)
	local dt = _telapsed[b] - _telapsed[a]
	if dt == 0 then return _ncalls[b] < _ncalls[a] end
	return dt < 0
end

----------------------------------------------------------------------------------
--- Query: Iterates all functions that have been called since the profile was started
----------------------------------------------------------------------------------
-- @tparam[opt] number limit Maximum number of rows
function profile.query(limit)
	local t = {}
	for f, n in pairs(_ncalls) do if n > 0 then t[#t + 1] = f end end;  table.sort(t, profile.comp)
	if limit then while #t > limit do table.remove(t) end end
	local p = 0
    for i, f in ipairs(t) do
		local dt = 0; if _tcalled[f] then dt = clock() - _tcalled[f] end
		local q = _telapsed[f] + dt - p;               local p = q;
        t[i] = { i, _labeled[f] or "?", _ncalls[f], _telapsed[f] + dt, q/_ncalls[f], _defined[f] }
	end
	return t
end

-------------------------------------------------------------------------------------------
--- Report: Generates a text report
-------------------------------------------------------------------------------------------
function check_memory()
    collectgarbage("collect") -- Force a full GC cycle
    local mem = string.format("Memory used after Garbage Collect = %.1f M\n", collectgarbage("count")/1024)
    return mem
end
-- @tparam[opt] number limit Maximum number of rows
function profile.report(n)
    local n = n or 50
	local out, cols, report = {}, { 3, 29, 11, 24, 32 }, profile.query(n)
	for i, row in ipairs(report) do
		for j = 1, 5 do
            local s = tostring(row[j])
			local l1, l2 = #s, cols[j]
			if     l1 < l2 then s = s .. (" "):rep(l2 - l1)
			elseif l1 > l2 then s = s:sub(l1 - l2 + 1, l1) end
			row[j] = s
		end
		out[i] = table.concat(row, " | ")
	end

    local mem_use = check_memory()
	local row_sep = " +-----+-------------------------------+-------------+--------------------------+----------------------------------+----------------------------------+ \n"
	local col_hdr = " | #   | Function                      | Calls       | Time                     | Unit Time                        | Code                             | \n"
	local sz      = mem_use..row_sep .. col_hdr .. row_sep
	if #out > 0 then sz = sz .. " | " .. table.concat(out, " | \n | ") .. " | \n" end
	return "\n" .. sz .. row_sep
end

---------------------------------------------------
-- store all internal profiler functions
---------------------------------------------------
for _, v in pairs(profile) do if type(v) == "function" then _internal[v] = true end end
return profile
