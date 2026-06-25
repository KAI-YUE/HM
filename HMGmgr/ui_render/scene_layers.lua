local Card     = require("HMEng.entities.card")
local TabUtils = require("HMfns.utils.table_utils")

local contains = TabUtils.contains
local LG       = love.graphics

local Y, N = true, false

return function(GMgr)
-----------------------------
--- _send_title_page_options_snapshot_shader
----------------------------------
function GMgr:_send_title_page_options_snapshot_shader(shader, canvas)
    if shader:hasUniform("texel_size") then shader:send("texel_size", { 1 / canvas:getWidth(), 1 / canvas:getHeight() }) end
    if shader:hasUniform("blur_radius") then shader:send("blur_radius", self.title_page_options_snapshot_blur_radius or 3.0) end
    if shader:hasUniform("dim_color") then shader:send("dim_color", self.title_page_options_snapshot_dim_color or { 0, 0, 0, 0.24 }) end
    if shader:hasUniform("time") then shader:send("time", self.title_page_options_snapshot_shader_time or (self._T.real_s) or 0) end
end

-----------------------------
--- _draw_title_page_options_snapshot
----------------------------------
function GMgr:_draw_title_page_options_snapshot()
    local canvas = self.title_page_options_snapshot;      if not canvas then return N end
    local shader_name = self.title_page_options_snapshot_shader
    local shader = shader_name and self.t_shaders and self.t_shaders[shader_name]
    local old_shader = LG.getShader()
    local r, g, b, a = LG.getColor()
    LG.push()
    LG.origin()
    if shader then
        self:_send_title_page_options_snapshot_shader(shader, canvas)
        LG.setShader(shader)
    else
        LG.setShader()
    end
    LG.setColor(1, 1, 1, 1)
    LG.draw(canvas, 0, 0)
    LG.pop()
    LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    return Y
end

-----------------------------
--- HUD render guards
----------------------------
--- Helper: deck preview HUD panel
local function deck_preview_hud_panel(gm, panel)
    if not (gm.VIEWING_DECK and panel) then return N end
    if panel.hud_side or panel == gm.HUD or panel == gm.HUD_blind then return Y end
    for _, tag in pairs(gm.HUD_tags or {}) do if panel == tag then return Y end end
    local UI = gm.UI or {}
    return panel == UI.player_hud or panel == UI.foe_hud
end

-----------------------------
--- obj_render_1by1
----------------------------------
function GMgr:obj_render_1by1(opts)
    if self.debug_UI_toggle then return end
    opts = opts or {}
    local R = self.R

    for _, v in pairs(self:render_bucket("GOBJ"))  do self:_render_obj(v, Y) end
    for _, v in pairs(self:render_bucket("ACTOR")) do self:_render_obj(v, Y) end

    local UI,  F,   CTRL   = self.UI, self.F, self.CTRL
    local drt, fct         = CTRL.dragging.target, CTRL.focused.target
    local hide_underlay = UI.overlay_menu and (F.hide_bg or self:_overlay_underlay_mode() == "snapshot" or self:_overlay_underlay_mode() == "hidden")
    if not hide_underlay then
        local Texclude  = { UI.overlay_menu, opts.exclude_overlay, UI.overlay_tut, self.achievement_notification }

        for _, v in pairs(self:render_bucket("TMAP")) do
            if v ~= self.bg then self:_render_obj_in_context(v, Y) end
        end
        for _, v in pairs(self:render_bucket("BOARDZONE")) do self:_render_obj_in_context(v, Y) end

        self:_render_shader_fx_pass("above_field")
        for _, v in pairs(self.sky_decorators or {}) do self:_render_obj_in_context(v) end
        for _, v in pairs(self:render_bucket("CARDZONE")) do  self:_render_obj_in_context(v, Y) end
        for _, v in pairs(self:render_bucket("CHARA")) do self:_render_obj(v, Y) end
        self:_render_shader_fx_pass("above_hand")

        self:_draw_title_page_options_snapshot()

        for _, v in pairs(self:render_bucket("UIPANEL")) do
            if v.attention_text or v.parent or contains(Texclude, v) then goto continue end
            if deck_preview_hud_panel(self, v) then goto continue end
            if v == self.screenwipe or v == self.debug_tools then  goto continue end
            self:_render_obj(v)
            ::continue::
        end

        self.under_overlay = N
    end

    if UI.overlay_menu or not F.hide_bg then
        if not UI.overlay_menu or UI.overlay_menu == fct then goto continue end
        self:_render_obj(UI.overlay_menu)
        ::continue::
    end

    if drt and drt ~= CTRL.focused.target then self:_render_obj_in_context(drt) end
    if fct and fct:is(Card) and (fct.zone ~= self.hand or fct == drt) then self:_render_obj_in_context(fct) end
    if not opts.skip_popups then for _, v in pairs(self:render_bucket("POPUP")) do self:_render_obj(v) end end

    local ntf, sw = self.achievement_notification, self.screenwipe
    if ntf then self:_render_obj(ntf) end
    if sw  then self:_render_obj(sw) end

    local DT = self.debug_tools
    if DT then self:_render_obj(DT) end

    if not opts.skip_cursor then self:_render_cursor() end
end

-----------------------------
--- _render_modal_layers
----------------------------------
function GMgr:_render_modal_layers()
    for _, v in pairs(self:render_bucket("POPUP")) do self:_render_obj(v) end

    local ntf, sw = self.achievement_notification, self.screenwipe
    if ntf then self:_render_obj(ntf) end
    if sw  then self:_render_obj(sw) end

    local DT = self.debug_tools
    if DT then self:_render_obj(DT) end

    self:_render_cursor()
end

end
