local Actor = require("HMEng.actors.actor")

local LIMG, LG = love.image, love.graphics
local push     = table.insert

local Y, N = true, false

local _placeholder_img

return function (ShaderFX)
-----------------------------------------------------------
--- Helper: shared white image
-----------------------------------------------------------
local function _get_placeholder_img()
    if _placeholder_img then return _placeholder_img end

    local data = LIMG.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 0)
    _placeholder_img = LG.newImage(data)
    return _placeholder_img
end

-----------------------------------------------------------
--- init shader fx attributes
-----------------------------------------------------------
function ShaderFX:init_shader_fx_attributes(gm, x, y, w, h)
    Actor.init(self, gm, x, y, w, h)

    self.img,         self.quad         = _get_placeholder_img(), LG.newQuad(0, 0, 1, 1, 1, 1)
    self.qx, self.qy, self.qw, self.qh  = 0, 0, 1, 1

    self.img_dims,    self.shader_only  = { 1, 1 }, Y
    self.draw_alpha = 1

    self.t_shaders, self.RFX = gm.t_shaders, gm.R.SHADERFX
    self.shader_fx_layer = "above_field"
    if getmetatable(self) == ShaderFX then push(self.RFX, self) end
end

-------------------------------------------------
--- quad_viewport | image_dims | render_layers
-------------------------------------------------
function ShaderFX:quad_viewport()         return { self.qx, self.qy, self.qw, self.qh } end
function ShaderFX:image_dims()            return self.img_dims end
function ShaderFX:set_render_layer(layer) self.shader_fx_layer = layer or "above_field"; return self end

-----------------------------------------------------------
--- Remove
-----------------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function ShaderFX:remove()
    cleanup(self.RFX, self)
    Actor.remove(self)
end

end
