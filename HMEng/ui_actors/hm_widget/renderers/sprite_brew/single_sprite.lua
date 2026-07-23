local Init    = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.init")
local Hit     = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.hit")
local Draw    = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.draw")
local Metrics = require("HMEng.ui_actors.hm_widget.renderers.sprite_brew.single_sprite.metrics")

local M = {}

M.config_keys = {
    "atlas_key",            "quad_key",            "sprite_mask_key", "sprite_offset", "sprite_mask_offset", "sprite_mask_scale",
    "sprite_mask_deco_color", "sprite_mask_deco_offset", "sprite_mask_deco_scale",
    "sprite_flip_x",        "sprite_flip_y",       "fit_axis", "quad_T", "quad_T_map", "quad_T_index", "quad_T_gap", "sprite_overlays", "bg", "sprite_bg",
    "sprite_rotate_speed",  "sprite_rotate_phase",
    "hit_shape",            "hit_padding",
    "hover_face_shader",    "hover_mask_shader",
    "hover_zoom",           "hover_rotate",        "hover_rotate_time", "hover_shake", "hover_shake_sprite_only",
    "shadow",               "shadow_color",        "shadow_parallax", "hover_safe_time",
    "paint",                "slot_enter_shader",   "slot_enter_delay",
    "tint",                 "sprite_color",        "fill_color", "hover_color", "hover_tint", "parent_hover_tint", "click_visual_time", "widget_dist",
    "idle_tint",            "selected_tint",
    "show_on_parent_hover", "parent_hover_reveal_s", "parent_hover_reveal_ease", "parent_hover_reveal_alpha",
    "no_press_squash",       "parent_press_squash",
}

M.init           = Init.init
M.layout_sprite  = Metrics.layout_sprite
M.hit_test_outer = Hit.hit_test_outer
M.hit_test       = Hit.hit_test
M.draw           = Draw.draw

return M
