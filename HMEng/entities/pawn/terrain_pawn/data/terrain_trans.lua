local default_shader = "plain"

local Y, N = true, false

return {
    rock1  = { s_min = 0.55, s_max = 0.62, spawn_pr = 1.0, flip_x = Y, shader = default_shader },
    rock2  = { s_min = 0.92, s_max = 1.2,  spawn_pr = 1,   flip_x = Y, shader = default_shader },
    rock5  = { s_min = 0.62, s_max = 0.80, spawn_pr = 1,   flip_x = Y, shader = default_shader },
    rock6  = { s_min = 0.82, s_max = 0.85, spawn_pr = 1,   flip_x = Y, shader = default_shader },
    rock7  = { s_min = 1.3,  s_max = 1.42, spawn_pr = 1,   flip_x = N, shader = default_shader },
    rock8  = { s_min = 0.92, s_max = 1.2,  spawn_pr = 1.0, flip_x = Y, shader = default_shader },

    tree1  = { s_min = 0.7, s_max = 0.75, spawn_pr = 1, flip_x = N, shader = default_shader },
    tree2  = { s_min = 0.7, s_max = 0.75, spawn_pr = 1, flip_x = Y, shader = default_shader },
    tree3  = { s_min = 1.5, s_max = 2,    spawn_pr = 2, flip_x = Y, shader = default_shader },
    tree4  = { s_min = 1.5, s_max = 2,    spawn_pr = 2, flip_x = Y, shader = default_shader },
    tree5  = { s_min = 1.5, s_max = 2,    spawn_pr = 2, flip_x = Y, shader = default_shader },
    tree6  = { s_min = 1.5, s_max = 2,    spawn_pr = 2, flip_x = Y, shader = default_shader },
    tree7  = { s_min = 1.5, s_max = 2,    spawn_pr = 2, flip_x = Y, shader = default_shader },
    tree8  = { s_min = 1.4, s_max = 1.5,  spawn_pr = 2, flip_x = Y, shader = default_shader },
}
