local Common = require("HMEng.ui_actors.card_textfx.in_factory.build.common")
local LG     = love.graphics

local max, min = math.max, math.min

local _letter_space = 0.03

local Y, N = true, false

return function (CardTextFx)
-----------------------------
--- letter sampling
----------------------------------
--- Helper: _font_fallback_match
function CardTextFx:_font_fallback_match(fc_ref, char)
    local font_cfg  = self:_resolve_font_cfg(fc_ref)
    local font      = self:_font_cfg_font(font_cfg)
    if self:_font_can_draw(font, char) then return font_cfg, font end
end

--- Helper: _string_rotation_dir
function CardTextFx:_string_rotation_dir()
    local cfg = self.config or {};          if not Common.rotation_enabled(cfg) then return 0 end
    local dir = cfg.card_rotation_dir;      if dir then return dir end
    return Common.sampling_unit(self, "rotation_dir") < 0.5 and -1 or 1
end

--- Helper: _letter_rotation
function CardTextFx:_letter_rotation(cache, index)
    if cache.rotation_dir == 0 then return 0 end
    local dir, sample_rate  = cache.rotation_dir or 1, 0.62
    local rot_max, opp_max  = 0.1, 0.1

    sample_rate = Common.clamp(sample_rate, 0, 1)
    local sign = Common.cache_sampling_unit(cache, index, "rot_sign") < sample_rate and dir or -dir
    local mag  = rot_max * Common.cache_sampling_unit(cache, index, "rot_mag")
    if sign ~= dir then mag = min(mag, opp_max) end
    return sign * mag
end

--- Helper: _transform_letter_rules
function CardTextFx:_transform_letter_rules(char, font, font_cfg, glyph_rule, cache, index)
    local y_offset = 0
    if font_cfg.random_case then
        local case_char = Common.random_case_char(char, Common.cache_sampling_unit(cache, index, "random_case"))
        if self:_font_can_draw(font, case_char) then char = case_char end
    end
    if type(glyph_rule) == "table" then y_offset = glyph_rule.y_offset or 0 end
    return char, y_offset
end

--- Helper: _letter_style_cfg
function CardTextFx:_letter_style_cfg(char, cache, index, defaults)
    local fn = self.config and self.config.letter_style_fn
    if type(fn) ~= "function" then return defaults end

    local style = fn(char, {
        cache = cache,
        config = self.config,
        index = index,
        unit = function(salt) return Common.cache_sampling_unit(cache, index, salt) end,
    }) or {}
    if type(style) ~= "table" then return defaults end

    for k, v in pairs(style) do defaults[k] = v end
    return defaults
end

--- Helper: _letter_font_sample
function CardTextFx:_letter_font_sample(cache, char, index)
    local cfg                   = self.config
    local seed,     fonts       = Common.sampling_seed_number(self, 17*index, 5), self:_font_fallbacks()
    local fallback              = cfg.lang and cfg.lang.font
    local font_ref, glyph_rule  = self:_sample_font_for_char(char, seed, cache)
    local font_cfg              = self:_resolve_font_cfg(font_ref) or fallback
    local font                  = self:_font_cfg_font(font_cfg)

    if not self:_font_can_draw(font, char) or (self:_font_bans_char(font_ref, char) and not glyph_rule) then
        font_cfg, font = nil, nil
        for _, fc_ref in ipairs(fonts) do
            if self:_font_bans_char(fc_ref, char) then goto continue end
            font_cfg, font = self:_font_fallback_match(fc_ref, char)
            if font then font_ref = fc_ref; break end
            ::continue::
        end
    end
    if not self:_font_can_draw(font, char) then font_ref, font_cfg, font = nil, fallback, self:_font_cfg_font(fallback) end
    if not font then return end

    return {
        font_ref       = font_ref,
        font_cfg       = font_cfg,
        font           = font,
        glyph_rule     = glyph_rule,
        sampled_ransom = self:_font_ref_is_ransom(font_ref),
    }
end

-----------------------------
--- letter assembly
----------------------------------
--- Helper: _letter_visuals
function CardTextFx:_letter_visuals(char, font, font_cfg, cache, index, base_scale)
    local cfg                      = self.config
    local char_scale               = (cfg.disable_ransom_scale == Y) and 1 or 0.88 + 0.24*Common.cache_sampling_unit(cache, index, "char_scale")
    local squish,       pad        = font_cfg.squish or 1, Common.xy_pair(-0.1, -0.1)
    local letter_scale, hl_scale   = base_scale*(font_cfg.font_scale or 1), font_cfg.font_hl_scale or 1
    local w,            h          = font:getWidth(char)*squish*letter_scale*char_scale, font:getHeight()*letter_scale*char_scale*hl_scale
    local paper_color,  text_color = self:_default_textfx_colors()
    local style                    = self:_letter_style_cfg(char, cache, index, { paper_color = paper_color, text_color = text_color })
    local o_px, o_py               = font_cfg.o_px or 0,   font_cfg.o_py or 0.5
    local s_pw, s_ph               = font_cfg.s_pw or 1.2, font_cfg.s_ph or 0.62

    o_px = style.letter_bg_o_px == nil and o_px or style.letter_bg_o_px
    o_py = style.letter_bg_o_py == nil and o_py or style.letter_bg_o_py
    s_pw = style.letter_s_pw    == nil and s_pw or style.letter_s_pw
    s_ph = style.letter_s_ph    == nil and s_ph or style.letter_s_ph

    return {
        text             = LG.newText(font, char),
        w                = w,
        h                = h,
        draw_sx          = squish*letter_scale*char_scale,
        draw_sy          = letter_scale*char_scale*hl_scale,
        paper_w          = w + 2*pad.x,
        paper_h          = h + 2*pad.y,
        paper_pad        = pad,
        paper_color      = style.paper_color,
        text_color       = style.text_color,
        letter_bg_o_px   = o_px,
        letter_bg_o_py   = o_py,
        letter_s_pw      = s_pw,
        letter_s_ph      = s_ph,
        letter_paper     = style.letter_paper,
        letter_style_key = style.letter_style_key,
    }
end

--- Helper: _letter_motion
function CardTextFx:_letter_motion(cache, index, font_cfg, rule_y_offset)
    local cfg = self.config
    local r   = (font_cfg.ban_rotation or not Common.rotation_enabled(cfg)) and 0 or self:_letter_rotation(cache, index)
    local base_oy, jitter_oy = (font_cfg.y_offset or 0) + rule_y_offset, 0.005 * (2*Common.cache_sampling_unit(cache, index, "jitter_oy") - 1)
    local ox, oy = 0.025 * (2*Common.cache_sampling_unit(cache, index, "ox") - 1), base_oy + jitter_oy

    if cfg.disable_ransom_offset == Y then base_oy, jitter_oy, ox, oy = 0, 0, 0, 0 end

    return {
        r          = r,
        ox         = ox,
        oy         = oy,
        base_oy    = base_oy,
        jitter_oy  = jitter_oy,
        delay      = (index - 1)*(0.05 + 0.1*Common.cache_sampling_unit(cache, index, "delay")),
        idle_phase = Common.cache_sampling_unit(cache, index, "idle_phase"),
        next_idle  = cache.now + 3.5*Common.cache_sampling_unit(cache, index, "next_idle"),
    }
end

--- Helper: _new_letter
function CardTextFx:_new_letter(cache, char, font_cfg, visuals, motion)
    return {
        char        = char,             text  = visuals.text,   font_cfg    = font_cfg,        w            = visuals.w,     h = visuals.h,
        draw_sx     = visuals.draw_sx,  draw_sy  = visuals.draw_sy, x        = cache.x,         y            = cache.y,
        paper_w     = visuals.paper_w,  paper_h  = visuals.paper_h, paper_pad = visuals.paper_pad,
        r           = motion.r,         ox       = motion.ox,    oy          = motion.oy,       paper_color  = visuals.paper_color,
        text_color  = visuals.text_color, delay  = motion.delay, idle_phase  = motion.idle_phase, idle_start = nil,
        next_idle   = motion.next_idle, letter_bg_o_px = visuals.letter_bg_o_px, letter_bg_o_py = visuals.letter_bg_o_py,
        letter_s_pw = visuals.letter_s_pw, letter_s_ph = visuals.letter_s_ph,
        base_oy     = motion.base_oy,   jitter_oy = motion.jitter_oy, letter_paper = visuals.letter_paper,
        letter_style_key = visuals.letter_style_key,
    }
end

-----------------------------
--- layout push
----------------------------------
--- Helper: _push_letter
function CardTextFx:_push_letter(cache, char, index, base_scale)
    local sample = self:_letter_font_sample(cache, char, index)
    if not sample then cache.font_sampling_prev_is_ransom = N; return end

    local rule_y_offset
    char, rule_y_offset = self:_transform_letter_rules(char, sample.font, sample.font_cfg, sample.glyph_rule, cache, index)

    local visuals = self:_letter_visuals(char, sample.font, sample.font_cfg, cache, index, base_scale)
    local motion  = self:_letter_motion(cache, index, sample.font_cfg, rule_y_offset)
    local letter  = self:_new_letter(cache, char, sample.font_cfg, visuals, motion)

    cache.letters[#cache.letters + 1] = letter
    cache.font_sampling_prev_is_ransom = sample.sampled_ransom
    self:_include_letter_bounds(cache, letter)

    cache.x = cache.x + visuals.w + 0.025
    cache.line_w, cache.line_h = max(cache.line_w, cache.x), max(cache.line_h, visuals.h)
end

--- Helper: _push_space
function CardTextFx:_push_space(cache, font_cfg, scale)
    local font        = self:_font_cfg_font(font_cfg)
    local font_scale  = (font_cfg and font_cfg.font_scale) or 1
    cache.x = cache.x + (font and font:getWidth(" ") or 8) * scale * font_scale + _letter_space
end

--- Helper: _new_line
function CardTextFx:_new_line(cache) cache.x, cache.line_h, cache.y  = 0, 0, cache.y + cache.line_h  end

end
