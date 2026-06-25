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
    local zcfg = gm.gridzone and gm.gridzone._focus_projection_cfg and gm.gridzone:_focus_projection_cfg()
    local anchor_camera = zcfg and zcfg.enabled ~= false and zcfg.camera_anchor ~= false
    gm.camera:set_target(pawn)
    if anchor_camera then local cell = { row = zcfg.debug_anchor_row or (pawn.cell and pawn.cell.row), col = zcfg.debug_anchor_col or (pawn.cell and pawn.cell.col) }; if gm.gridzone and cell.row and cell.col then gm.gridzone:set_field_view_anchor(cell.row, cell.col) end
    elseif gm.camera.clear_focus_point then gm.camera:clear_focus_point() end
    gm.camera:set_zoom(start_zoom)
    gm.camera:snap_to_target()
    if not opts.silent_start then gm.camera:zoom_to(target_zoom) end
    if zcfg and zcfg.enabled ~= false and gm.gridzone.mark_focus_projection_dirty then gm.gridzone:mark_focus_projection_dirty(); if gm.gridzone.refresh_focus_projection_state then gm.gridzone:refresh_focus_projection_state() end; gm.gridzone:align_cards({ dt = 0 }) end
end

return M
