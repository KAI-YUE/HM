local Y, N = true, false
local floor, min, max = math.floor, math.min, math.max

--- Helper: char rule value
local function _char_rule_value(list, char)
    if not list or not char then return end
    if list[char] ~= nil then return list[char] end
    for _, v in ipairs(list) do if v == char then return Y end end
end

return function (CardTextFx)
function CardTextFx:_font_can_draw(font, char)
    if not font or not char then return N end
    if not font.hasGlyphs then return Y end
    local ok, has = pcall(font.hasGlyphs, font, char)
    return ok and has
end

function CardTextFx:_resolve_font_cfg(font_cfg)
    if type(font_cfg) == "number" then return self.gm.g_fonts and self.gm.g_fonts[font_cfg] end
    if type(font_cfg) == "string" then return self.gm.g_fonts and self.gm.g_fonts[font_cfg] end
    return font_cfg
end

function CardTextFx:_font_cfg_font(font_cfg) font_cfg = self:_resolve_font_cfg(font_cfg); return font_cfg and font_cfg.FONT end

function CardTextFx:_font_ban()
    local cfg,    data   = self.config or {}, self:_data_fonts()
    local gm_ban = self.gm.font_glyph_ban
    local global_ban = gm_ban and (gm_ban.global or gm_ban)
    return cfg.font_ban or cfg.card_font_ban or cfg.ransom_font_ban
        or cfg.card_font_abandon or cfg.ransom_font_abandon or cfg.font_abandon
        or global_ban or data.font_ban or data.card_font_abandon or {}
end

--- Helper: font_bans_char | font_char_rule
function CardTextFx:_font_char_rule(font_ref, char)
    local ban       = self:_font_ban()
    local font_cfg  = self:_resolve_font_cfg(font_ref)
    local list      = (font_cfg and font_cfg.glyph_ban) or (ban and ban[font_ref])
    return _char_rule_value(list, char)
end
function CardTextFx:_font_bans_char(font_ref, char) return self:_font_char_rule(font_ref, char) ~= nil end

function CardTextFx:_font_sampling_cfg()
    local cfg = self.config or {}
    if cfg.card_font_sampling   then return cfg.card_font_sampling end
    if cfg.ransom_font_sampling then return cfg.ransom_font_sampling end
    if cfg.card_fonts or cfg.ransom_fonts then return {} end
    return self:_data_fonts().card_font_sampling or {}
end

-----------------------------
--- font_ref_is_ransom
----------------------------------
function CardTextFx:_font_ref_is_ransom(font_ref)
    local sampling = self:_font_sampling_cfg()
    if sampling.ransom and sampling.ransom[font_ref] then return Y end
    local data_sampling = self:_data_fonts().card_font_sampling or {}
    if data_sampling.ransom and data_sampling.ransom[font_ref] then return Y end

    local fonts = self.config.ransom_fonts
    if type(fonts) ~= "table" then return N end
    for _, ref in ipairs(fonts) do if ref == font_ref then return Y end end
    return N
end
end
