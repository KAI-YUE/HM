local DebugFlags = require("HMGmgr.data.global.flags.debug_flags")

local floor = math.floor

local _map_tile_size = 1.4 

local Y, N = true, false

return function (self)
-----------------------------
--- Map / terrain cfg
----------------------------------
    local n_rows = (self.Fcfg and self.Fcfg.n_rows) or 10

    local M_s,    M_base  = 2,                 n_rows
    local M_rows, M_cols  = floor(M_s*M_base), floor(1.5*M_s*M_base)
    local M_w,    M_h     = _map_tile_size,    _map_tile_size

    local tile_shader = DebugFlags.fps.enable_tile_shader and DebugFlags.fps.tile_shader

    --- the background map
    self.Mcfg  = {  n_rows = M_rows,  n_cols      = M_cols,             tile_w       = M_w,         tile_h = M_h,
        atlas_key     = "grass",      tile_shader = tile_shader,        random_tiles = N,
        tile_overdraw = 0.05,         fblend_world_phase_scale = 0.1,   tile_shader_uniforms_once = Y,

        tile_shader_opts = { edge_pad = 2,    send   = { { name = "input_scale",  val =  1 } } },
        map_growth       = { top      = 0.20, bottom = 0.4, left = 0.15, right = 0.15 },
    }

    --- grass decorator
    self.Dcfg  = { atlas_key  = "grass_dec",  tile_h = 0.55*M_h,  spawn_pr     = 0.22,   cen2side_k = 0.15,
        throw_k = 0.1, throw_bias_qs = 0.2,   scale  = 0.6,       num_groups   = 3 }

    --- terrain decorators
    self.TPcfg = { atlas_key  = "terrain",     tile_h   = 0.72*M_h,  tile_w    = 0.72*M_w,    spawn_pr = 0.,
        anim = Y, model_key   = "white_birch", static   = Y, 
        scale = 1.5,  seed    = "terrain",     can_drag = N,         can_hover = Y,           can_click  = Y,
        anim_debug_spawn = { enabled = N, row = 10, col = 15, seed = "anim_terrain_debug" },
        }
end
