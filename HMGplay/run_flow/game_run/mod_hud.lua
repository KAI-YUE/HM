local RunHud = require("HMui.hud")
local LG     = love.graphics

local M = {}

local max = math.max

--- Helpers: clamp | gameplay
local function _clamp(v, min_v, max_v) return math.max(min_v, math.min(max_v, v)) end
local function _gameplay(gm) if not gm then return {} end; return gm.GAME and (gm.GAME.gameplay or gm.GAME.starting_params) or gm.GAME or {} end

-----------------------------
--- profile chara
----------------------------
--- Helper: hide world tut chara
local function _hide_world_tut_chara(gm)
    local chara = gm and gm.tut_chara; if not (chara and chara.states) then return end
    chara.states.visible = false
end

--- Helper: profile chara box
local function _profile_chara_box(child)
    local cfg, VT, tz = RunHud.Layout.profile_chara or {}, child.VT, child.rcfg.tile_size
    if cfg.relative ~= false then return { x = (cfg.x or 0)*VT.w*tz, y = (cfg.y or 0)*VT.h*tz, w = (cfg.w or 1)*VT.w*tz, h = (cfg.h or 1)*VT.h*tz, fit_axis = cfg.fit_axis or "height" } end
    return { x = (cfg.x or 0)*tz, y = (cfg.y or 0)*tz, w = (cfg.w or VT.w)*tz, h = (cfg.h or VT.h)*tz, fit_axis = cfg.fit_axis or "height" }
end

--- Helper: profile chara scale
local function _profile_chara_scale(box, dims, scale)
    local sx, sy = box.w/max(dims.w or 1, 1), box.h/max(dims.h or 1, 1)
    if box.fit_axis == "height" then sx = sy elseif box.fit_axis == "width" then sy = sx end
    return sx*(scale.x or 1), sy*(scale.y or 1)
end

--- Helper: draw profile chara model
local function _draw_profile_chara_model(chara, child)
    if not (chara and child and chara.model) then return end
    local dims, box = chara.model_dims or {}, _profile_chara_box(child)
    local off, scale = chara.model_offset or {}, chara.model_scale or {}
    local sx, sy = _profile_chara_scale(box, dims, scale)
    local x, y = box.x + 0.5*(box.w - (dims.w or 1)*sx) + (off.x or 0), box.y + (off.y or 0)
    LG.setShader()
    LG.setColor(1, 1, 1, chara.draw_alpha or 1)
    if chara.draw_mesh and chara.model_mesh and chara.mesh_draw_idx > 0 then LG.draw(chara.model_mesh[chara.mesh_draw_idx], x, y, 0, sx, sy); return end
    chara.model:draw(x, y, 0, sx, sy)
end

--- Helper: attach tut chara profile
local function _attach_tut_chara_profile(gm, panel)
    local chara = gm and gm.tut_chara; if not (chara and panel) then return end
    _hide_world_tut_chara(gm)
    RunHud.attach_profile_draw(panel, function(_, child) _draw_profile_chara_model(chara, child) end)
end

-----------------------------
--- stats
----------------------------
--- Helper: ensure stats
local function _ensure_stats(gm, run)
    local gp = _gameplay(gm)
    run.hud_stats = run.hud_stats or {
        player = { hp = gp.hp or 100, hp_max = gp.hp_max or 100, full = gp.full or gp.fullness or 100, full_max = gp.full_max or 100, money = gp.money or gp.dollars or 0 },
        foe    = { hp = 80, hp_max = 80, full = 70, full_max = 100, money = 0 },
    }
    return run.hud_stats
end

--- Helper: sync player stats
local function _sync_player_stats(gm, stats)
    local gp = _gameplay(gm)
    stats.hp, stats.hp_max       = gp.hp or stats.hp, gp.hp_max or stats.hp_max
    stats.full, stats.full_max   = gp.full or gp.fullness or stats.full, gp.full_max or stats.full_max
    stats.money                  = gp.money or gp.dollars or stats.money
end

--- Helper: write gameplay stat
local function _write_gameplay_stat(gm, stat, value)
    local gp = _gameplay(gm); if not gp then return end
    if stat == "money" and gp.money ~= nil then gp.money = value; return end
    if stat == "money" and gp.dollars ~= nil then gp.dollars = value; return end
    if stat == "full" and gp.full ~= nil then gp.full = value; return end
    if stat == "full" and gp.fullness ~= nil then gp.fullness = value; return end
    gp[stat] = value
end

-----------------------------
--- create
----------------------------
--- Helper: create panel
local function _create_panel(gm, run, side)
    local stats = _ensure_stats(gm, run)[side == "foe" and "foe" or "player"]
    local panel = RunHud.create_panel(gm, side, stats)
    if side == "player" then panel.update = function() _sync_player_stats(gm, stats) end end
    return panel
end

function M.create(gm, run)
    local UI = gm.UI
    if UI.player_hud then UI.player_hud:remove() end
    if UI.foe_hud then UI.foe_hud:remove() end

    _ensure_stats(gm, run)
    UI.player_hud = _create_panel(gm, run, "player")
    UI.foe_hud    = _create_panel(gm, run, "foe")
    _attach_tut_chara_profile(gm, UI.player_hud)
    run.player_hud, run.foe_hud = UI.player_hud, UI.foe_hud
    return UI.player_hud, UI.foe_hud
end

-----------------------------
--- refresh
----------------------------
function M.refresh(gm, run)
    if not run then return end
    local stats = _ensure_stats(gm, run)
    _sync_player_stats(gm, stats.player)
end

-----------------------------
--- debug_mod
----------------------------
function M.debug_mod(gm, stat, delta)
    local run = gm.run_loop; if not run then return end
    local stats = _ensure_stats(gm, run).player
    if stat == "money" then stats.money = math.max(0, (stats.money or 0) + delta); _write_gameplay_stat(gm, stat, stats.money); return stats.money end
    local max_key = stat .. "_max"
    stats[stat] = _clamp((stats[stat] or 0) + delta, 0, stats[max_key] or 100)
    _write_gameplay_stat(gm, stat, stats[stat])
    return stats[stat]
end

-----------------------------
--- toggle_foe
-----------------------------
function M.toggle_foe(gm)
    local foe = gm.UI and gm.UI.foe_hud; if not foe then return end
    foe.states.visible = not foe.states.visible
    if foe.widget then foe.widget.states.visible = foe.states.visible end
    return foe.states.visible
end

return M
