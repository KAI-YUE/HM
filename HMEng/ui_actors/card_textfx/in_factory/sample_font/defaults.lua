local RNG = require("HMfns.utils.math.rng_utils")

local Y = true

local weighted_refs = RNG.weighted_refs

return function (CardTextFx)
function CardTextFx:_font_fallbacks()
    local sampling, fonts, seen = self:_font_sampling_cfg(), {}, {}
    local function add(font)
        if seen[font] then return end
        seen[font] = Y
        fonts[#fonts + 1] = font
    end
    for _, font in ipairs(weighted_refs(sampling.normal)) do add(font) end
    for _, font in ipairs(weighted_refs(sampling.ransom)) do add(font) end
    if #fonts > 0 then return fonts end
    return self:_default_fonts()
end

function CardTextFx:_default_fonts()
    local gf, cfg = self.gm.g_fonts, self.config
    if not gf then return { cfg.lang.font } end
    local data = self:_data_fonts()
    local sampling, fonts = data.card_font_sampling, {}
    for _, group in ipairs({ sampling and sampling.normal, sampling and sampling.ransom }) do
        for _, font in ipairs(weighted_refs(group)) do fonts[#fonts + 1] = font end
    end
    if #fonts > 0 then return fonts end
    return data.card_fonts
end

-----------------------------
--- colors: default colors
----------------------------------
--- Helper: _default_textfx_colors
function CardTextFx:_default_textfx_colors()
    local cfg = self.config or {}
    local data = self:_data_fonts()
    return cfg.card_paper_color or data.card_paper_color, cfg.card_text_color or data.card_text_color
end
end
