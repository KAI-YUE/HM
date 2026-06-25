local Actor    = require("HMEng.actors.actor")
local BgDecor  = Actor:extend()

local min, max = math.min, math.max

local function install(mod) mod(BgDecor) end
local install_list = { "registry", "build", "group", "render", "update" }
for _, pkg in ipairs(install_list) do install(require("HMEng.entities.bg.bg_decor." .. pkg)) end

--------------------------------
--- init, for grass decorators
--------------------------------
function BgDecor:init(gm, x, y, w, h, config) self:init_bg_decor_attributes(gm, x, y, w, h, config) end

-----------------------------------------------------------
--- Methods: add_entry | set_entries | clear_entries
-----------------------------------------------------------
function BgDecor:add_entry(entry)     if not entry then return end; self.entries[#self.entries + 1] = entry end
function BgDecor:set_entries(entries) self.entries = entries or {} end
function BgDecor:clear_entries()      self.entries = {} end

return BgDecor
