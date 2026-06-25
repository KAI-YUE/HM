local M = {
    key           = "rui",
    model_def     = "resources/textures/chara/rui/rui.model3.json",
    motion_group  = "normal",

    model  = { offset_x = 0, offset_y = 0, scale_x = 1, scale_y = 1 },
    params = {
        --- eye settings
        eye_open_l = "ParamEyeLOpen",     eye_open_r = "ParamEyeROpen",
        eye_ball_x = "ParamEyeBallX",     eye_ball_y = "ParamEyeBallY",

        --- brow settings
        brow_l_x = "ParamBrowLX",         brow_r_x = "ParamBrowRX",
        brow_l_y = "ParamBrowLY",         brow_r_y = "ParamBrowRY",
        brow_l_form = "ParamBrowLForm",   brow_r_form = "ParamBrowRForm",

        mouth_open = "ParamMouthOpenY",   mouth_form = "ParamMouthForm",
    },

    hair = {
        detail_amp = 0.06,
        detail_speed = 1.9,
        gust_amp = 0.8,
        wind_speed = 0.8,
        params = {
            { id = "ParamHairSide", scale = 1.00, phase = 0.65, name = "left_side" },
            { id = "Param",         scale = 1.20, phase = 0.35, name = "bang" },
            { id = "Param2",        scale = 1.00, phase = 1.10, name = "right_side" },
            { id = "Param3",        scale = 0.54, phase = 1.75, name = "back" },
        },
    },

    expressions = {
        pathetic  = { id = "Param4", value = 1 },
        empty     = { id = "Param5", value = 1 },
        big_smile = { id = "Param6", value = 1 },
        smug      = { id = "Param7", value = 1 },
    },

}

return M
