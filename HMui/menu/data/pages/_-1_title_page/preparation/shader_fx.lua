local ShaderFX = require("HMEng.actors.shader_fx")
local Layout   = require("HMui.menu.data.pages._-1_title_page.preparation.layout")

local Y = true

local M = {}

local _key = "title_prompt_square_fx"

--- Helper: remove_current
local function remove_current(gm)
    local fx = gm and gm[_key];       if not fx then return end
    if not fx.REMOVED then fx:remove() end
    gm[_key] = nil
end

--- Helper: prompt_square_args
local function prompt_square_args()
    local cfg = Layout.shader_fx and Layout.shader_fx.prompt_squares
    return cfg, cfg and cfg.T
end

----------------------------------------------
--- main: start
----------------------------------------------
function M.start(gm)
    local cfg, T = prompt_square_args();       if not (gm and cfg and T and gm.R and gm.R.SHADERFX and gm._room_r) then return end
    if not (cfg.shader and gm.t_shaders and gm.t_shaders[cfg.shader]) then return end

    remove_current(gm)

    local fx = ShaderFX(gm, 0, 0, T.w, T.h)
    fx.shader_code, fx.draw_alpha, fx.shader_uniforms = cfg.shader, cfg.alpha or 1, cfg.uniforms
    fx:set_render_layer(cfg.layer or "above_field")
    fx:set_role({ role_type = "Minor", major = gm._room_r, offset = { x = T.x or 0, y = T.y or 0 }, draw_major = gm._room_r })

    gm[_key] = fx
    return Y
end

----------------------------------------------
--- main: stop
----------------------------------------------
function M.stop(gm) remove_current(gm); return Y end

return M
