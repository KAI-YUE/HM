local CardZone = require("HMEng.entities.board.cardzone")
local FileIO   = require("core.io.fileio")

require("HMEng.my_io.string_packer")

local _tt, Y, N = "table", true, false

local M = {}

---------------------------------------------------------------
--- Serialize
---------------------------------------------------------------
function M.serialize(t)
	local ret_t, Class = {}, require("core.class")
	for k, v in pairs(t) do
		if type(v) == "table" then
			if v.is and v.is(v, Class) then ret_t[k] = [["]].."MANUAL_REPLACE"..[["]]
			else    ret_t[k] = M.serialize(v) end
		else        ret_t[k] = v    end
	end
	return ret_t
end

----------------------------------------------------------------
-- Save State dict: save the current run snapshot into f_handler
----------------------------------------------------------------
-- Helper: fetch ths serial 
local function _ser(_list, class)
    local objs = {}
    for k, v in pairs(_list) do 
        if type(v) ~= _tt or not v.is or not v:is(class) then goto continue end
        local ser = v.save and v:save()
        if ser then objs[k] = ser end
        ::continue::
    end
    return objs
end

-- Main: build the major info in state dict
function M.build_state_dict(gm, action)
    if action then gm.action = action end
    local game, cardzones  = gm.GAME, _ser(gm, CardZone)
    
    return M.serialize({ cardzones = cardzones, GAME = game, g_state = gm.g_state,
    ACTION = gm.action , Ver  = gm.Ver })
end

-- Main: save the major info in state dict
function M.save_state_dict(gm, action)
	gm.culled_table = M.build_state_dict(gm, action)
	gm.args.save_run = gm.culled_table
    gm:_run_file_handler()
end

----------------------------------------------------------------
-- delete state dict 
----------------------------------------------------------------
function M.delete_state_dict(gm)
	if gm.slot_save_path then love.filesystem.remove(gm:slot_save_path(gm.SET.profile))
	else love.filesystem.remove((gm.SET.profile or "").."/save.hm") end
	gm.saved_game = nil
	gm.f_handler = gm.f_handler or {}
	gm.f_handler.run = nil
end

-------------------------------------------------
-- convert save to meta: migrate old unlock files into meta.hm
-------------------------------------------------
function M.convert_save_to_meta(gm)
	if love.filesystem.getInfo((gm.SET.profile or "").."/unlocked_jokers.hm") then
		local _meta = { unlocked = {}, alerted = {}, discovered = {} }

		local function slurp_flags(fname, target)
			if love.filesystem.getInfo((gm.SET.profile or "").."/"..fname) then
				for line in string.gmatch(((get_compressed and get_compressed((gm.SET.profile or "").."/"..fname)) or "").."\n", "([^\n]*)\n") do
					local key = line:gsub("%s+", "")
					if key ~= "" then target[key] = true end
				end
			end
		end

		slurp_flags("unlocked_jokers.hm",  _meta.unlocked)
		slurp_flags("discovered_jokers.hm", _meta.discovered)
		slurp_flags("alerted_jokers.hm",    _meta.alerted)

		love.filesystem.remove((gm.SET.profile or "").."/unlocked_jokers.hm")
		love.filesystem.remove((gm.SET.profile or "").."/discovered_jokers.hm")
		love.filesystem.remove((gm.SET.profile or "").."/alerted_jokers.hm")

		if gm.shared_save_path then
			local shared = FileIO.unpickle(gm:shared_save_path()) or {}
			shared.meta = shared.meta or {}
			shared.meta[gm.SET.profile or 1] = _meta
			FileIO.pickle_dump(gm:shared_save_path(), shared)
		elseif compress_and_save then
			compress_and_save((gm.SET.profile or "").."/meta.hm", FileIO.pickle_pack(_meta))
		end
	end
end

return M
