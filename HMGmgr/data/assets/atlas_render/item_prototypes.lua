local FileIO = require("core.io.fileio")

local tsort = table.sort
local Tuda  = { "unlocked", "discovered", "alerted" }
local N = false

return function(GMgr)
-----------------------------
--- init item prototypes
----------------------------
--- Helper: save to profile
function GMgr:_save2profile()
    self:save_progress()
    local SET, Spro = self.SET, self.SET.profile

    self.Fs.convert_save_to_meta(self)
    local shared = self.shared_save_path and FileIO.unpickle(self:shared_save_path())
    local meta = shared and shared.meta and shared.meta[Spro] or FileIO.unpickle(Spro.."/meta.hm") or {}
    for _, k in ipairs(Tuda) do meta[k] = meta[k] or {} end

    tsort(self.P_locked,         function(a, b) return not a.order or not b.order or a.order < b.order end)
    tsort(self.P_CPools["Deck"], function(a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
end

---____________________
--- main: init item prototypes
---____________________
function GMgr:init_item_prototypes()
    self:shared_atlas_settings()
    self.tag_undiscovered = {name = "Not Discovered", order = 1, config = {type = ""}, pos = { x=3,y=4 } }

    self.b_undiscovered = {name = "Undiscovered", debuff_text = "Defeat this blind to discover", pos = {x=0,y=30}}

    self.CMod = {
        c_base = { max = 500, freq = 1, line = "base", name = "Default Base", pos = { x = 1,y = 0 }, set = "Default", label = "Base Card", effect = "Base", cost_mult = 1.0, config = {} },

        b_red = {name = "Red Deck", stake = 1, unlocked = true, order = 1, pos = {x=0,y=0}, set = "Deck", config = {discards = 1}, discovered = true},

        e_base        = {order = 1, unlocked = true, discovered = N, name = "Base",         pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {}},
        e_foil        = {order = 2, unlocked = true, discovered = N, name = "Foil",         pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 50}},
        e_holo        = {order = 3, unlocked = true, discovered = N, name = "Holographic",  pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 10}},
        e_polychrome  = {order = 4, unlocked = true, discovered = N, name = "Polychrome",   pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 1.5}},
        e_negative    = {order = 5, unlocked = true, discovered = N, name = "Negative",     pos = {x=0,y=0}, atlas = "Joker", set = "Edition", config = {extra = 1}},
    }

    self.P_CPools = { Default = {}, Edition = {}, Deck = {} }
    self.P_locked = {}
    self:_save2profile()
end

end
