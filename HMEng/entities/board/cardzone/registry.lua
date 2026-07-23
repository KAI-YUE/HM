local Actor    = require("HMEng.actors.actor")
local TabUtils = require("HMfns.utils.table_utils")

local destroy_tree = TabUtils.destroy_tree
local push         = table.insert

local Tst         = { "drag", "hover", "click" }
local Tatt        = { "cards", "children", "highlighted" }
local Tcfg        = { "highlight_limit" }
local Tproj       = { "projector", "projected_quad_source", "projected_quad_coords" }

local Tcfg_init   = { "highlighted_limit", "card_limit", "type", "sort" }
local Dcfg_init   = { 5,                    52,          "deck", "desc" }
local Tself_init  = { "card_w", "card_h", "card_d" }
local Dself_init  = { function(_, gm) return gm.card_w end, function(_, gm) return gm.card_h end,  function(_, gm) return gm.card_d end }

local Y, N   = true, false

return function (CardZone)
-----------------------------------------
-- Init cardarea att
-----------------------------------------
--- Helpers: init //projection | self | config// attribute
local function _init_projection_attributes(self, config) for _, k in ipairs(Tproj) do self[k] = config[k]  end end
local function _init_self_attributes(self, cfg, gm)      for i, k in ipairs(Tself_init) do local fallback = Dself_init[i]; if type(fallback) == "function" then fallback = fallback(cfg, gm) end; self[k] = cfg[k] or fallback end end
local function _init_config_defaults(cfg, gm)            for i, k in ipairs(Tcfg_init)  do local fallback = Dcfg_init[i];  if type(fallback) == "function" then fallback = fallback(cfg, gm) end;  cfg[k] = cfg[k] or fallback end end

---_________________
--- main: init 
---_________________
function CardZone:init_zone_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)

    local st = self.states
    for _, k in ipairs(Tst)  do st[k].can = N end
    for _, k in ipairs(Tatt) do self[k] = {} end 
    self.card_layout_dirty = N

    self.config = config or {}                 
    local cfg   = self.config
    _init_self_attributes(self, cfg, gm)
    _init_config_defaults(cfg, gm)
    _init_projection_attributes(self, cfg)

    local gR   = gm.R                            
    local RCZ  = gR.CARDZONE
    if self:is(CardZone) then push(RCZ, self) end
    self.gm, self.RCZ, self.gG = gm, RCZ, gm.GAME
end

------------------------------------
--- remove 
------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function CardZone:remove()
    if self.cards    then destroy_tree(self.cards) end;          self.cards = nil
    if self.children then destroy_tree(self.children) end;       self.children = nil
    cleanup(self.RCZ, self)
    Actor.remove(self)
end

end
