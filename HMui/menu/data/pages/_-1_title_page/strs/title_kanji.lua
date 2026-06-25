local C        = require("HMfns.animate.color.color_const")
local Layout   = require("HMui.menu.data.pages._-1_title_page.strs.title_layout")
local English  = require("HMui.menu.data.pages._-1_title_page.strs.title_english")
local Shared   = require("HMui.menu.data.pages._-1_title_page.shared.title_shared")

local tint_alpha     = Shared.tint_alpha
local sprite_widget  = Shared.sprite_widget
local push           = table.insert

local CUI, CTTL    = C.UI,    C.TITLE
local cw,  ccrm    = C.WHITE, C.CREAM
local ck,  cpaper  = C.BLACK, CTTL.PAPER

local c_kanji_mask, c_kanji = cpaper, CUI.TEXT_DARK
 
local _title_mask_shadow_layer,        _title_mask_face_layer        = 10, 20
local _title_kanji_shadow_layer,       _title_kanji_face_layer       = 21, 30
local _title_kanji_part_shadow_layer,  _title_kanji_part_face_layer  = 32, 40

local _kanji_mask_dist, _kanji_dist = 1.9, 1.2

local _kanji_mask_paint = { shader = "paper_sway", speed = 0.5 }

local Y = true

local M = {}

----------------------------------------------
--- Helper: item_matches_stage
----------------------------------------------
local function item_matches_stage(item, opts)
    local stage = item.stage or "both"
    if stage == "both" then return Y end
    if stage == "title" then return opts and opts.title_stage or false end
    return not (opts and opts.title_stage)
end

--- Helper: kanji_transform
local function kanji_transform(item)
    local mask_x_bias,  mask_y_bias   = item.mask_x_bias  or 0, item.mask_y_bias  or 0
    local kanji_x_bias, kanji_y_bias  = item.kanji_x_bias or 0, item.kanji_y_bias or 0.16

    local mask_T   = { x = item.x + mask_x_bias, y = item.y + mask_y_bias, w = item.mask_w, r = item.r }
    local kanji_T  = { x = item.x + 0.5*(item.mask_w - item.kanji_w) + kanji_x_bias, y = item.y + kanji_y_bias, w = item.kanji_w, r = item.r }

    return mask_T, kanji_T
end

----------------------------------------------
--- Helper: anchored_transform
----------------------------------------------
local function anchored_transform(anchor, item)
    return { x = anchor.x + (item.x_bias or 0), y = anchor.y + (item.y_bias or 0), w = item.w, r = item.r }
end

--- Helper: kanji_widgets
local function kanji_widgets(out)
    for _, item in ipairs(Layout.kanji) do
        local mask_T, kanji_T = kanji_transform(item)
        
        push(out, sprite_widget("title_" .. item.id .. "_mask", "title_pack", item.mask, mask_T, {
            sprite_color  =  c_kanji_mask,              shadow_color  = tint_alpha(ck, 0.40),
            widget_dist   = _kanji_mask_dist,           shadow_layer  = _title_mask_shadow_layer,
            face_layer    = _title_mask_face_layer,     paint         = _kanji_mask_paint,
        }))

        push(out, sprite_widget("title_" .. item.id .. "_kanji", "title_pack", item.kanji, kanji_T, {
            sprite_color  = c_kanji,                    shadow_color  = tint_alpha(ck, 0.34),
            widget_dist   = _kanji_dist,                shadow_layer  = _title_kanji_shadow_layer,
            face_layer    = _title_kanji_face_layer,
        }))
    end
end

--- Helper: decorator_widgets
local function decorator_widgets(out, opts)
    for _, kanji in ipairs(Layout.kanji) do
        for _, item in ipairs(kanji.decorators or {}) do
            if not item_matches_stage(item, opts)   then goto continue end
            if not (opts and opts.press_decorators) then goto continue end
            local tint = item.tint or ccrm

            push(out, sprite_widget("title_decorator_" .. item.id, item.atlas, item.key, anchored_transform(kanji, item), {
                sprite_color  = tint,
                shadow        = item.shadow,
                shadow_color  = tint_alpha(ck, 0.24),
                widget_dist   = item.dist,
                shadow_layer  = item.shadow_layer,
                face_layer    = item.face_layer,
                paint         = item.paint,
                page_switch_manual_enter = item.manual_enter,
            }))
            ::continue::
        end
    end
end

--- Helper: kanji_part_widgets
local function kanji_part_widgets(out, opts)
    for _, kanji in ipairs(Layout.kanji) do
        for _, item in ipairs(kanji.parts or {}) do
            if not item_matches_stage(item, opts) then goto continue end
            push(out, sprite_widget("title_part_" .. item.id, "title_pack", item.key, anchored_transform(kanji, item), {
                sprite_color  = c_kanji,
                shadow_color  = tint_alpha(ck, 0.30),
                widget_dist   = item.dist or 1.35,
                shadow_layer  = item.shadow_layer or _title_kanji_part_shadow_layer,
                face_layer    = item.face_layer or _title_kanji_part_face_layer,
                page_switch_manual_enter = Y,
            }))
            ::continue::
        end
    end
end

---------------------------------
--- child_widgets
---------------------------------
function M.child_widgets(opts)
    local out = {}
    
    English.english_letter_widgets(out)
    kanji_widgets(out)
    kanji_part_widgets(out, opts)
    decorator_widgets(out, opts)
    
    return out
end

return M
