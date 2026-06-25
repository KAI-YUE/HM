local Colors = require("HMEng.ui_actors.hm_panel.prototype.confirm_popup.confirm_colors")

local Y, N = true, false

local M = {}

local _btn_w = 1.7

--- Helper: confirm_button
local function confirm_button(args)
    return {
        --- basic settings
        style     = "rbox",                       slot_idx = args.slot_idx,
        id        = args.id,                      T = { x = args.x, y = args.y, w = _btn_w },
        quad_key  = "btn_mask",                   sprite_mask_key  = N,

        --- hit settings
        button    = Y,                            can_click  = Y,
        can_hover = Y,                            hook_fn    = args.hook_fn,

        --- color & shadow settings
        fill_color   = args.fill_color,           tint         = args.fill_color,
        sprite_color = args.fill_color,           shadow_color = Colors.shadow,
        shadow       = N,                         paint_bg     = N,
        hover_tint   = 0,
        click_visual_time  = 0.16,                idle_color  = { fill_color = Colors.black, tint = args.fill_color, sprite_color = args.fill_color, text_color = Colors.text_light },
        hover_color  = { fill_color = args.hover_fill_color, tint = args.hover_fill_color, sprite_color = args.hover_fill_color },

        --- text settings
        text = args.text,                         text_color = Colors.text_light,         text_align = { x = "center", y = "middle" },
        text_scale = 0.42,                        text_static = Y,                        text_wrap = N,
        text_reveal = N,                          text_shadow = Y,                        text_offset = { x = 0, y = 0 },
        paint = { "_2_edge_feather", feather_px = 0.1 },
    }
end

--- Helper: prompt_text
local function prompt_text(id, prompt, args)
    return { --- basic settings
        style = "text_widget",                    id = id,
        text  = prompt,

        --- text settings
        text_color = Colors.text_light,           text_scale = 0.54,                     text_align = { x = "center", y = "middle" },
        text_wrap = args.text_wrap ~= N,          text_box_T = args.text_box_T or { x = -0.7, y = 0, w = 3, h = 4 },
        text_static = args.text_wrap == N,        text_offset = args.text_offset or { x = 0, y = 0 },
        text_maxw = args.text_maxw,
    }
end

---____________________________
--- main: child_widgets
---______________________________________
function M.child_widgets(args, bx1, bx2, by, panel_w)
    local prefix  = args.id_prefix or "confirm_popup"
    local list    = { prompt_text(prefix .. "_text", args.prompt, args) }

    if args.title_widget then list[#list + 1] = args.title_widget(panel_w) end

    list[#list + 1] = confirm_button({ id = prefix .. "_yes", text = args.yes, slot_idx = args.slot_idx, x = bx1, y = by, hook_fn = args.yes_hook_fn, fill_color = Colors.yes_idle, hover_fill_color = Colors.yes_hover })
    list[#list + 1] = confirm_button({ id = prefix .. "_no",  text = args.no,  slot_idx = args.slot_idx, x = bx2, y = by, hook_fn = args.no_hook_fn,  fill_color = Colors.no_idle,  hover_fill_color = Colors.no_hover })
    return list
end

return M
