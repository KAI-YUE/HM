local C       = require("HMfns.animate.color.color_const")
local CUtils  = require("HMfns.animate.color.color_utils")

local tint_with_alpha = CUtils.tint_with_alpha

local CUI = C.UI
local ttl = tint_with_alpha(CUI.TEXT_LIGHT, 0.9)
local ck  = C.BLACK

local default_s1, default_s2 = 5, 0.27
local Y = true

-- Font scale mental model:
-- render_scale: s1*tz, raster font resolution, in tile_size multiples.
-- font_scale: s2, per-font visual correction applied after sampling.
-- text_scale: out_src, caller/UI size knob.
-- Effective draw scale is text_scale * font_scale * char_scale / tile_size.
-- Keep font_scale in a readable UI range;
-- increase render_scale only if large text looks blurry.
-- y_offset: for font; o_py, s_pw, s_ph: for letter bg card
local function textfx_font(name, s1, s2, y_offset, o_py, s_pw, s_ph, opts)
    local opts,  s1,   s2    = opts or {}, s1 or default_s1,     s2 or default_s2
    local s_pw,  s_ph, o_py  = s_pw or 1.2,          s_ph or 0.62, o_py or 0.5
    local cfg = { name = opts.name or (name .. "_textfx"), file = name,  font_scale = s2,
        y_offset = y_offset or 0,           o_py = o_py,  s_pw = s_pw,      s_ph = s_ph,
        ban_rotation = opts.ban_rotation,   random_case = opts.random_case,
        render_scale = function(tz) return s1*tz end }
    return cfg
end

local font_files = {
    textfx_font("Gsans",        4,          0.26,        0., 0.5, 1.2, 0.45),
    textfx_font("Gsans",        2,          0.53,       0, 0.6, 1.2, 0.45, { name = "Gsans_small_textfx" }),
    textfx_font("HachiMaruPop", 5,          0.19,       0, 0.63, 1., 0.35),
    textfx_font("SAB",          default_s1, default_s2, 0, 0.63, 0.9, 0.4),
    textfx_font("SAB",          3,          0.33,       0, 0.63, 0.9, 0., { name = "SAB_Panel_textfx" } ),
    textfx_font("ZCOOL",        default_s1, default_s2, 0, 0.5, 1, 0.5),
    textfx_font("ZCOOL",         3,          0.33,      0, 0.5, 1, 0.5,  { name = "ZCOOL_Panel_textfx" }),
    textfx_font("ZCOOLXW",      default_s1, default_s2, 0, 0.6, 1.2, 0.45),
    textfx_font("ZCOOLXW",          3,          0.33,   0, 0.6, 1.2, 0.45, { name = "ZCOOLXW_Panel_textfx" } ),

    textfx_font("ransom1",      default_s1, default_s2,  -0.2, 0.5, 1.2, 0.5),
    textfx_font("ransom2",      default_s1, default_s2,  0, 0.44, 1.2, 0.4),
    textfx_font("ransom3",      5,          0.24,        0.2,   0.35, 1, 0.5, { ban_rotation = Y }),
    textfx_font("ransom4",      default_s1, default_s2,  0, 0.48, 1., 0.4),
    textfx_font("ransom5",      4,          0.18,        0.35, 0.35, 1., 0.4, { ban_rotation = Y, random_case = Y }),
}

local card_fonts = {}
for _, font in ipairs(font_files) do card_fonts[#card_fonts + 1] = font.name end

return {
    --- basic settings
    font_files = font_files,        card_fonts = card_fonts,

    --- color settings
    card_paper_color = ck,          card_text_color  = ttl,

    card_font_sampling = {
        ransom_sampling_rate = 0.34,        max_allowable_normal_fonts = 2,
        max_allowable_ransom_fonts = 4,     avoid_successive_ransom = Y,

        normal = {
            Gsans_textfx = 1,
            -- HachiMaruPop_textfx = 0.25,
            -- SAB_textfx = 0.25,
            -- ZCOOL_textfx = 0.3,
            -- ZCOOLXW_textfx = 1,
        },

        ransom = {
            ransom1_textfx = 1,
            ransom2_textfx = 1,
            ransom3_textfx = 1,
            ransom4_textfx = 1,
            ransom5_textfx = 1.5,
        },
    },

}
