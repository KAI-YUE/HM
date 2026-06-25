local Actor = require("HMEng.actors.actor")

local Tst   = { "drag", "hover", "click" }
local Y, N  = true, false
local push  = table.insert

return function (BoardZone)
--------------------------------------------------
--- init_boardzone_attributes
--------------------------------------------------
function BoardZone:init_boardzone_attributes(gm, x, y, w, h, config)
    Actor.init(self, gm, x, y, w, h)

    self.config, self.zones   = config or {}, {}
    self.static_move          = self.config.static_move ~= N
    self:refresh_move_registry()
    if gm.refresh_render_context then gm:refresh_render_context(self) end
    self.spots,  self.events  = {}, {}
    self.bg_decor            = nil
    self.path, self.paths, self.path_template = nil, {}, nil
    self.route_nodes, self.route_adjacency, self.route_version = {}, {}, 0
    self.move_preview, self.path_selection_handler = nil, nil
    self.bridges, self.bridge_nodes, self.bridge_adjacency, self.bridge_serial = {}, {}, {}, 0
    self.bridge_interaction = { enabled = N, source = nil, proposal = nil }
    self.revealed_field_cells = {}

    local cfg = self.config
    cfg.path = cfg.path or { kind = "rectangle", inset = 2 }

    local st = self.states
    for _, k in ipairs(Tst) do st[k].can = N end

    local gR = gm.R
    self.RBZ = gR.BOARDZONE
    if getmetatable(self) == BoardZone then push(self.RBZ, self) end
end

--------------------------------------------------
--- remove
--------------------------------------------------
local function cleanup(tab, obj) for i, v in ipairs(tab) do if v == obj then table.remove(tab, i); break end end end
function BoardZone:remove()
    if self.bg_decor and self.bg_decor.boardzone == self then self.bg_decor.parent, self.bg_decor.board, self.bg_decor.boardzone = nil, nil, nil; end

    self.zones, self.spots, self.events, self.path, self.paths, self.path_template = nil, nil, nil, nil, nil, nil
    self.route_nodes, self.route_adjacency, self.route_version = nil, nil, nil
    self.move_preview, self.path_selection_handler = nil, nil
    self.bridges, self.bridge_nodes, self.bridge_adjacency, self.bridge_serial = nil, nil, nil, nil
    self.bridge_interaction, self.revealed_field_cells, self.bg_decor = nil, nil, nil
    cleanup(self.RBZ, self)
    Actor.remove(self)
end

end
