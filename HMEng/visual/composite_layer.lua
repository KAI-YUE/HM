local LG = love.graphics

local Y = true

local M = {}

local _premultiply_shader

--------------------------------------------------
--- shader helpers
--------------------------------------------------
function M.premultiply_shader()
    if _premultiply_shader then return _premultiply_shader end
    _premultiply_shader = LG.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            vec4 c = Texel(tex, texture_coords) * color;
            c.rgb *= c.a;
            return c;
        }
    ]])
    return _premultiply_shader
end

--------------------------------------------------
--- canvas helpers
--------------------------------------------------
function M.restore_canvas(canvas) if canvas then LG.setCanvas({ canvas, stencil = Y }) else LG.setCanvas() end end

function M.ensure_canvas(owner, key, w, h)
    local canvas = owner[key]
    if canvas and canvas:getWidth() == w and canvas:getHeight() == h then return canvas end

    canvas = LG.newCanvas(w, h, { type = "2d" })
    owner[key] = canvas
    return canvas
end

--------------------------------------------------
--- composite passes
--------------------------------------------------
function M.render_to_canvas(canvas, opts, draw_fn)
    opts = opts or {}
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    local old_blend, old_alpha_mode = LG.getBlendMode()

    LG.setCanvas({ canvas, stencil = Y })
    if opts.clear ~= false then LG.clear(0, 0, 0, 0) end
    if opts.reset_transform then LG.push(); LG.origin() end

    LG.setShader(opts.shader)
    LG.setBlendMode(opts.blend or "lighten", opts.alpha_mode or "premultiplied")
    draw_fn()

    if opts.reset_transform then LG.pop() end
    LG.setBlendMode(old_blend, old_alpha_mode)
    LG.setShader(old_shader)
    M.restore_canvas(old_canvas)
end

function M.draw_canvas(canvas, opts)
    opts = opts or {}
    local old_shader = LG.getShader()
    local old_blend, old_alpha_mode = LG.getBlendMode()
    local c = opts.color or { 1, 1, 1, 1 }

    LG.push()
    if opts.origin then LG.origin() end
    LG.setShader(opts.shader)
    LG.setBlendMode(opts.blend or "alpha", opts.alpha_mode or "alphamultiply")
    LG.setColor(c[1] or 1, c[2] or 1, c[3] or 1, (opts.alpha or 1)*(c[4] or 1))
    LG.draw(canvas, opts.x or 0, opts.y or 0, opts.r or 0, opts.sx or 1, opts.sy or 1)
    LG.setColor(1, 1, 1, 1)
    LG.setBlendMode(old_blend, old_alpha_mode)
    LG.setShader(old_shader)
    LG.pop()
end

return M
