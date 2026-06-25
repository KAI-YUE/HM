local Card = require("HMEng.entities.card")
local LG = love.graphics

local max, min = math.max, math.min

local Y, N = true, false

return function(GMgr)
-----------------------------
--- _overlay_underlay_mode
----------------------------------
function GMgr:_overlay_underlay_mode()
    local OM = self.UI and self.UI.overlay_menu
    return OM and OM.config and OM.config.underlay
end

-----------------------------
--- render_overlay_layers
----------------------------------
--- Helper: _option_menu_screenmode
local function _option_menu_screenmode(gm)
    local SET    = gm.SET or {}
    local Q, SW  = SET.queued_c or {}, SET.s_win or {}
    return Q.screenmode or SW.screenmode or "Windowed"
end

--- Helper: _overlay_menu_resolution_preview_enabled
local function _overlay_menu_resolution_preview_enabled(gm)
    local OM   = gm.UI and gm.UI.overlay_menu
    local cfg  = OM and OM.widget and OM.widget.config
    if not (cfg and cfg.renderer == "stroked_page") then return N end
    if _option_menu_screenmode(gm) == "Windowed"    then return N end
    local SET = gm.SET
    local res = SET and SET.queued_c and SET.queued_c.screenres
    return (res and Y) or N
end

--- Helper: _option_menu_resolution_preview
local function _option_menu_resolution_preview(gm)
    local SET = gm.SET
    if not _overlay_menu_resolution_preview_enabled(gm) then return end
    return SET and SET.queued_c and SET.queued_c.screenres
end

--- Helper: _resolution_preview_target_res
local function _resolution_preview_target_res(gm)
    local res = gm.SET and gm.SET.queued_c and gm.SET.queued_c.screenres
    if not res then return end
    return { w = res.w or res.width or LG.getWidth(), h = res.h or res.height or LG.getHeight() }
end

--- Helper: _resolution_preview_base_res
local function _resolution_preview_base_res(gm)
    local base = gm.option_menu_resolution_preview_base_res or {}
    return { w = base.w or base.width or LG.getWidth(), h = base.h or base.height or LG.getHeight() }
end

--- Helper: _resolution_preview_ratio
local function _resolution_preview_ratio(gm)
    local res, base = _resolution_preview_target_res(gm), _resolution_preview_base_res(gm)
    if not res then return 1 end
    return min((res.w or base.w)/base.w, (res.h or base.h)/base.h)
end

--- Helper: _resolution_preview_upscale | _resolution_preview_scale
local function _resolution_preview_upscale(gm) return _option_menu_resolution_preview(gm) and _resolution_preview_ratio(gm) > 1.005 end
local function _resolution_preview_scale(gm)  return max(0.1, min(1, _resolution_preview_ratio(gm))) end

--- Helper: _preview_canvas
local function _preview_canvas(gm, w, h)
    local canvas = gm.option_menu_resolution_preview_canvas
    if not canvas or canvas:getWidth() ~= w or canvas:getHeight() ~= h then
        canvas = LG.newCanvas(w, h, { type = "2d", readable = Y })
        canvas:setFilter("linear", "linear")
        gm.option_menu_resolution_preview_canvas = canvas
    end
    return canvas
end

--- Helper: _set_canvas
local function _set_canvas(canvas)
    if canvas then LG.setCanvas({ canvas, stencil = Y }) else LG.setCanvas() end
end

--- Helper: _hide_page_decor
local function _hide_page_decor(widget, hidden)
    local cfg = widget and widget.config
    if not (cfg and cfg.renderer == "stroked_page") then return end
    if hidden then
        widget._resolution_preview_decor = {
            split = cfg.split, page_regions = cfg.page_regions, page_region_polygons = cfg.page_region_polygons,
            strokes = cfg.strokes, page_colors = cfg.page_colors, stroke_color = cfg.stroke_color,
            shadow = cfg.shadow, shadow_color = cfg.shadow_color,
        }
        cfg.split, cfg.page_regions, cfg.page_region_polygons = nil, nil, nil
        cfg.strokes, cfg.page_colors, cfg.stroke_color = nil, nil, nil
        cfg.shadow, cfg.shadow_color = nil, nil
        return
    end
    local old = widget._resolution_preview_decor; if not old then return end
    cfg.split, cfg.page_regions, cfg.page_region_polygons = old.split, old.page_regions, old.page_region_polygons
    cfg.strokes, cfg.page_colors, cfg.stroke_color = old.strokes, old.page_colors, old.stroke_color
    cfg.shadow, cfg.shadow_color = old.shadow, old.shadow_color
    widget._resolution_preview_decor = nil
end

--- Helper: _hide_widget_children
local function _hide_widget_children(widget, hidden)
    if not widget then return end
    if hidden then
        widget._resolution_preview_children = widget.children
        widget.children = {}
        return
    end
    if widget._resolution_preview_children then widget.children = widget._resolution_preview_children; widget._resolution_preview_children = nil end
end

--- Helper: _hide_widget_textfx
local function _hide_widget_textfx(widget, hidden)
    local cfg = widget and widget.config;     if not cfg then return end
    if hidden then
        widget._resolution_preview_card_textfx = cfg.card_textfx
        cfg.card_textfx = nil
        return
    end
    if widget._resolution_preview_card_textfx ~= nil then cfg.card_textfx = widget._resolution_preview_card_textfx; widget._resolution_preview_card_textfx = nil end
end

--- Helper: _hide_attached_panel
local function _hide_attached_panel(panel, hidden)
    if not panel then return end
    if hidden then
        panel._resolution_preview_attached_panel = panel.attached_panel
        panel.attached_panel = nil
        return
    end
    if panel._resolution_preview_attached_panel then panel.attached_panel = panel._resolution_preview_attached_panel; panel._resolution_preview_attached_panel = nil end
end

--- Helper: _set_overlay_menu_children_hidden
local function _set_overlay_menu_children_hidden(overlay_menu, hidden)
    _hide_widget_children(overlay_menu.widget, hidden)
    _hide_widget_textfx(overlay_menu.widget, hidden)
    _hide_attached_panel(overlay_menu, hidden)
end

--- Helper: set overlay main decor hidden | force panel redraw
local function _set_overlay_main_decor_hidden(overlay_menu, hidden) _hide_page_decor(overlay_menu.widget, hidden) end
local function _force_panel_redraw(panel) if panel and panel.FR then panel.FR.f_dr = -1 end end

--- Helper: _render_overlay_menu_decor
local function _render_overlay_menu_decor(gm, overlay_menu)
    _set_overlay_menu_children_hidden(overlay_menu, Y)
    _force_panel_redraw(overlay_menu)
    gm:_render_obj(overlay_menu)
    _set_overlay_menu_children_hidden(overlay_menu, N)
end

--- Helper: _render_resolution_preview_overlay_menu
local function _render_resolution_preview_overlay_menu(gm, overlay_menu)
    local preview_scale = _resolution_preview_scale(gm)
    if preview_scale >= 0.995 then return gm:_render_obj(overlay_menu) end

    local target = LG.getCanvas();                    if not target then return gm:_render_obj(overlay_menu) end

    local tw,  th  = target:getDimensions()
    local pw,  ph  = max(1, math.floor(tw*preview_scale + 0.5)), max(1, math.floor(th*preview_scale + 0.5))
    local preview  = _preview_canvas(gm, pw, ph)

    local old_canvas, old_shader = target, LG.getShader()
    local r,     g,   b,    a    = LG.getColor()

    _render_overlay_menu_decor(gm, overlay_menu)

    LG.setCanvas({ preview, stencil = Y });             LG.push()
    LG.origin();                                        LG.scale((gm.rcfg.s_canvas or 1)*preview_scale)
    LG.setShader();                                     LG.clear(0, 0, 0, 0)
    LG.setColor(r, g, b, a);                            _set_overlay_main_decor_hidden(overlay_menu, Y)
    _force_panel_redraw(overlay_menu);                  gm:_render_obj(overlay_menu)
    _set_overlay_main_decor_hidden(overlay_menu, N);    LG.pop()

    _set_canvas(old_canvas);                            LG.push()
    LG.origin();                                        LG.setShader()
    LG.setColor(1, 1, 1, a);                            LG.draw(preview, 0, 0, 0, 1/preview_scale, 1/preview_scale)
    LG.pop();                                           LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    return Y
end

--- Helper: _render_overlay_menu
local function _render_overlay_menu(gm, overlay_menu)
    if _resolution_preview_upscale(gm)     then return Y end
    if _option_menu_resolution_preview(gm) then return _render_resolution_preview_overlay_menu(gm, overlay_menu) end
    return gm:_render_obj(overlay_menu)
end

-----------------------------
--- _render_overlay_layers
----------------------------------
function GMgr:_render_overlay_layers(opts)
    opts = opts or {}
    local UI, CTRL = self.UI, self.CTRL
    local drt, fct = CTRL.dragging.target, CTRL.focused.target

    if UI.overlay_menu then _render_overlay_menu(self, UI.overlay_menu) end
    if not opts.skip_drag and drt and drt ~= CTRL.focused.target then self:_render_obj_in_context(drt) end
    if not opts.skip_focus_card and fct and fct:is(Card) and (fct.zone ~= self.hand or fct == drt) then self:_render_obj_in_context(fct) end
    if not opts.skip_popups then for _, v in pairs(self:render_bucket("POPUP")) do self:_render_obj(v) end end

    local ntf, sw = self.achievement_notification, self.screenwipe
    if ntf then self:_render_obj(ntf) end
    if sw  then self:_render_obj(sw) end

    local DT = self.debug_tools
    if DT then self:_render_obj(DT) end

    if not opts.skip_cursor then self:_render_cursor() end
end

-----------------------------
--- _draw_resolution_preview_screen_overlay
----------------------------------
--- Helper: render_screen_resolution_preview_overlay_menu
local function _render_screen_resolution_preview_overlay_menu(gm, overlay_menu)
    local res = _resolution_preview_target_res(gm);     if not res then return end

    local target      = LG.getCanvas()
    local preview     = _preview_canvas(gm, max(1, math.floor(res.w + 0.5)), max(1, math.floor(res.h + 0.5)))
    local old_shader  = LG.getShader()
    local r, g, b, a  = LG.getColor()

    _render_overlay_menu_decor(gm, overlay_menu)

    LG.setCanvas({ preview, stencil = Y });             LG.push()
    LG.origin();                                        LG.scale(preview:getWidth()/LG.getWidth(), preview:getHeight()/LG.getHeight())
    LG.setShader();                                     LG.clear(0, 0, 0, 0)
    LG.setColor(r, g, b, a);                            _set_overlay_main_decor_hidden(overlay_menu, Y)
    _force_panel_redraw(overlay_menu);                  gm:_render_obj(overlay_menu)
    _set_overlay_main_decor_hidden(overlay_menu, N);    LG.pop()

    _set_canvas(target);                                LG.push()
    LG.origin();                                        LG.setShader()
    LG.setColor(1, 1, 1, a);                            LG.draw(preview, 0, 0, 0, LG.getWidth()/preview:getWidth(), LG.getHeight()/preview:getHeight())
    LG.pop();                                           LG.setShader(old_shader)
    LG.setColor(r, g, b, a)
    return Y
end

function GMgr:_draw_resolution_preview_screen_overlay()
    if self:_modal_backdrop_config() then return N end
    local overlay_menu = self.UI and self.UI.overlay_menu
    if not (overlay_menu and _resolution_preview_upscale(self)) then return N end
    return _render_screen_resolution_preview_overlay_menu(self, overlay_menu)
end

end
