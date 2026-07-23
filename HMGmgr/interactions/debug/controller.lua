local Intents = require("HMGmgr.interactions.intents")

local M = {}

-----------------------------
--- controller intents
----------------------------------
function M.install(GMgr)
--- Helper: handle controller intent
function GMgr:_handle_controller_intent(intent)
    if not intent then return end
    local intent_type = type(intent) == "table" and intent.type or intent
    local handler     = Intents[intent_type]
    if handler then handler(self, intent.payload) end
end

--- Helper: handle controller intents
function GMgr:_handle_controller_intents(intents)
    if not intents then return end
    for _, intent in ipairs(intents) do self:_handle_controller_intent(intent) end
end

function GMgr:_handle_controller_callback(intent) self:_handle_controller_intent(intent) end
end

return M

