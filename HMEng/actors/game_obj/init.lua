local class   = require("core.class")
local GameObj = class:extend()

local function install(mod) mod(GameObj) end
local install_list = {"registry", "render", "render_debug", "ops"}
for _, pkg in ipairs(install_list) do install(require("HMEng.actors.game_obj." .. pkg)) end

-------------------------------------------------------
-- GameObj: init 
-------------------------------------------------------
--- Initialize a new GameObj
function GameObj:init(gm, args) self:init_gameobj_attributes(gm, args) end
--- Base method hooks 
function GameObj:hover(gm) end
function GameObj:stop_hover() end
function GameObj:drag()     end
function GameObj:can_drag() return self.states.drag.can end
function GameObj:click()    end
function GameObj:release()  end
function GameObj:animate()  end
function GameObj:update(dt) end

return GameObj
