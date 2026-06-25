return function (BoardZone)
--------------------------------------------------
--- get zone
--------------------------------------------------
function BoardZone:get_zone(key) local zones = self.zones; return zones and zones[key]  end

--------------------------------------------------
--- set zone
--------------------------------------------------
--- Helper: _bind_zone
local function _bind_zone(self, key, zone)
    if not zone then return end

    self.zones[key], self[key]    = zone, zone
    zone.parent,     zone.board   = self, self
    zone.boardzone                = self
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self); self.gm:refresh_render_context(zone) end

    if key == "gridzone" then
        self.cell_w, self.cell_h  = zone.cell_w, zone.cell_h
        self.n_rows, self.n_cols  = zone.n_rows, zone.n_cols

        local path_cfg = self.config and self.config.path or {}
        local kind = path_cfg.kind or "rectangle"
        if kind == "rectangle" then self:build_rectangle_path(path_cfg.inset or 2) end
        if kind == "graph" then self:set_graph_paths(path_cfg.paths or { path_cfg }) end
    end
    return zone
end

---________________________________
--- main: set zone
---________________________________
function BoardZone:set_zone(key, zone) if not key then return end; return _bind_zone(self, key, zone) end
function BoardZone:set_gridzone(zone) return self:set_zone("gridzone", zone) end
function BoardZone:set_cardzone(zone) return self:set_zone("cardzone", zone) end

--------------------------------------------------
--- set_bg_decor
--------------------------------------------------
function BoardZone:set_bg_decor(bg_decor)
    if self.bg_decor == bg_decor then return bg_decor end
    if self.bg_decor and self.bg_decor.boardzone == self then
        self.bg_decor.parent, self.bg_decor.board, self.bg_decor.boardzone = nil, nil, nil
        if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(self.bg_decor) end
    end

    self.bg_decor = bg_decor;           if not bg_decor then return end

    bg_decor.parent, bg_decor.board, bg_decor.boardzone = self, self, self
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(bg_decor) end
    return bg_decor
end

--------------------------------------------------
--- clear_bg_decor
--------------------------------------------------
function BoardZone:clear_bg_decor()
    local bg_decor = self.bg_decor
    if not bg_decor then return end

    if bg_decor.parent    == self then bg_decor.parent    = nil end
    if bg_decor.board     == self then bg_decor.board     = nil end
    if bg_decor.boardzone == self then bg_decor.boardzone = nil end
    self.bg_decor = nil
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(bg_decor) end
    return bg_decor
end

--------------------------------------------------
--- clear zone
--------------------------------------------------
function BoardZone:clear_zone(key)
    local zone = self:get_zone(key)
    if not zone then return end

    if zone.parent    == self  then zone.parent = nil end
    if zone.board     == self  then zone.board = nil end
    if zone.boardzone == self  then zone.boardzone = nil end
    zone.states.visible = Y
    if self.gm and self.gm.refresh_render_context then self.gm:refresh_render_context(zone) end

    self.zones[key], self[key] = nil, nil

    if key == "gridzone" then
        self.cell_w, self.cell_h = nil, nil
        self.n_rows, self.n_cols = nil, nil
    end
    return zone
end

--------------------------------------------------
--- field proxies
--------------------------------------------------
function BoardZone:emplace_card(card, r_idx, c_idx)
    local zone = self.gridzone
    if not zone then return end
    return zone:emplace_card(card, r_idx, c_idx)
end

--------------------------------------------------
--- align cards & hard_set_cards
--------------------------------------------------
function BoardZone:align_cards(args) self.gridzone:align_cards(args) end
function BoardZone:hard_set_cards()  self.gridzone:hard_set_cards() end

--------------------------------------------------
--- emplace_pawn & remove pawn 
--------------------------------------------------
function BoardZone:emplace_pawn(pawn, r_idx, c_idx) self.gridzone:emplace_pawn(pawn, r_idx, c_idx) end
function BoardZone:remove_pawn(pawn) self.gridzone:remove_pawn(pawn) end

end
