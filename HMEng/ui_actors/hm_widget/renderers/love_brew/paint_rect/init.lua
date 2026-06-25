local Paint  = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.paint")
local Hit    = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.hit")
local TextFx = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.textfx")
local Draw   = require("HMEng.ui_actors.hm_widget.renderers.love_brew.paint_rect.draw")

local M = {}

M.config_keys = {
    "paint",  "paint_alpha", "paint_seed_entry",
    "shader", "seed",   "wobble", "bleed", "wave_px", "feather_px", "fx_mask_ref",
    "x_mul",  "y_mul",  "w_mul", "h_mul",
    "x", "y", "w", "h", "ox", "oy", "ow", "oh",

    "text_box_scale", "text_offset",
    "textfx",         "extra_textfx",   "textfx_static", "letter_flip", "paint_bg",
    "hover_color",    "hover_tint",    "parent_hover_tint", "click_visual_time", "widget_dist",
    "fill_color",     "shadow",        "shadow_color",      "idle_color", "idle_fill_color", "idle_text_color",
    "hit_shape",      "hit_padding",   "hit_scale",         "hit_offset",
}

M.draw_paint_rect = Paint.draw_paint_rect
M.draw_bleed_layer = Paint.draw_bleed_layer
M.hit_test = Hit.hit_test
M.hit_test_outer = Hit.hit_test_outer
M.text_layout_box = Hit.text_layout_box
M.init = TextFx.init
M.draw = Draw.draw

return M
