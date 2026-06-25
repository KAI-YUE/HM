vec4 suit_card_position(mat4 transform_projection, vec4 vertex_position)
{
    if (hover_tilt <= 0.) {
        return transform_projection * vertex_position;
    }

    float mid_dist = length(vertex_position.xy - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);
    vec2 mouse_offset = (vertex_position.xy - mouse_screen_pos.xy) / screen_scale;
    float scale = 0.2 * (-0.03 - 0.3 * max(0., 0.3 - mid_dist))
        * hover_tilt * (length(mouse_offset) * length(mouse_offset)) / (2. - mid_dist);

    return transform_projection * vertex_position + vec4(0, 0, 0, scale);
}
