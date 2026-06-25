local Prep        = require("HMGplay.run_flow.prep")
local HMPanel     = require("HMEng.ui_actors.hm_panel")
local TabUtils    = require("HMfns.utils.table_utils")
local CircleData  = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.predrawn_circle.circle_type1")
local RboxData    = require("HMEng.ui_actors.hm_widget.prototype.sprite_preset.rbox.rbox_type2")
local play_clip   = require("HMfns.utils.sound_utils").play_clip

local copy = TabUtils.deep_copy
local min, max = math.min, math.max

local Y, N = true, false

local M = {}

-----------------------------
--- tut_test
----------------------------------
--- Helper: preview panel T
local function _preview_panel_T(gm)
    local pw, ph = 2, 1
    local _s     = 2
    local anchor = (gm.field_pawn and gm.field_pawn.T) or (gm.tut_chara and gm.tut_chara.T) or { x = 4 }
    local ax     = anchor.x or 4
    local x      = ax
    local x, y = 2, 8

    return { x = x, y = y, w = _s*pw, h = _s*ph }
end

--- Helper: create panel preview
local function _create_panel_preview(gm)
    if gm.UI.hm_panel_preview then gm.UI.hm_panel_preview:remove() end
    local args = copy(CircleData)
    args.T, args.style = _preview_panel_T(gm), "predrawn_circle"

    local args = copy(RboxData)
    args.T, args.style = _preview_panel_T(gm), "rbox"

    gm.UI.hm_panel_preview = HMPanel(gm, args)
end

function M.tut_test(gm, args)
    Prep.prepare_for_gm(gm, args)

    Prep.init_gridzone(gm)  -- GridZone and pawns
    Prep.prep_camera(gm)
    Prep.prep_chara(gm)

    Prep.init_cardzones(gm) -- CardZone
    Prep.render_bg(gm)
    Prep.place_shader_fx(gm)

    -- _create_panel_preview(gm)
    return Y
end

return M
