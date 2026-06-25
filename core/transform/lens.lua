local class = require("core.class")

local LG, LF = love.graphics, love.filesystem

local Lens = class:extend()

local FXAA_PATH    = "resources/shaders/_0_lib/_2_aa/_100_fxaa.glsl"
local SHARPEN_PATH = "resources/shaders/_0_lib/_2_aa/_101_sharpen.glsl"

--- Helpers: read_shader | new canvas | restore canvas 
local function _read_shader(path)          return assert(LF.read(path), ("Failed to read shader source '%s'"):format(path)) end
local function _new_canvas(width, height)  return LG.newCanvas(width, height) end
local function _restore_canvas(old_canvas) if old_canvas then LG.setCanvas({ old_canvas, stencil = true }) else LG.setCanvas() end end
local function _lens_args(args, height, stages, sharpen) if type(args) == "table" then return args end; return { width = args, height = height, stages = stages, sharpen = sharpen } end

-----------------------------
--- init
----------------------------
--- Helper: init shaders 
function Lens:_init_shaders()
    self.shader_fxaa = LG.newShader(_read_shader(FXAA_PATH))
    self.shader_fxaa:send("fxaa_reduce_min", 1.0 / 128.0)
    self.shader_fxaa:send("fxaa_reduce_mul", 1.0 / 8.0)
    self.shader_fxaa:send("fxaa_span_max", 8.0)

    self.shader_sharpen = LG.newShader(_read_shader(SHARPEN_PATH))
    if self.sharpen > 0 then self.shader_sharpen:send("sharpness", self.sharpen) end
end

---__________________
-- main
---__________________
function Lens:init(args, height, stages, sharpen)
    args = _lens_args(args, height, stages, sharpen)
    self.stages, self.sharpen  = args.stages or 1, args.sharpen or 0
    self.width, self.height    = 0, 0
    self.layers   = {}

    self:_init_shaders()
    self:resize(args.width or 1, args.height or 1)
end

-----------------------------
--- resize 
----------------------------
--- Helper: rebuild canvases 
function Lens:_rebuild_canvases(width, height)
    self.width, self.height = width, height
    self.layers = {}
    for _ = 1, self.stages do table.insert(self.layers, _new_canvas(width, height)) end
    self.sharp_pass = self.sharpen > 0 and _new_canvas(width, height) 
end

---____________________
--- main: resize 
---____________________
function Lens:resize(width, height)
    width, height = math.max(1, math.floor(width + 0.5)), math.max(1, math.floor(height + 0.5))
    if self.width == width and self.height == height then return end
    self:_rebuild_canvases(width, height)
end

-----------------------------
--- draw
----------------------------
function Lens:draw(dfn)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    LG.setCanvas(self.layers[1])
    LG.clear(0, 0, 0, 0)
    LG.setShader(self.shader_fxaa)
    LG.push()
    LG.origin()
    dfn()
    LG.pop()
    _restore_canvas(old_canvas)
    LG.setShader(old_shader)
end

-----------------------------
--- render 
----------------------------
--- Helper: stage_by_stage
local function stage_by_stage(self, old_canvas, old_shader)
    for stage, canvas in ipairs(self.layers) do
        if stage <= 1 then goto continue end 
        LG.setCanvas(canvas)
        LG.clear(0, 0, 0, 0)
        LG.setShader(self.shader_fxaa)
        LG.push()
        LG.origin()
        LG.draw(self.layers[stage - 1], 0, 0)
        LG.pop()
        LG.setShader(old_shader)
        _restore_canvas(old_canvas)
        ::continue::
    end
end

---_____________________
--- main
---_____________________
function Lens:render(x, y, sx, sy)
    local old_canvas, old_shader = LG.getCanvas(), LG.getShader()
    if #self.layers > 1 then stage_by_stage(self, old_canvas, old_shader) end

    local final = self.layers[#self.layers]
    local function _handle_rest() LG.draw(final, x or 0, y or 0, 0, sx or 1, sy or 1); LG.setShader(old_shader) end
    if not self.sharp_pass then return _handle_rest() end
    
    LG.setCanvas(self.sharp_pass)
    LG.clear(0, 0, 0, 0)
    LG.setShader(self.shader_sharpen)
    LG.push()
    LG.origin()
    LG.draw(final, 0, 0)
    LG.pop()
    LG.setShader(old_shader)
    _restore_canvas(old_canvas)
    final = self.sharp_pass

    return _handle_rest()
end

return Lens
