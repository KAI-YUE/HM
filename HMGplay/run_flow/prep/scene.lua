local Chara     = require("HMEng.chara")
local Spritor   = require("HMEng.actors.spritor")
local BgDecor   = require("HMEng.entities.bg.bg_decor")
local IntroTimeline = require("HMfns.animate.start.intro_timeline")
local TiledMap  = require("HMEng.entities.bg.tiledmap")
local MoonDef   = require("HMEng.chara.defs.moon")
local Lens      = require("core.transform.lens")
local DebugFlags = require("HMGmgr.data.global.flags.debug_flags")

local min, max = math.min, math.max

local Y, N  = true, false
local DISABLE_BG_DECOR_FOR_FPS_TEST = true

local M = {}

-----------------------------
--- prep_chara
----------------------------------
function M.prep_chara(gm)
    local x, y, w, h = 0, 4.5, 5.5, 8.4
    gm.tut_chara = Chara(gm, x, y, w, h, { definition = MoonDef })
    gm.tut_chara.states.visible = N

    -- local Dialogue  = require("HMui.chara.dialogue")
    -- Dialogue.show_dialogue_box(gm, gm.tut_chara)

    return gm.tut_chara
end

-----------------------------
--- render_bg
----------------------------------
--- Helper: estimate field map rect
local function _estimate_field_map_rect(gm)
    local Mcfg,   Fcfg    = gm.Mcfg or {}, gm.Fcfg or {}
    local n_rows, n_cols  = Mcfg.n_rows,   Mcfg.n_cols
    local tile_w, tile_h  = Mcfg.tile_w,   Mcfg.tile_h

    local base_w, base_h  = max(n_cols*tile_w, 0.01),  max(n_rows*tile_h, 0.01)
    local growth          = Mcfg.map_growth or Fcfg.map_growth or {}
    local pad_l,  pad_r   = base_w*(growth.left or 0), base_w*(growth.right or 0)
    local pad_t,  pad_b   = base_h*(growth.top or 0),  base_h*(growth.bottom or 0)

    local x, y = -0.2*base_w, -0.2*base_h

    return { x = x, y = y, w = base_w + pad_l + pad_r, h = base_h + pad_t + pad_b }
end

--- Helper: delay bg decor until field spawn
local function _delay_bg_decor_until_field_spawn(gm)
    local decor, EM = gm.bg_decor, gm.E_MANAGER
    if not decor or not decor.states or not decor.states.visible then return end

    local timeline = IntroTimeline.bg_decor or {}
    local delay    = timeline.field_spawn or 0
    local fade_in  = timeline.fade_in or 0
    if delay <= 0 or not EM then return end

    decor.draw_alpha = 0
    EM:enqueue_event({ trigger = "after", delay = delay, blockable = N, func = function()
        if decor.REMOVED or not decor.states then return Y end
        if fade_in <= 0 then decor.draw_alpha = 1; return Y end
        EM:enqueue_event({ trigger = "ease", delay = fade_in, ease = "sine", blockable = N, ref_table = decor, ref_value = "draw_alpha", ease_to = 1 })
        return Y
    end })
end

--- Helper: apply debug world camera
local function _apply_debug_world_camera(gm)
    local cam, RT, T = gm.camera, gm._room and gm._room.T, gm.bg and gm.bg.T
    if not (cam and RT and T) then return end
    local zoom = DebugFlags.fps.world_camera_zoom or 1
    cam.min_zoom = min(cam.min_zoom or zoom, zoom)
    cam:set_target(nil)
    cam:set_zoom(zoom)
    cam.x, cam.y = T.x + 0.5*T.w - 0.5*RT.w/zoom, T.y + 0.5*T.h - 0.5*RT.h/zoom
    cam.velocity.x, cam.velocity.y, cam.zoom_velocity = 0, 0, 0
end

---_________________________________________
--- main: render_bg
---_________________________________________
function M.render_bg(gm)
    local Mcfg, Dcfg  = gm.Mcfg, gm.Dcfg
    local map_rect    = _estimate_field_map_rect(gm)

    gm.bg        = TiledMap(gm, map_rect.x, map_rect.y, map_rect.w, map_rect.h, Mcfg)
    gm.bg_decor  = nil
    if not DISABLE_BG_DECOR_FOR_FPS_TEST then
        gm.bg_decor  = BgDecor(gm,  map_rect.x, map_rect.y, map_rect.w, map_rect.h, Dcfg)
        if gm.field then gm.field:set_bg_decor(gm.bg_decor) end
        _delay_bg_decor_until_field_spawn(gm)
    elseif gm.field then gm.field:clear_bg_decor() end

    if gm.camera then
        gm.camera:set_bounds_from_tiledmap(gm.bg)
        if gm.debug_freeze_camera_world_view then _apply_debug_world_camera(gm) else gm.camera:snap_to_target() end
    end
end

-----------------------------
--- render_bg_spritor
----------------------------------
function M.render_bg_spritor(gm)
    local TA, rT = gm.T_atlas, gm._room.T
    gm.bg        = Spritor(gm, 0, 0, rT.w/2, rT.h/2, TA["map"], "map")
    gm.bg.lens   = Lens({ width = 1, height = 1, stages = 4, sharpen = 0 })
    gm.bg:set_alignment({ major = gm._room_r, type = "cm", bond = "Strong", offset = { x = 0, y = 0 } })
end

return M
