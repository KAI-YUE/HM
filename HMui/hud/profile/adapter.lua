local HMWidget = require("HMEng.ui_actors.hm_widget")
local Render   = require("HMfns.systems.render")
local Layout   = require("HMui.hud.cfg_data.layout")
local Common   = require("HMui.hud.common")
local Mask     = require("HMui.hud.profile.mask")
local Canvas   = require("HMui.hud.profile.canvas")
local LG       = love.graphics

local Y, N = true, false

local M = {}

local LAYER = Layout.layer
local push_draw_trans = Render.push_actor_draw_transform
local _mask_shader

-----------------------------
--- shader
-----------------------------
local function _shader()
    if _mask_shader then return _mask_shader end
    _mask_shader = LG.newShader([[
        extern Image mask_tex;
        extern vec4 canvas_rect;
        extern vec4 mask_rect;
        extern vec4 mask_uv_rect;
        extern vec4 ext_rect;
        extern vec4 ext_uv_rect;
        extern vec2 canvas_px;
        extern vec2 mask_texel;
        extern number canvas_scale;
        extern number alpha_cutoff;
        extern number edge_feather;
        extern number edge_px;
        extern number ext_enabled;

        number mask_alpha_at(vec2 uv, vec4 uv_rect)
        {
            if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
            vec2 atlas_uv = uv_rect.xy + uv * uv_rect.zw;
            return Texel(mask_tex, atlas_uv).a;
        }

        number mask_sample(vec2 uv, vec4 uv_rect)
        {
            vec2 d = max(edge_px, 0.0) * mask_texel / max(uv_rect.zw, vec2(0.0001));
            number a = mask_alpha_at(uv, uv_rect) * 0.36;
            a += mask_alpha_at(uv + vec2( d.x, 0.0), uv_rect) * 0.16;
            a += mask_alpha_at(uv + vec2(-d.x, 0.0), uv_rect) * 0.16;
            a += mask_alpha_at(uv + vec2(0.0,  d.y), uv_rect) * 0.16;
            a += mask_alpha_at(uv + vec2(0.0, -d.y), uv_rect) * 0.16;
            return a;
        }

        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
        {
            vec4 src = Texel(tex, uv) * color;
            vec2 local_xy = canvas_rect.xy + uv * canvas_px / max(canvas_scale, 0.0001);
            vec2 mask_uv = (local_xy - mask_rect.xy) / max(mask_rect.zw, vec2(0.0001));
            number a = mask_sample(mask_uv, mask_uv_rect);
            vec2 ext_uv = (local_xy - ext_rect.xy) / max(ext_rect.zw, vec2(0.0001));
            a = max(a, mask_sample(ext_uv, ext_uv_rect) * ext_enabled);
            number m = smoothstep(alpha_cutoff, alpha_cutoff + max(edge_feather, 0.0001), a);
            return vec4(src.rgb, src.a * m);
        }
    ]])
    return _mask_shader
end

local function _uv_rect(rect, iw, ih)
    local qx, qy, qw, qh = rect.quad:getViewport()
    return { qx/iw, qy/ih, qw/iw, qh/ih }
end

local function _send_shader(shader, canvas, ox, oy, cs, r, ext_r, cfg)
    local qx, qy, qw, qh = r.quad:getViewport()
    local iw, ih = r.atlas.image:getDimensions()
    shader:send("mask_tex", r.atlas.image)
    shader:send("canvas_rect", { -ox, -oy, canvas:getWidth()/cs, canvas:getHeight()/cs })
    shader:send("canvas_px", { canvas:getWidth(), canvas:getHeight() })
    shader:send("mask_texel", { 1/iw, 1/ih })
    shader:send("canvas_scale", cs)
    shader:send("mask_rect", { r.x, r.y, r.w, r.h })
    shader:send("mask_uv_rect", { qx/iw, qy/ih, qw/iw, qh/ih })
    shader:send("ext_rect", ext_r and { ext_r.x, ext_r.y, ext_r.w, ext_r.h } or { r.x, r.y, r.w, r.h })
    shader:send("ext_uv_rect", ext_r and _uv_rect(ext_r, iw, ih) or { qx/iw, qy/ih, qw/iw, qh/ih })
    shader:send("ext_enabled", ext_r and 1 or 0)
    shader:send("alpha_cutoff", cfg.alpha_cutoff or cfg.alpha or 0.05)
    shader:send("edge_feather", cfg.edge_feather or cfg.feather or 0.035)
    shader:send("edge_px", cfg.edge_px or cfg.feather_px or 1.25)
end

-----------------------------
--- draw
-----------------------------
function M.draw_profile_masked(panel, child, draw_fn, opts)
    local cfg = Mask.cfg(opts); if not cfg then return draw_fn(panel, child) end
    local canvas, ox, oy, cs = Canvas.render(panel, child, draw_fn, cfg); if not canvas then return end
    local r = Mask.rect(panel, child, cfg); if not r then return end
    local ext_cfg = Mask.sub_cfg(cfg, "extension")
    local ext_r = ext_cfg and Mask.rect(panel, child, ext_cfg)

    local old_shader, old_color = LG.getShader(), { LG.getColor() }
    local shader = _shader()

    push_draw_trans(child)
    LG.scale(1/child.rcfg.tile_size)
    Mask.draw_visible(panel, child, cfg)
    Mask.draw_visible_sub(panel, child, cfg, "extension")
    LG.setColor(1, 1, 1, 1)
    _send_shader(shader, canvas, ox, oy, cs, r, ext_r, cfg)
    LG.setShader(shader)
    LG.draw(canvas, -ox, -oy, 0, 1/cs, 1/cs)
    LG.setShader(old_shader)
    LG.setColor(old_color[1], old_color[2], old_color[3], old_color[4])
    LG.pop()
end

-----------------------------
--- attach
-----------------------------
local function _remove_profile_draw(panel)
    local children = panel.widget and panel.widget.children; if not children then return end
    for i = #children, 1, -1 do if children[i].hud_profile_draw_adapter then table.remove(children, i) end end
end

function M.attach_profile_draw(panel, draw_fn, order, opts)
    if not (panel and panel.widget and draw_fn) then return end
    _remove_profile_draw(panel)
    panel.widget.children = panel.widget.children or {}

    local T = panel.hud_profile_T or Common.profile_T(panel.hud_side or "player")
    local child = HMWidget(panel.gm, { style = "empty_container", T = T, can_hover = N, can_collide = N, draw_order = order or LAYER.profile_picture })

    child.hud_profile_draw_adapter = Y
    child.parent = panel.widget
    child:set_role({ role_type = "Minor", major = panel.widget, offset = { x = T.x or 0, y = T.y or 0 }, xy_bond = "Strong", wh_bond = "Strong", r_bond = "Strong", scale_bond = "Strong" })
    child.draw = function(_, draw_opts) if not (draw_opts and draw_opts.shadow_only) then M.draw_profile_masked(panel, child, draw_fn, opts) end end

    panel.widget.children[#panel.widget.children + 1] = child
end

return M
