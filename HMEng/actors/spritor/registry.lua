local TabUtils = require("HMfns.utils.table_utils")
local Actor    = require("HMEng.actors.actor")

local LG = love.graphics
local push, _copy = table.insert, TabUtils.deep_copy

local Y, N = true, false

return function (Spritor)
-----------------------------------------------------------
--- Init sprite actor attributes 
-----------------------------------------------------------
--- Helper: resolve lock_wh_ratio
local function _resolve_lock_wh_ratio(lock_wh_ratio) if lock_wh_ratio == nil then return Y else return lock_wh_ratio end end

---____________________________
--- main: init_spritor_attributes
---____________________________
function Spritor:init_spritor_attributes(gm, x, y, w, h, atlas, key, lock_wh_ratio)
    Actor.init(self, gm, x, y, w, h)
    self.img,          self.quad           = atlas.image, atlas:get_quad(key)
    self.qx,  self.qy, self.qw, self.qh    = self.quad:getViewport()
    self.t_shaders,    self.lock_wh_ratio  = gm.t_shaders, _resolve_lock_wh_ratio(lock_wh_ratio)

    self.img_dims = {}
    self.img_dims[1],  self.img_dims[2]    = self.img:getDimensions()

end

--------------------------------------------
--- quad_viewport | image_dims
--------------------------------------------
function Spritor:quad_viewport() return { self.qx, self.qy, self.qw, self.qh } end
function Spritor:image_dims()    return self.img_dims end

-----------------------------------------------------------
--- Remove 
-----------------------------------------------------------
function Spritor:remove() Actor.remove(self) end

end
