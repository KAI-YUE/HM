local Y, N = true, false
local sway_shaders = { "dr_sway", "grass_sway", "paper_sway", "xy_sway" }
-- local sway_shaders = { "xy_sway" }

return {
    grass1  = { s_min = 0.85, s_max = 1.15, r_max = 0.5,  spawn_pr = 0.70, flip_x = Y, flip_y = Y,  shader_set = sway_shaders },
    grass2  = { s_min = 0.85, s_max = 1.15, r_max = 0.5,  spawn_pr = 0.70, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
    grass3  = { s_min = 0.85, s_max = 1.15, r_max = 0.75, spawn_pr = 0.70, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
    grass4  = { s_min = 0.85, s_max = 1.15, r_max = 0.5,  spawn_pr = 0.70, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
    grass5  = { s_min = 0.68, s_max = 0.62, r_max = 0.25, spawn_pr = 0.00, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
    grass6  = { s_min = 1.02, s_max = 1.18, r_max = 0.75, spawn_pr = 0.7,  flip_x = Y, flip_y = Y,  shader_set = sway_shaders },
    grass7  = { s_min = 0.85, s_max = 0.8,  r_max = 0.75, spawn_pr = 1.00, flip_x = Y, flip_y = Y,  shader_set = sway_shaders },
    grass8  = { s_min = 0.85, s_max = 1.15, r_max = 0.75, spawn_pr = 1.00, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
    grass9  = { s_min = 0.85, s_max = 1.15, r_max = 0.75, spawn_pr = 1.00, flip_x = Y, flip_y = Y,  shader_set = sway_shaders },
    grass10 = { s_min = 0.85, s_max = 1.15, r_max = 0.75, spawn_pr = 1.00, flip_x = Y, flip_y = Y,  shader_set = sway_shaders },
    grass11 = { s_min = 0.94, s_max = 0.7,  r_max = 0.45, spawn_pr = 0.80, flip_x = Y, flip_y = N,  shader_set = sway_shaders },
}
