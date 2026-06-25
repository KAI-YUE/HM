local TabUtils = require("HMfns.utils.table_utils")
local C, LG    = require("HMfns.animate.color.color_const"), love.graphics

local abs,  min  = math.abs,     math.min
local push, wipe = table.insert, TabUtils.wipe

local cw       = C.WHITE
local Tdraws   = { "shader", "shadow_height", "send", "no_tilt", "other_obj", "ms", "mr", "mx", "my" }
local Y, N     = true, false

local ShaderUtils = {}

------------------------------------
--- define_draw_steps
------------------------------------
function ShaderUtils.define_draw_steps(self, steps)
    self.draw_steps = wipe(self.draw_steps)
    for _, v in ipairs(steps) do
        local l = {}
        for _, d in ipairs(Tdraws) do l[d] = v[d] end
        push(self.draw_steps, l)
    end
end

------------------------------------
--- run draw_steps
------------------------------------
function ShaderUtils.run_draw_steps(self)
    if not self.draw_steps then return N end
    for _, v in ipairs(self.draw_steps) do self:draw_shader(v.shader, v.shadow_height, v.send, v.no_tilt, v.other_obj, v.ms, v.mr, v.mx, v.my, not not v.send) end
    return Y
end

------------------------------------
--- init_ss
------------------------------------
function ShaderUtils.init_ss(self, opts)
    opts = opts or {}

    local args, VT = self.args, self.VT
    local TV, now  = self.tilt_var or { amt = 0 }, self.gm._T.real_s
    local base     = (opts.base and opts.base(self, now, VT, TV)) or (min(3*(VT.r or 0), 1) + now/30 + (TV.amt or 0))

    args.send2fs = args.send2fs or {}
    local ss     = args.send2fs
    ss[1], ss[2], ss[3] = base, now, self.ID
    return ss
end

------------------------------------
--- send custom_shader 
------------------------------------
function ShaderUtils.send_custom_shader(_shader, _send)
    if not _send then return end
    local SS = S and S[_shader]
    for _, v in ipairs(_send) do
        local val = v.val
        if val == nil then val = (v.func and v.func()) or (v.ref_table and v.ref_table[v.ref_value]) end
        ShaderUtils.send_sp_uniform(SS, v.name, val)
    end
end

--- Helper: send uniform 
function ShaderUtils.send_sp_uniform(SS, name, val) if SS and name and SS:hasUniform(name) then SS:send(name, val) end end

---___________________________
--- main: send base uniforms
---___________________________
function ShaderUtils.send_base_uniforms(SS, cfg)
    cfg = cfg or {}
    local _send = ShaderUtils.send_sp_uniform
    _send(SS, "mouse_screen_pos", cfg.mouse_screen_pos or { 0, 0 })
    _send(SS, "screen_scale",     cfg.screen_scale or 1)
    if cfg.hovering   ~= nil then _send(SS, "hovering",   cfg.hovering) end
    if cfg.hover_tilt ~= nil then _send(SS, "hover_tilt", cfg.hover_tilt) end
    _send(SS, "position_shader_mode", cfg.position_shader_mode or 0)

    _send(SS, "fx_mask",       cfg.fx_mask or 0)
    -- _send(SS, "fx_mask",       1)
    _send(SS, "time",          cfg.time or 0)
    _send(SS, "blur_severity", cfg.blur_severity or 0.04)
    _send(SS, "blur_radius",   cfg.blur_radius or cfg.radius or cfg.blur_severity or 0.04)
    _send(SS, "speed_factor",  cfg.speed_factor or 1)
    _send(SS, "_tex_details",  cfg.tex_details or { 0, 0, 1, 1 })
    _send(SS, "image_details", cfg.image_details or { 1, 1 })
    _send(SS, "c1",            cfg.c1 or cw)
    _send(SS, "c2",            cfg.c2 or cw)
    _send(SS, "shadow",        not not cfg.shadow)
end


------------------------------------
--- draw shader 
------------------------------------
--- Helper: apply_shadow_parallax
local function apply_shadow_parallax(VT, sp, h, sign)
    if not h then return end
    local sx, sy = sp.x or 0, sp.y or 0
    VT.x = VT.x + sign*sx*h
    VT.y = VT.y + sign*sy*h
    VT.scale = sign < 0 and VT.scale*(1 - 0.2*h) or VT.scale/(1 - 0.2*h)
end

--- Helper: shader cursor position
local function shader_cursor_pos(self, draw_major, scale)
    local cpos = self.Ctrl.cursor_position
    local tv   = draw_major.tilt_var
    if tv then return { tv.mx*scale, tv.my*scale } end
    return { cpos.x*scale, cpos.y*scale }
end

--- Helper: shader mask colors
local function shader_mask_colors(opts, draw_major)
    local cs = { opts.fx_mask_color_default or cw, opts.fx_mask_color_default or cw }
    local dc = draw_major.fx_mask_colors
    if dc then cs[1], cs[2] = dc[1] or cs[1], dc[2] or cs[2] end
    return cs
end

--- Helper: shader texture details
local function shader_tex_details(self, opts)
    local tex_details   = opts.tex_details   and opts.tex_details(self)   or self:quad_viewport()
    local image_details = opts.image_details and opts.image_details(self) or self:image_dims()
    return tex_details, image_details
end

--- Helper: handle shader 
function ShaderUtils.handle_shader(self, opts, h, _send2, _no_tilt, _shader, custom_shader, tilt_shadow, _draw_major)
    local opts, SS = opts or {}, (self.t_shaders and self.t_shaders[_shader]) or self.default_shader
    if custom_shader then return ShaderUtils.send_custom_shader(_shader, _send2) end

    local rcfg  = self.rcfg                       
    local norm  = rcfg.tile_scale * rcfg.tile_size
    
    local scale,   cs          = rcfg.s_canvas*norm,                                   shader_mask_colors(opts, _draw_major)
    local damping, hover_tilt  = _draw_major.mouse_damping or 1,                        _draw_major.hover_tilt or 0
    local time,    pos         = self._T.real_s%100 + 10*(_draw_major.ID/1.1 or 13)%100, shader_cursor_pos(self, _draw_major, scale)
    
    local tex_details, image_details = shader_tex_details(self, opts)

    if (h and not tilt_shadow) or _no_tilt then hover_tilt = 0 end

    local hovering = opts.hovering
    if opts.hovering_func then hovering = opts.hovering_func(self, _draw_major) end
    if opts.zero_hover_tilt_when_idle and (hovering == N or hovering == 0) then hover_tilt = 0 end
    
    local hover_send = (not opts.skip_hover_tilt) and hover_tilt 
    if opts.before_send         then opts.before_send(SS, self, _draw_major) end

    local fx_mask = abs(_draw_major.fx_mask or 0)

    ShaderUtils.send_base_uniforms(SS, {
        mouse_screen_pos      = pos,                            screen_scale      = damping * scale,
        hovering              = hovering,                       hover_tilt        = hover_send,
        position_shader_mode  = _draw_major.position_shader_mode or 0,
        fx_mask               = fx_mask,                        time              = time,
        tex_details           = tex_details,                    image_details     = image_details,
        c1                    = cs[1],                          c2                = cs[2],
        shadow                = not not h,
    })
    
    local _send = ShaderUtils.send_sp_uniform
    if opts.send_shader_uniform and _send2 then _send(SS, _shader, _send2) end
end


---_______________________________________
--- main: draw shader 
---_______________________________________
function ShaderUtils.draw_shader(self, opts, _shader, h, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow, draw_state)
    local ctx = { shader = _shader,        h           = h,               send = _send,  no_tilt = _no_tilt,
        other_obj        = other_obj,      ms          = ms,              mr   = mr,     mx      = mx,          my = my,
        custom_shader    = custom_shader,  tilt_shadow = tilt_shadow,     draw_state = draw_state,
    }

    ctx.draw_major  = (opts.get_draw_major  and opts.get_draw_major(self, ctx))  or self.role.draw_major or self
    ctx.tilt_shadow = (opts.get_tilt_shadow and opts.get_tilt_shadow(self, ctx)) or ctx.tilt_shadow

    if opts.prepare and opts.prepare(self, ctx) == N then return ctx.result end

    local VT, _shader = self.VT, (self.t_shaders and self.t_shaders[ctx.shader]) or self.default_shader
    local sp = (opts.get_shadow_parallax and opts.get_shadow_parallax(self, ctx)) or ctx.draw_major.shadow_parallax or {}

    apply_shadow_parallax(VT, sp, ctx.h, -1)

    if not opts.skip_handle_shader then self:handle_shader(ctx.h, ctx.send, ctx.no_tilt, ctx.shader, ctx.custom_shader, ctx.tilt_shadow, ctx.draw_major, ctx.target) end

    LG.setShader(_shader)
    if opts.draw_with_shader  then opts.draw_with_shader(self, ctx)
    elseif ctx.other_obj      then self:draw_from(ctx.other_obj, ctx.ms, ctx.mr, ctx.mx, ctx.my)
    else                           self:draw_self(nil, ctx) end
    LG.setShader()

    apply_shadow_parallax(VT, sp, ctx.h, 1)

    return ctx.result
end

return ShaderUtils
