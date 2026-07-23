local Camera        = require("core.transform.camera")
local IntroTimeline = require("HMfns.animate.start.intro_timeline")
local DebugFlags    = require("HMGmgr.data.global.flags.debug_flags")

local max = math.max

local M = {}

-----------------------------
--- prep_camera
----------------------------------
--- Helper: pawn intro zoom
local function _pawn_intro_zoom(base_zoom, pawn)
    local pT    = pawn and pawn.T
    local scale = pT and pT.scale or 1
    local zoom  = 0.9*(base_zoom or 1) / max(scale, 1e-6)
    return zoom
end

--- Helper: apply debug world camera
local function _apply_debug_world_camera(gm, RT)
    local cam, T = gm.camera, gm.bg and gm.bg.T or gm.field and gm.field.T; if not (cam and T and RT) then return end
    local zoom = DebugFlags.fps.world_camera_zoom or 1
    -- cam.min_zoom = min(cam.min_zoom or zoom, zoom)
    cam:set_target(nil)
    cam:set_zoom(zoom)
    cam.x, cam.y = T.x + 0.5*T.w - 0.5*RT.w/zoom, T.y + 0.5*T.h - 0.5*RT.h/zoom
    cam.velocity.x, cam.velocity.y, cam.zoom_velocity = 0, 0, 0
end

function M.prep_camera(gm, opts)
    opts = opts or {}
    local freeze_camera = DebugFlags.fps.freeze_camera_world_view
    gm.debug_freeze_camera_world_view = freeze_camera
    local room, field  = gm._room, gm.field
    local RT, pawn     = room and room.T,  gm.field_pawn;                   if not RT or not field or not pawn then return end

    local Tintro       = IntroTimeline.field
    local intro_zoom   = _pawn_intro_zoom(Tintro.camera_intro_zoom, pawn)
    local target_zoom  = Tintro.camera_target_zoom
    local start_zoom   = opts.silent_start and target_zoom or intro_zoom
    gm.camera = Camera({ x = RT.x, y = RT.y, w = RT.w, h = RT.h,
        zoom = start_zoom, min_zoom = freeze_camera and 0.1 or 1.0, max_zoom = 4.0, smooth_time = 0.40, max_speed = 120,
        zoom_smooth_time = Tintro.camera_zoom_time, zoom_max_speed = Tintro.camera_zoom_speed })

    if gm.bg then gm.camera:set_bounds_from_tiledmap(gm.bg) end
    if freeze_camera then _apply_debug_world_camera(gm, RT); return end
    gm.camera:set_target(pawn)
    gm.camera:set_zoom(start_zoom)
    if not opts.silent_start then gm.camera:zoom_to(target_zoom) end
    gm.camera:snap_to_target()
end

return M
