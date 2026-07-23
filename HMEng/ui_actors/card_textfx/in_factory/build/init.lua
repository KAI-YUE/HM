local UTF8   = require("HMfns.utils.format.utf8_utils")
local Common = require("HMEng.ui_actors.card_textfx.in_factory.build.common")

return function (CardTextFx)
-----------------------------
--- build
----------------------------------
--- Helper: _new_build_cache
function CardTextFx:_new_build_cache(key, seed)
    return { key = key, sampling_seed_key = seed, letters = {}, bounds = {}, x = 0, y = 0, line_w = 0, line_h = 0, max_abs_r = 0, now = self.gm._T.real_s }
end

--- Helper: _push_text_chars
function CardTextFx:_push_text_chars(cache, text, font_cfg, scale)
    local index = 1
    for _, char in UTF8.chars(text) do
        if     char == "\n" then self:_new_line(cache)
        elseif char == " "  then self:_push_space(cache, font_cfg, scale)
        else self:_push_letter(cache, char, index, scale); index = index + 1 end
    end
end

--- Helper: _finalize_build_cache
function CardTextFx:_finalize_build_cache(cache)
    self:_assign_idle_flippers(cache)
    self:_guard_letter_jitter(cache)
    cache.w, cache.h = cache.line_w, cache.y + cache.line_h
    self:_finalize_bounds(cache)
    self:_apply_auto_bounds(cache)
end

---____________________________
--- main: build
---______________________________________
function CardTextFx:build(text)
    local cfg = self.config;             if not text or text == "" then  if cfg then cfg.card_textfx_cache = nil end; return end
    cfg.lang = cfg.lang or "en_us"

    local tz,    font_cfg  = self.rcfg.tile_size, cfg.lang.font
    local scale            = (cfg.text_scale or cfg.scale or 1) / tz
    local seed             = Common.sampling_seed_key(self)
    local key,   cache     = Common.cache_key(text, scale, seed, Common.rotation_enabled(cfg)), cfg.card_textfx_cache
    if cache and cache.key == key then self:_apply_auto_bounds(cache); return cache end

    cache = self:_new_build_cache(key, seed)
    cache.text, cache.text_scale, cache.config_scale = text, cfg.text_scale, cfg.scale
    cache.rotation_dir = self:_string_rotation_dir()
    self:_push_text_chars(cache, text, font_cfg, scale)
    self:_finalize_build_cache(cache)

    cfg.card_textfx_cache = cache
    return cache
end

end
