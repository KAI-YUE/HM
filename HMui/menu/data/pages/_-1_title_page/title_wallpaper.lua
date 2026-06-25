local C = require("HMfns.animate.color.color_const")

local M = {}

-------------------------------------------------
--- Wallpaper args
-------------------------------------------------
function M.wallpaper_args()
    return {
        --- basics 
        type      = "title_wallpaper",         atlas_key = "title_map_dummy",
        quad_key  = "title",                   shader    = "toon_fog",

        shader_opts = {
            field_uniform       = "toon_fog",
            blur_radius         = 3.0,     -- max blur radius in pixels
            speed_factor        = 0.6,     -- full blur cycle speed
            blur_clean_stage    = 0.5,     -- phase fraction spent mostly clean
            blur_turning_point  = 0.6,     -- phase where blur starts ramping hard
            blur_peak_point     = 0.78,    -- phase where max blur starts falling back
            blur_clean_amount   = 0.4,     -- blur amount at the end of clean stage
            blur_increase_speed = 4.5,     -- higher means faster early blur buildup
            blur_fall_slowdown  = 2.2,     -- higher keeps the reverse fall near peak longer
            send = {
                { name = "fog_alpha",        val = 1 },           -- overall fog opacity
                { name = "fog_color",        val = C.SPGRAY },    -- warm fog tint matched to wallpaper whites
                { name = "fog_perspective",  val = 0.52 },        -- 0 = flat screen fog, 1 = strongest plane warp
                { name = "fog_vanish_x",     val = -0.08 },       -- far-plane horizontal lean; negative pulls top-left
                { name = "fog_far_scale",    val = 0.2 },         -- far/top cloud scale; lower makes distant fog smaller
                { name = "fog_near_scale",   val = 1.55 },        -- near/bottom cloud scale; higher makes close fog broader
                { name = "fog_depth_curve",  val = 1.45 },        -- higher extends the far/small look downward
                { name = "fog_far_alpha",    val = 0.5 },         -- far/top opacity multiplier before edge fade
                { name = "fog_volume_alpha", val = 0.78 },        -- volume layer opacity before title fog alpha
                { name = "fog_volume_depth", val = 0.46 },        -- parallax spread between front/back fog slices
                { name = "fog_volume_scale", val = 2.05 },        -- 3d noise scale; higher makes smaller cloud pockets
                { name = "fog_volume_light", val = 0.72 },        -- side-light contrast inside volume fog
                { name = "fog_volume_shadow", val = 0.24 },       -- soft dimming under denser volume pockets
            },
        },
        drift = {
            -------------------------------------------------
            --- Drift knobs
            -------------------------------------------------
            mode           = "scan", -- scan = hop focus across a grid instead of free drifting
            amount         = 0.18,   -- max screen-space travel from the centered wallpaper position
            drift          = 0.35,   -- small continuous wobble layered on top of the scan target
            speed          = 0.15,   -- smoothing speed while moving toward the next target
            scale          = 1.1,    -- wallpaper zoom used to hide edges while panning
            scan_cols      = 9,      -- horizontal scan grid density
            scan_rows      = 9,      -- vertical scan grid density
            scan_step_time = 3,      -- seconds spent on each scan target before advancing
        },
    }
end

return M
