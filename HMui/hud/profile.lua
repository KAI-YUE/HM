local HMWidget  = require("HMEng.ui_actors.hm_widget")
local Render    = require("HMfns.systems.render")
local Layout    = require("HMui.hud.layout")
local Theme     = require("HMui.hud.theme")
local Common    = require("HMui.hud.common")
local LG        = love.graphics

local Y, N = true, false

local M = {}

local LAYER   = Layout.layer
local PROFILE = Theme.profile or {}
local push_draw_trans = Render.push_actor_draw_transform

local _mask_shader

-----------------------------
--- profile mask
----------------------------
--- Helper: mask shader
local function _profile_mask_shader()
    if _mask_shader then return _mask_shader end
    _mask_shader = LG.newShader([[
        extern number alpha_cutoff;
        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
        {
            if (Texel(tex, uv).a <= alpha_cutoff) discard;
            return vec4(1.0);
        }
    ]])
    return _mask_shader
end

--- Helper: profile mask cfg
local function _profile_mask_cfg(opts)
    if opts and opts.mask == N then return end
    if type(opts and opts.mask) == "table" then return opts.mask end
    return Layout.profile_mask
end

--- Helper: profile mask box
local function _profile_mask_box(child, cfg)
    local VT = child and child.VT; if not VT then return end
    if cfg.relative ~= N then return { x = (cfg.x or 0)*VT.w, y = (cfg.y or 0)*VT.h, w = (cfg.w or 1)*VT.w, h = (cfg.h or 1)*VT.h } end
    return { x = cfg.x or 0, y = cfg.y or 0, w = cfg.w or VT.w, h = cfg.h or VT.h }
end

--- Helper: draw profile mask
local function _draw_profile_mask(panel, child, cfg)
    local gm, box = panel and panel.gm, _profile_mask_box(child, cfg); if not (gm and box) then return end
    local atlas = gm.T_atlas and gm.T_atlas[cfg.atlas_key or "icon_pack"]; if not atlas then return end
    local ok, quad = pcall(atlas.get_quad, atlas, cfg.quad_key or "paper-1"); if not ok then return end
    local _, _, qw, qh = quad:getViewport(); if not (qw and qh and qw > 0 and qh > 0) then return end
    LG.draw(atlas.image, quad, box.x, box.y, cfg.r or 0, box.w*child.rcfg.tile_size/qw, box.h*child.rcfg.tile_size/qh)
end

--- Helper: draw visible profile mask
local function _draw_visible_profile_mask(panel, child, cfg)
    if cfg.draw == N then return end
    local tint = cfg.tint or { 1, 1, 1, 0.42 }
    LG.setColor(tint[1] or 1, tint[2] or 1, tint[3] or 1, tint[4] or 1)
    _draw_profile_mask(panel, child, cfg)
    LG.setColor(1, 1, 1, 1)
end

--- Helper: restore stencil
local function _restore_stencil(compare, value) if compare then LG.setStencilTest(compare, value) else LG.setStencilTest() end end

--- Helper: profile mask scissor
local function _profile_mask_scissor(child, cfg)
    local box = _profile_mask_box(child, cfg); if not box then return end
    local x1, y1 = LG.transformPoint(box.x, box.y)
    local x2, y2 = LG.transformPoint(box.x + box.w*child.rcfg.tile_size, box.y + box.h*child.rcfg.tile_size)
    return math.floor(math.min(x1, x2)), math.floor(math.min(y1, y2)), math.ceil(math.abs(x2 - x1)), math.ceil(math.abs(y2 - y1))
end

--- Helper: restore scissor
local function _restore_scissor(x, y, w, h) if x then LG.setScissor(x, y, w, h) else LG.setScissor() end end

---______________________________________________
--- main: draw profile masked
---______________________________________________
function M.draw_profile_masked(panel, child, draw_fn, opts)
    local cfg = _profile_mask_cfg(opts); if not cfg then return draw_fn(panel, child) end

    local old_shader, old_color = LG.getShader(), { LG.getColor() }
    local old_compare, old_value = LG.getStencilTest()
    local old_sx, old_sy, old_sw, old_sh = LG.getScissor()
    local shader = _profile_mask_shader()
    shader:send("alpha_cutoff", cfg.alpha_cutoff or cfg.alpha or 0.05)

    push_draw_trans(child)
    LG.scale(1/child.rcfg.tile_size)
    _draw_visible_profile_mask(panel, child, cfg)
    LG.setShader(shader)
    LG.stencil(function() _draw_profile_mask(panel, child, cfg) end, "replace", 1)
    LG.setShader(old_shader)
    LG.setStencilTest("greater", 0)
    LG.setScissor(_profile_mask_scissor(child, cfg))
    draw_fn(panel, child)
    LG.setShader(old_shader)
    _restore_scissor(old_sx, old_sy, old_sw, old_sh)
    _restore_stencil(old_compare, old_value)
    LG.setColor(old_color[1], old_color[2], old_color[3], old_color[4])
    LG.pop()
end

-----------------------------
--- profile draw
----------------------------
--- Helper: remove profile draw
local function _remove_profile_draw(panel)
    local children = panel.widget and panel.widget.children; if not children then return end
    for i = #children, 1, -1 do if children[i].hud_profile_draw_adapter then table.remove(children, i) end end
end

---______________________________________________
--- main: attach profile draw
---______________________________________________
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

-----------------------------
--- profile widgets
----------------------------
--- Helper: profile strokes
local function _profile_strokes(strokes)
    local out = {}
    for i, s in ipairs(strokes) do out[i] = type(s) == "table" and Common.copy_T(s) or { quad_key = s, x = 0, y = 0, w = 1, h = 1, r = 0 }; if type(s) == "table" then out[i].quad_key = s.quad_key end end
    return out
end

--- Helper: profile stroke color
local function _profile_stroke_color(side, pass, fallback)
    local stroke = PROFILE.stroke or {}
    local color  = stroke[side]
    if type(color) == "table" and color[1] then return color end
    if type(color) == "table" then return color[pass] or fallback end
    return color or fallback
end

--- Helper: profile stroke shadow opts
local function _profile_stroke_shadow_opts(shadow, face_layer, shadow_layer)
    local out = { shadow = shadow.enabled ~= N, shadow_color = shadow.color or { 0, 0, 0, 0.28 }, shadow_parallax = shadow.shadow_parallax, widget_dist = shadow.widget_dist or 0.45, stroke_shadow_order = shadow.order, no_press_squash = Y }
    if shadow.order ~= "per_stroke" then out.shadow_layer, out.face_layer = shadow_layer, face_layer end
    return out
end

--- Helper: profile mask preview T
local function _profile_mask_preview_T(T, cfg)
    if cfg.relative ~= N then return { x = T.x + (cfg.x or 0)*T.w, y = T.y + (cfg.y or 0)*T.h, w = (cfg.w or 1)*T.w, h = (cfg.h or 1)*T.h, r = cfg.r } end
    return { x = T.x + (cfg.x or 0), y = T.y + (cfg.y or 0), w = cfg.w or T.w, h = cfg.h or T.h, r = cfg.r }
end

--- Helper: profile mask preview
local function _profile_mask_preview(T)
    local cfg = Layout.profile_mask; if not (cfg and cfg.draw ~= N) then return end
    return Common.sprite(_profile_mask_preview_T(T, cfg), cfg.atlas_key or "icon_pack", cfg.quad_key or "paper-1", cfg.tint or { 1, 1, 1, 0.42 }, LAYER.profile_picture - 1, "hud_profile_mask_preview")
end

---______________________________
--- main: widgets
---______________________________
function M.widgets(side, stroke_color)
    local T            = Common.profile_T(side)
    local out, shadow  = {}, PROFILE.stroke_shadow or {}
    local back_shadow  = _profile_stroke_shadow_opts(shadow, LAYER.profile_back, LAYER.profile_back)
    local front_shadow = _profile_stroke_shadow_opts(shadow, LAYER.profile_front, LAYER.profile_picture)
    out[#out + 1] = Common.stroke_child(T, _profile_strokes(Layout.profile_strokes.back), _profile_stroke_color(side, "back", stroke_color), LAYER.profile_back, back_shadow)
    out[#out + 1] = _profile_mask_preview(T)
    out[#out + 1] = Common.stroke_child(T, _profile_strokes(Layout.profile_strokes.front), _profile_stroke_color(side, "front", stroke_color), LAYER.profile_front, front_shadow)
    return out
end

return M
