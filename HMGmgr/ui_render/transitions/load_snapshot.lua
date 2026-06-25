local ShaderUtils = require("HMEng.visual.shader_utils")
local TransitionCommon = require("HMGmgr.ui_render.transitions.common")

local send_base_uniforms        = ShaderUtils.send_base_uniforms
local send_sp_uniform           = ShaderUtils.send_sp_uniform
local load_snapshot_mask_domain = TransitionCommon.load_snapshot_mask_domain

local LG = love.graphics
local cw = require("HMfns.animate.color.color_const").WHITE
local N  = false

local M = {}

-----------------------------
--- _draw_load_transition_snapshot
----------------------------------
--- Helper: _draw_load_transition_snapshot
function M._draw_load_transition_snapshot(gm)
    local snap   = gm.load_transition_snapshot
    local canvas = snap and snap.canvas; if not canvas then return false end

    local shader     = snap.fx_mask_shader and gm.t_shaders and gm.t_shaders[snap.fx_mask_shader]
    local old_shader = LG.getShader()
    local w, h       = canvas:getWidth(), canvas:getHeight()
    local fx_mask    = snap.fx_mask or 0

    LG.push()
    LG.origin()
    LG.setColor(cw)
    if shader and fx_mask > 0.001 then
        local tex_details, image_details, wipe_rect = load_snapshot_mask_domain(gm, snap, w, h)
        send_base_uniforms(shader, {
            fx_mask       = fx_mask,
            time          = gm._T and gm._T.real_s or 0,
            tex_details   = tex_details,
            image_details = image_details,
            shadow        = N,
        })
        send_sp_uniform(shader, "fx_mask_dir", snap.fx_mask_dir or 0)
        send_sp_uniform(shader, "fx_mask_seed", snap.fx_mask_seed or 0)
        send_sp_uniform(shader, "wipe_rect", wipe_rect)
        send_sp_uniform(shader, "generic", { 0, gm._T and gm._T.real_s or 0, snap.generic_id or 0 })
        LG.setShader(shader)
    end
    LG.draw(canvas, 0, 0)
    LG.setShader(old_shader)
    LG.pop()
    return true
end

return M
