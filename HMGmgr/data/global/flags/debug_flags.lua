local Y, N = true, false

return {
-----------------------------
--- FPS debug switches
----------------------------------
    fps = {
        --- Camera
        freeze_camera_world_view = N,
        world_camera_zoom        = 0.4,

        --- Pawn toddle
        disable_pawn_toddle      = N,

        --- Pawn auto-move
        hover_pawn_move_key      = "k",
        hover_pawn_move_interval = 0.18,
        hover_pawn_move_steps    = 100,
        hover_pawn_move          = Y,

        --- Pawn scale
        force_fixed_pawn_scale   = N,
        pawn_scale_snap          = 0.005,

        --- Render skips
        skip_tiled_map_render    = N,
        skip_field_card_render   = N,

        --- Tiled map shader
        enable_tile_shader       = Y,
        tile_shader              = "fblend",
    },
}
