local HMPanel         = require("HMEng.ui_actors.hm_panel")
local DeckPreviewPage = require("HMui.menu.data.pages._4_deck_preview_page.init")
local Data            = require("HMui.menu.data.pages._4_deck_preview_page.preview_layout")
local Tabs            = require("HMui.menu.data.pages._4_deck_preview_page.preview_tabs")
local C               = require("HMfns.animate.color.color_const")
local CUtils          = require("HMfns.animate.color.color_utils")

local snapshot_dim = CUtils.tint_with_alpha(C.STEEL, 0.4)

local Y, N = true, false

local M = { default_key = Data.default_key }

--------------------------------------------------
--- page data
--------------------------------------------------
--- Helper: switch_page
local function switch_page(gm, page_key)  local deck = gm and gm.deck; if deck then return deck:switch_deck_view_page(page_key) end end

---______________________________
--- main: build
---______________________________
function M.build(deck, selected, suits) return DeckPreviewPage.build(deck.gm, selected, { switch_page = switch_page }, suits) end

--------------------------------------------------
--- create panel
--------------------------------------------------
function M.create(deck, selected, suits)
    local gm, page = deck.gm, M.build(deck, selected, suits)

    page.type,     page.can_collide, page.can_hover  = "overlay_menu",  Y, Y
    page.hit_area, page.can_click,   page.can_drag   = "world",         N, N
    
    local panel = HMPanel(gm, page)
    panel.config        = {
        no_esc = Y, underlay = "snapshot", underlay_base = "world",
        underlay_shader = "mc_polar", underlay_blur_radius = 5., underlay_flow_strength = 1.0,
        underlay_shader_time = gm._T.real_s or 0, underlay_dim_color = snapshot_dim,
    }
    gm.UI.overlay_menu  = panel
    gm.CTRL:mod_cursor_context_layer(1)

    Tabs.select(panel.widget, selected)

    return panel
end

--------------------------------------------------
--- select tab
--------------------------------------------------
function M.select(panel, selected) Tabs.select(panel and panel.widget, selected) end

--------------------------------------------------
--- remove panel
--------------------------------------------------
function M.remove(gm, session)
    local panel = session.page_panel
    if gm.UI.overlay_menu == panel     then gm.UI.overlay_menu = nil end
    if panel and not panel.REMOVED     then panel:remove() end
    if session.cursor_context_open     then gm.CTRL:mod_cursor_context_layer(-1) end
    if gm.mark_overlay_snapshot_dirty  then gm:mark_overlay_snapshot_dirty() else gm.overlay_bg_snapshot_dirty = Y end
end

return M
