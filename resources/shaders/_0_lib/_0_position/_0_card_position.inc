#pragma HM_INCLUDE "_0_lib/_0_position/_1_suit_card.inc"
#pragma HM_INCLUDE "_0_lib/_0_position/_2_field_card.inc"

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    if (position_shader_mode >= 0.5) {
        return field_card_position(transform_projection, vertex_position);
    }

    return suit_card_position(transform_projection, vertex_position);
}
