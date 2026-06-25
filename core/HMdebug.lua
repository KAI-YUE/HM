local class = require("core.class")

local LG, push = love.graphics, table.insert
local debug_utils = {}

------------------------------------------
--- Timing the func 
------------------------------------------
function debug_utils.now() return love.timer.getTime() end
function debug_utils.ms(seconds) return seconds * 1000 end

-------------------------------------------------------------------
--- Table print: Pretty print a table as a string (recursive, guarded depth)
-------------------------------------------------------------------
function debug_utils.tprint(tbl, indent)
	if not indent then indent = 0 end
	local res = string.rep(" ", indent) .. "{\r\n"
	indent = indent + 2
	for k, v in pairs(tbl) do
		res = res .. string.rep(" ", indent)
		if     type(k) == "number" then res = res .. "[" .. k .. "] = "
		elseif type(k) == "string" then res = res .. k .. "= " end
		if     type(v) == "number" then res = res .. v .. ",\r\n"
		elseif type(v) == "string" then res = res .. "\"" .. v .. "\",\r\n"
		elseif type(v) == "table"  then
			if indent >= 10 then res = res .. tostring(v) .. ",\r\n"
            else                 res = res .. tostring(v) .. debug_utils.tprint(v, indent + 1) .. ",\r\n" end
		else                     res = res .. "\"" .. tostring(v) .. "\",\r\n" end
	end
	res = res .. string.rep(" ", indent-2) .. "}"
	return res
end

-------------------------------------------------------
-- diff_tables: returns a list of differences:
-------------------------------------------------------
function debug_utils.diff_tables(t1, t2)
	local diffs = {}
	-- keys that exist in t1
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		if     v2 == nil then push(diffs, { key = k, change = "removed", old = v1, new = nil })
		elseif v1 ~= v2  then push(diffs, { key = k, change = "changed", old = v1, new = v2 }) end
	end
	-- keys that exist only in t2
	for k, v2 in pairs(t2) do if t1[k] == nil then push(diffs, { key = k, change = "added", old = nil, new = v2 }) end end
    for _, d in ipairs(diffs) do  print(d.key, d.change, d.old, "→", d.new) end
end

------------------------------------------------
--- Save table
-------------------------------------------------
function debug_utils.save_table(table, file_name)
	local table_str = debug_utils.tprint(table)
	local file_name = file_name or "/home/kyue/Documents/output.txt"
    print(("Table saved to %s"):format(file_name))
	local f = assert(io.open(file_name, "w"))  -- "w" = write mode (overwrite)
	f:write(table_str)
	f:close()
end

---------------------------------------------------
--- Who called 
---------------------------------------------------
function debug_utils.who_called()
	-- level 1 = this function, level 2 = caller, level 3 = caller's caller, etc.
	local info = debug.getinfo(3, "nSl")  -- n=name, S=source, l=current line
	if info then print(("[caller] %s:%d in %s()"):format(info.short_src or "?", info.currentline or -1, info.name or "<anonymous>"))
    else print("[caller] <no info>") end
end

-----------------------------------------------
--- Contains 
------------------------------------------------
function debug_utils.contains(t, x) for i = 1, #t do if t[i] == x then return true end end; return false end

------------------------------------------------
--- Who is fn
-------------------------------------------------
function debug_utils.who_is_fn(fn)
    if not fn then return end 
	if type(fn) ~= "function" then
		print(("[fn] expected function, got %s (%s)"):format(type(fn), tostring(fn)))
		return
	end
    local info = debug.getinfo(fn, "nS")  -- n: name, S: source/lines
    print(("[fn] %s:%d (%s)"):format(info.short_src, info.linedefined, info.name or "<anonymous>"))
end

---------------------------------------------------
--- Time stamp 
----------------------------------------------------
function debug_utils.time_stamp() return os.date("%Y-%m-%d %H:%M:%S")  end

----------------------------------------------------
--- log screen change
----------------------------------------------------
--- Helper: log final composite anomalies
function debug_utils._log_composite_flags(gm)
    local flags = {}
    local shader = LG.getShader()
    local r, g, b, a = LG.getColor()
    local blend, alpha = LG.getBlendMode()
    local canvas = LG.getCanvas()
    local om = gm.UI and gm.UI.overlay_menu
    local ow = om and om.widget
    local ofx = ow and ow.fx_mask

    if shader then flags[#flags + 1] = "shader=" .. tostring(shader) end
    if abs(r - 1) > 0.001 or abs(g - 1) > 0.001 or abs(b - 1) > 0.001 or abs(a - 1) > 0.001 then
        flags[#flags + 1] = string.format("color=%.2f,%.2f,%.2f,%.2f", r, g, b, a)
    end
    if blend ~= "alpha" then flags[#flags + 1] = "blend=" .. tostring(blend) .. "/" .. tostring(alpha) end
    if canvas then flags[#flags + 1] = "canvas=" .. tostring(canvas) end
    if (gm.real_dt or 0) > 0.05 then flags[#flags + 1] = string.format("long_dt=%.3f", gm.real_dt) end
    if gm.screenwipe then flags[#flags + 1] = "screenwipe" end
    if ofx and abs(ofx) > 0.001 then flags[#flags + 1] = string.format("overlay_fx=%.3f", ofx) end
    if not gm.g_canvas then flags[#flags + 1] = "missing_g_canvas" end
    if gm._render_diag_canvas ~= gm.g_canvas then
        gm._render_diag_canvas = gm.g_canvas
        flags[#flags + 1] = "g_canvas_changed"
    end

    if #flags == 0 then return end

    local now = gm._T and gm._T.real_s or 0
    local key = table.concat(flags, "|")
    if key == gm._render_diag_key and now < (gm._render_diag_next or 0) then return end

    gm._render_diag_key = key
    gm._render_diag_next = now + 0.25
    print(string.format("[render] t=%.3f frame=%s %s", now, tostring(gm.FRS and gm.FRS.f_dr), key))
end

-------------------------------------------------
--- Which Actor 
-------------------------------------------------
function debug_utils.which_actor(actor)
    local GameObj = require("HMEng.actors.game_obj")
    local Actor = require("HMEng.actors.actor")
    local ParticleEmitter = require("HMEng.actors.particle_emitter")
    local Spritor  = require("HMEng.actors.spritor") 
    local TextFX   = require("HMEng.ui_actors.card_textfx")
    -- local UIPanel     = require("HMEng.ui_actors.ui_panel")  = require("HMEng.ui_actors.ui_panel")
    local UIWidget = require("HMEng.ui_actors.ui_widget")

    local Deck = require("HMEng.entities.deck")
    local Card = require("HMEng.entities.card")
    local CardFront = require("HMEng.entities.card.card_front")
    local CardZone = require("HMEng.entities.board.cardzone")
    local Controller = require("HMEng.controller")


    local mt = getmetatable(actor)
    if mt == GameObj then print("GameObj", actor)  
    elseif mt == Actor then print("Actor", actor) 
    elseif mt == ParticleEmitter then print("ParticleEmitter", actor)
    elseif mt == Spritor then print("Spritor", actor) 
    elseif mt == TextFX then print("TextFX", actor) 
    elseif mt == UIPanel then print("UIPanel", actor)
    elseif mt == UIWidget then print("UIWidget", actor) 
    elseif mt == Deck then print("Deck", actor) 
    elseif mt == Card then print("Card", actor)
    elseif mt == CardFront then print("CardFront", actor)
    elseif mt == CardZone then print("CardZone", actor)
    else print("SOMETHING ELSE", actor) end
end

return debug_utils
