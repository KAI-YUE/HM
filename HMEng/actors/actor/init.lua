local GameObj = require("HMEng.actors.game_obj")
local Actor   = GameObj:extend()

local TabUtils   = require("HMfns.utils.table_utils")
local MathUtils  = require("HMfns.utils.math.math_utils")

local random_pick, wipe = TabUtils.random_pick, TabUtils.wipe
local t_in, r_in        = MathUtils.vec_translate_inplace, MathUtils.vec_rotate_inplace

local function install(mod) mod(Actor) end
local install_list = {"parallax", "registry", "align", "move.init", "role"}
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.actor." .. pkg)) end

-------------------------------------------------------
-- Actor: init 
-------------------------------------------------------
function Actor:init(gm, x, y, w, h) self:init_actor_attributes(gm, x, y, w, h) end
function Actor:draw() GameObj.draw(self); self:bound_me() end

return Actor
