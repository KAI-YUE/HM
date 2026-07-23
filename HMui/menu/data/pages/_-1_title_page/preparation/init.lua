local Layout = require("HMui.menu.data.pages._-1_title_page.preparation.layout")
local Shared = require("HMui.menu.data.pages._-1_title_page.shared.title_shared")

local sprite_widget  = Shared.sprite_widget
local max, min       = math.max, math.min

local Y, N = true, false

local M = {}

local colors,          paint       = Layout.colors, Layout.paint
local press,           center      = Layout.press,  Layout.prompt_center
local prompt_letters,  word_masks  = Layout.letters, Layout.word_masks

--- Helper: centered_x | centered_y | prompt_width | prompt_origin
local function centered_x(w, center_bias)  return center.x + (center_bias or 0) - 0.5*w end
local function centered_y(y_bias)          return center.y + (y_bias or 0) end
local function prompt_width()              local w = 0; for i, tab in ipairs(prompt_letters) do w = w + (i < #prompt_letters and tab.step_w or tab.w) end; return w; end
local function prompt_origin()             return centered_x(prompt_width()), centered_y(-0.345) end

----------------------------------------------
--- Helper: prompt_underlay_composite
----------------------------------------------
local function prompt_letter_positions()
    local out, x, y = {}, prompt_origin()
    for i, tab in ipairs(prompt_letters) do
        out[i] = { x = x + (tab.x or 0), y = y + (tab.y or 0), w = tab.w, h = tab.w }
        x = x + tab.step_w
    end
    return out
end

--- Helper: prompt_word_bounds
local function prompt_word_bounds(pos, first, last)
    local x0, y0, x1, y1
    for i = first, last do
        local p = pos[i];      if not p then goto continue end
        x0, y0 = min(x0 or p.x, p.x), min(y0 or p.y, p.y)
        x1, y1 = max(x1 or p.x + p.w, p.x + p.w), max(y1 or p.y + p.h, p.y + p.h)
        ::continue::
    end
    return x0, y0, x1, y1
end

--- Helper: prompt_underlay_bounds
local function prompt_underlay_bounds(bounds, item)
    local x,  y,  w,  h   = item.x or 0,   item.y or 0,      item.w or 0,    item.h or 0
    bounds.x0, bounds.y0  = min(bounds.x0 or x, x),          min(bounds.y0 or y, y)
    bounds.x1, bounds.y1  = max(bounds.x1 or x + w, x + w),  max(bounds.y1 or y + h, y + h)
end

--- Helper: prompt_word_mask_item
local function prompt_word_mask_item(cfg, pos)
    local x0,  y0, x1,  y1  = prompt_word_bounds(pos, cfg.first, cfg.last);      if not x0 then return end
    local base_w,  base_h   = x1 - x0, y1 - y0
    local w = base_w*(cfg.x_scale or cfg.scale or Layout.word_mask_scale)
    local h = base_h*(cfg.y_scale or cfg.scale or Layout.word_mask_scale)
    return { atlas_key = "title_pack", quad_key = cfg.key, x = x0 + 0.5*base_w - 0.5*w, y = y0 + 0.5*base_h - 0.5*h + (cfg.y_bias or 0), w = w, h = h, r = cfg.r or 0 }
end

--- Helper: prompt_underlay_items
local function prompt_underlay_items()
    local items, bounds, paper = {}, {}, Layout.word_mask_paper
    if paper and paper.enabled ~= N then items[#items + 1] = { atlas_key = paper.atlas, quad_key = paper.key, x = centered_x(paper.w, paper.center_bias), y = centered_y(paper.y_bias), w = paper.w, h = paper.h, r = paper.r or 0 } end

    local pos = prompt_letter_positions()
    for _, cfg  in ipairs(word_masks) do local item = prompt_word_mask_item(cfg, pos); if item then items[#items + 1] = item end; end
    for _, item in ipairs(items)      do prompt_underlay_bounds(bounds, item) end
    return items, bounds
end

--- Helper: prompt_underlay_composite_widget
local function prompt_underlay_composite_widget(out)
    local items, bounds = prompt_underlay_items();      if not bounds.x0 then return end
    
    local pad   = Layout.word_mask_composite_pad or 0.25
    local x, y  = bounds.x0 - pad, bounds.y0 - pad
    for _, item in ipairs(items) do item.x, item.y = item.x - x, item.y - y end

    out[#out + 1] = {
        --- basics
        style     = "sprite_in_page",                T         = { x = x, y = y, w = bounds.x1 - bounds.x0 + 2*pad, h = bounds.y1 - bounds.y0 + 2*pad },
        renderer  = "sprite_composite",              room_ref  = Y,
        id        = "press_any_underlay_composite", 
        
        --- hit settings
        button     = N,                              can_click = N, 
        can_hover  = N,

        --- composite
        composite_items = items,                     composite_blend = "lighten",
        
        --- paint
        paint  = paint.underlay_sway,                sprite_color  = colors.word_mask, 
        tint   = colors.word_mask,                   widget_dist   = 0.53,
    }
end

----------------------------------------------
--- Helper: prompt_letter_widgets
----------------------------------------------
local function prompt_letter_widgets(out)
    local x, y = prompt_origin()
    for i, tab in ipairs(prompt_letters) do
        local lx, ly = x + (tab.x or 0), y + (tab.y or 0)
        out[#out + 1] = sprite_widget("press_any_letter_" .. i, "title_pack", tab.key, { x = lx, y = ly, w = tab.w, r = 0 }, {
            sprite_color = colors.text, shadow_color = colors.text_shadow, widget_dist = 0.65, paint = paint.prompt_glint,
        })
        x = x + tab.step_w
    end
end

--- Helper: prompt_underline_widget
local function prompt_underline_widget(out, cfg)
    local widget = sprite_widget(cfg.id, "title_pack", cfg.key, { x = centered_x(cfg.w, cfg.center_bias), y = centered_y(cfg.y_bias), w = cfg.w, r = cfg.r }, {
        sprite_color = colors.text, shadow_color = colors.line_shadow, widget_dist = cfg.dist, paint = paint.prompt_glint,
    })
    out[#out + 1] = widget
end

--- Helper: prompt_underline_widgets
local function prompt_underline_widgets(out) for _, cfg in ipairs(Layout.underline) do prompt_underline_widget(out, cfg) end end

----------------------------------------
--- preparation_widgets
----------------------------------------
function M.preparation_widgets(gm)
    local out = {
        {
            --- basics
            style  = "empty_container",          T = { x = 0, y = 0, w = 1, h = 1 },    
            id     = "press_any_screen",         room_ref = Y,

            --- hit settings
            hit_area   = "world",                button     = Y,
            can_click  = Y,                      can_hover  = Y,
            hook_fn    = "title_page_press_any",
        },
        {
            --- basics
            style  = "empty_container",          T = { x = press.x, y = press.y, w = press.w, h = press.h },
            id     = "press_any",                room_ref = Y,

            --- hit settings
            button     = Y,                      can_click  = Y,
            can_hover  = Y,                      hook_fn    = "title_page_press_any",
        },
    }
    prompt_underlay_composite_widget(out)
    prompt_letter_widgets(out)
    prompt_underline_widgets(out)
    return out
end

return M
