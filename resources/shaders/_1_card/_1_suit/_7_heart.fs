extern highp vec3 _7_heart;
extern highp number fx_mask;
extern highp number time;
extern highp vec4 _tex_details;
extern highp vec2 image_details;
extern bool shadow;
extern highp vec4 c1;
extern highp vec4 c2;

extern highp vec2 mouse_screen_pos;
extern highp float hovering;
extern highp float hover_tilt;
extern highp float screen_scale;
extern highp float position_shader_mode;
const highp number contrast = 1.1;

number GameID = _7_heart.z;

#pragma HM_INCLUDE "_0_lib/_1_masks/_0_dir_sweep.inc"

/* main fn */
vec4 effect( vec4 color, Image _tex, vec2 _tex_coords, vec2 screen_coords )
{
    vec4 tex = Texel(_tex, _tex_coords);
    vec2 mask_uv = ((_tex_coords * image_details) - _tex_details.xy) / _tex_details.ba;
    vec2 uv = (((_tex_coords)*(image_details)) + _tex_details.rg)/_tex_details.ba;
    if (shadow) {
        return apply_fx_mask(tex, mask_uv);
    }

    if (tex.a <= 0.0001) {
        return apply_fx_mask(tex, mask_uv);
    }

    // Luminosity delta (from your original code) helps the foil cling to midtones/highlights
    number low   = min(tex.r, min(tex.g, tex.b));
    number high  = max(tex.r, max(tex.g, tex.b));
    number delta = min(high, max(0.5, 1.0 - low));

    // Inputs
    number t = 1.*_7_heart.g;    // Drives animation/sweep speed
    number tilt = _7_heart.r;    // Drives gyroscope angle shift
    if (hovering > 0.0) { t *= 2; }
    else { t *= 0.5; }
    if (position_shader_mode >= 0.5 && hovering <= 0.0) { t *= 0.5; }
    number uv_sum = (uv.x + uv.y) * 2.0;
    number sweep_phase = t + tilt * 4.0;

    // -----------------------------------------------------------------
    // VORONOI SHATTER GENERATION
    // -----------------------------------------------------------------
    // Scale up the UVs. Higher number = smaller, more numerous shards. 
    vec2 suv = uv * 4.0; 
    vec2 i_uv = floor(suv);
    vec2 f_uv = fract(suv);

    number min_dist = 2.0;
    number second_dist = 2.0;
    number cell_val = 0.0;

    // 3x3 loop to check neighboring cells and build the geometric shards
    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 lattice = vec2(number(x), number(y));
            vec2 cell_id = i_uv + lattice;
            
            // Generate a pseudo-random point inside this cell
            vec2 offset = fract(sin(vec2(dot(cell_id, vec2(127.1, 311.7)), dot(cell_id, vec2(269.5, 183.3)))) * 43758.5453);
            
            vec2 diff = lattice + offset - f_uv;
            number dist = dot(diff, diff); // Squared distance builds the sharp edges
            
            // If this is the closest center, we belong to this shard!
            if(dist < min_dist) {
                second_dist = min_dist;
                min_dist = dist;
                // Generate a single unique random float (0.0 to 1.0) for this specific shard
                cell_val = fract(sin(dot(cell_id, vec2(12.9898, 78.233))) * 43758.5453);
            } else if (dist < second_dist) {
                second_dist = dist;
            }
        }
    }

    number edge_metric = sqrt(max(second_dist, 0.0)) - sqrt(max(min_dist, 0.0));
    number edge_aa = 1.2 / max(min(_tex_details.z, _tex_details.w), 1.0);
    number shard_mask = smoothstep(edge_aa * 0.75, edge_aa * 2.5, edge_metric);

    // -----------------------------------------------------------------
    // INDEPENDENT SHARD REFLECTIONS
    // -----------------------------------------------------------------
    // Calculate a light sweep that interacts with the shard's unique value, time, and tilt
    number sweep = sin(sweep_phase + cell_val * 10.0 + uv_sum);
    number shard_glint = pow(max(0.0, sweep), 8.0) * shard_mask; 

    // Generate a holographic rainbow color based on the shard's ID and the time
    vec3 shard_color = 0.5 + 0.5 * cos(cell_val * 6.28 + t * 2.0 + vec3(0.0, 2.0, 4.0));
    
    // Combine to create the final flashing shard
    vec3 final_foil = shard_color * shard_glint * 1.0;

    // -----------------------------------------------------------------
    // BLENDING
    // -----------------------------------------------------------------
    // Additive blend the shattered foil over the _tex
    tex.r = tex.r - 0.2*final_foil.r * delta;
    tex.g = tex.g - 0.5*final_foil.g * delta;
    // tex.b = tex.b - 0.4*final_foil.b * delta;

    return apply_fx_mask(tex, mask_uv);
}

#ifdef VERTEX
#pragma HM_INCLUDE "_0_lib/_0_position/_0_card_position.inc"
#endif
