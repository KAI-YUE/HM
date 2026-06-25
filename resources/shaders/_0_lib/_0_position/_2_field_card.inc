vec4 field_card_position(mat4 transform_projection, vec4 vertex_position)
{
    if (hovering <= 0.0 || hover_tilt <= 0.){
        return transform_projection * vertex_position;
    }

    float x01 = (vertex_position.x - mouse_screen_pos.x)/(love_ScreenSize.x);
    float y01 = (vertex_position.y - 0.8*mouse_screen_pos.y)/(love_ScreenSize.y);
    
    float depth = 0.5 * (0.5 - y01);
    float side  = 0.5 * (x01 - .2) *(x01 - .2);

    float scale = (depth - side) + 0.001*screen_scale;
    
    scale = clamp(scale, -1, 1);
    // return transform_projection * vertex_position + vec4(0,0,0,scale);
    return transform_projection * vertex_position + vec4(0,0,0, 0.025*scale);
}
