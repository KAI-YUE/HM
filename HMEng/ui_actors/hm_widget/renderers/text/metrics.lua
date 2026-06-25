local M = {}

local Y = true

--- Helper: _text_squish | _drawable_metrics_cfg
local function _text_squish(cfg, font)                           return cfg.text_squish or font.squish or 1 end
local function _drawable_metrics_cfg(cfg, drawable, font, scale) return drawable:getWidth() * _text_squish(cfg, font) * scale, drawable:getHeight() * scale * (font.font_hl_scale or 1); end

-----------------------------
--- text metrics
----------------------------------
--- Helper: _runs_metrics
local function _runs_metrics(cfg, runs, font)
    local tw, th = 0, 0
    for _, run in ipairs(runs) do
        local rfont   = run.font_cfg or font
        local rscale  = (cfg.text_scale or cfg.scale or 0.5) * rfont.font_scale / cfg._text_render_tz
        local rw, rh  = _drawable_metrics_cfg(cfg, run.drawable, rfont, rscale)
        tw, th = tw + rw, math.max(th, rh)
    end
    return tw, th
end

---____________________________
--- main: text
---______________________________________
function M.text(cfg, font, scale)
    local runs = cfg.text_drawable_runs
    if not runs then return _drawable_metrics_cfg(cfg, cfg.text_drawable, font, scale) end
    return _runs_metrics(cfg, runs, font)
end

-----------------------------
--- fit, text fit metrics
----------------------------------
function M.fit(cfg, font, scale)
    if cfg.text_reveal ~= Y  then return M.text(cfg, font, scale) end

    local drawable, runs = cfg.text_fit_drawable, cfg.text_fit_drawable_runs
    if not (drawable or runs) then return M.text(cfg, font, scale) end
    if not runs               then return _drawable_metrics_cfg(cfg, drawable, font, scale) end
    return _runs_metrics(cfg, runs, font)
end

function M.fit_scale(cfg, maxw, tw, th, ftw, fth, scale)
    local fit = 1
    if not cfg.text_wrap and maxw and ftw > maxw then
        fit = maxw/ftw
        scale, tw, th, ftw, fth = scale*fit, tw*fit, th*fit, ftw*fit, fth*fit
    end
    return fit, scale, tw, th, ftw, fth
end

return M
