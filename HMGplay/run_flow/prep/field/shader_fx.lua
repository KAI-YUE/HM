local ShaderFX      = require("HMEng.actors.shader_fx")
local IntroTimeline = require("HMfns.animate.start.intro_timeline")

local Y, N = true, false

local M = {}

-----------------------------
--- place_shader_fx
----------------------------------
--- Helper: enqueue ease | enqueue after
local function _enqueue_ease(EM, ref_table, ref_value, ease_to, delay, ease) EM:enqueue_event({ queue = "shader_fx", trigger = "ease", ease = ease or "sine", blockable = N, ref_table = ref_table, ref_value = ref_value, ease_to = ease_to, delay = delay }) end
local function _enqueue_after(EM, delay, func) EM:enqueue_event({ queue = "shader_fx", trigger = "after", blockable = N, delay = delay, func = func }) end

--- Helper: resolve field cloud fx layout
local function _resolve_field_cloud_fx_layout(gm)
    local field, pawn = gm.field, gm.field_pawn;            if not field then return end

    local fw, fh           = field.cell_w, field.cell_h
    local fT, pT           = field.T,      pawn and pawn.T
    local field_center     = { x = 0.5*fT.w, y = 0.5*fT.h }
    local pawn_center      = field_center
    if pT then pawn_center = { x = (pT.x - fT.x) + 0.5*pT.w, y = (pT.y - fT.y) + 0.5 * pT.h } end

    local bottom_offset  = gm.Fcfg.proj.bottom_offset
    local offset_y       = 4*bottom_offset

    local anchor = { x = 0.5*(pawn_center.x + field_center.x), y = 0.5*(pawn_center.y + field_center.y) }
    local offset = { x = anchor.x - 0.2*fw, y = anchor.y - 1.5*fh + offset_y }

    return { w = fw, h = 0.5*fh, offset = offset, field = field }
end

--- Helper: place field cloud-like fx
local function _place_field_cloud_like_fx(gm, args)
    local EM, timeline  = gm.E_MANAGER, IntroTimeline.field
    local layout        = _resolve_field_cloud_fx_layout(gm); if not layout then return end

    local fx = ShaderFX(gm, 0, 0, layout.w, layout.h)
    fx.shader_code, fx.draw_alpha = args.shader_code, args.draw_alpha or 0

    fx:set_render_layer(args.render_layer or "above_field")
    fx:set_role({ role_type = "Minor", major = layout.field, offset = layout.offset, draw_major = layout.field })

    local reveal_dur   = args.reveal_dur  or timeline.cloud_reveal or 0
    local start_delay  = args.start_delay or timeline.pawn_reveal

    _enqueue_after(EM, start_delay, function()
        if fx.REMOVED then return Y end
        _enqueue_ease(EM, fx, "draw_alpha", 1, reveal_dur, "lerp")
        if args.motion then fx:start_event_motion(args.motion) end
        return Y
    end)

    fx.parent = layout.field
    return fx
end

function M.place_shader_fx(gm, opts)
    opts = opts or {};                                      if opts.silent_start then return end
    local EM, Tcloud = gm.E_MANAGER, IntroTimeline.cloud
    _enqueue_after(EM, Tcloud.field_spawn, function() gm.field_cloud_fx = _place_field_cloud_like_fx(gm, { shader_code = "vcloud", motion = IntroTimeline.cloud }); return Y end )
end

return M
