local class = require("core.class")
local EventMgr = class:extend()

local function install(mod) mod(EventMgr) end
local install_list = {"registry", "ops"}
for _, pkg in ipairs(install_list) do install(require("HMEng.events.event_mgr." .. pkg)) end

-------------------------------------------------------
-- EventMgr: init 
-------------------------------------------------------
function EventMgr:init(gm) self:init_event_mgr_attributes(gm, config) end

return EventMgr
