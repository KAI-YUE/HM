local Layout       = require("HMEng.ui_actors.card_textfx.in_factory.layout")
local PaintRect    = require("HMEng.ui_actors.card_textfx.in_factory.paint.textfx_bg_paint_rect")
local CUtils       = require("HMfns.animate.color.color_utils")
local C            = require("HMfns.animate.color.color_const")
local Parallax     = require("HMEng.actors.actor.parallax")

local tint_with_alpha = CUtils.tint_with_alpha
local draw_paint_rect = PaintRect.draw_paint_rect

local abs = math.abs

local ck       = C.BLACK
local tcshadow = tint_with_alpha(ck, 0.3)
local Y, N     = true, false

local Background = {}

-----------------------------
--- draw letter bg
----------------------------------
--- Helper: _letter_shadow_offset, actor-consistent letter parallax
local function _letter_shadow_offset(ctx, letter, box, draw)
    local VT, room  = ctx.VT, ctx._room;     if not VT or not room then return 0, 0 end

    local sx,  px   = (draw and draw.scale_x) or 1, (draw and draw.x) or 0
    local center_x  = px + 0.5*letter.paper_w + sx*(box.x + 0.5*box.w - 0.5*letter.paper_w)
    local w,   sp   = abs(sx)*box.w, ctx.shadow_parallax
    local spx       = Parallax.shadow_x(ctx.gm, room.T, { x = VT.x + center_x - 0.5*w, w = w })

    local rcfg = ctx.rcfg
    return -spx, -1/rcfg.tile_size
end

--- Helper: letter paper cfg
local function _letter_paper_cfg(ctx, letter)
    if letter and letter.letter_paper == N then return end
    local cfg   = ctx.config or {}
    local paper = (letter and letter.letter_paper) or cfg.letter_paper;     if paper == N then return end
    local out   = {}
    if paper ~= Y and paper ~= nil then for k, v in pairs(paper) do out[k] = v end end
    if cfg.disable_letter_bg_shader ~= Y and out.disable_shader ~= Y then
        out.shader, out.fx_mask_ref = "_2_edge_feather", out.fx_mask_ref or "fx_mask"
    else
        out.shader = nil
    end
    return out
end

---____________________________
--- main: draw_letter_bg
---______________________________________
function Background.draw_letter_bg(ctx, letter, shadow, draw)
    local pw,   ph    = letter.paper_w, letter.paper_h
    local s_pw, s_ph  = letter.letter_s_pw or 1.2, letter.letter_s_ph
    local o_px        = letter.letter_bg_o_px or 0
    local o_py, dist  = letter.letter_bg_o_py or 0.5, 0.12
    local paper_cfg   = _letter_paper_cfg(ctx, letter);     if not paper_cfg then return end

    local box         = { x = o_px, y = o_py, w = s_pw*pw, h = s_ph*ph }
    local paper_color = (paper_cfg and paper_cfg.color) or letter.paper_color or ck

    if not shadow then return draw_paint_rect(ctx, box, paper_cfg, N, paper_color) end

    local sx, sy = _letter_shadow_offset(ctx, letter, box, draw)  -- shadow and ground_truth
    draw_paint_rect(ctx, { x = box.x + dist*sx, y = box.y + dist*sy, w = box.w, h = box.h }, paper_cfg, N, tcshadow)
    if shadow == "only" then return end
    draw_paint_rect(ctx, box, paper_cfg, N, paper_color)
end

-----------------------------
--- draw text (string) bg
----------------------------------
function Background.draw_text_bg(ctx, cache, x, y, opts)
    opts = opts or {}
    if ctx.config and ctx.config.paint_bg == N then return end
    local b    = cache.bounds or { x = 0, y = 0, w = cache.w, h = cache.h }
    local bg   = Layout.text_bg_cfg(ctx);       if not bg then return end
    local box  = Layout.text_bg_box(ctx, cache, { x = x + b.x, y = y + b.y, w = b.w, h = b.h });     if not box then return end

    bg.feather_px = 0.08

    PaintRect.draw_bleed_layer(ctx, box, bg, nil, opts)
end

return Background
