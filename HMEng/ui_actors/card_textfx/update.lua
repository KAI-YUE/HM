return function (CardTextFx)
---____________________________
--- main: update
---______________________________________
function CardTextFx:update(dt)
    local cfg = self.config;        if not cfg then return end
    local text, cache = tostring(cfg.text or ""), cfg.card_textfx_cache
    if cache and cache.text == text and cache.text_scale == cfg.text_scale and cache.config_scale == cfg.scale then return end
    self:build(text)
end

end
