shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

// Shared wind for low-poly foliage surfaces or explicitly bound cutout cards.
// Alpha is discarded instead of blended, retaining depth writes and avoiding
// transparent sorting. Do not assign this to trunk or collision-only meshes.
uniform vec4 base_color : source_color = vec4(0.38, 0.52, 0.29, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;
uniform float alpha_cutoff : hint_range(0.0, 1.0, 0.01) = 0.42;

uniform bool use_uv_anchor = false;
uniform float anchor_height = 0.0;
uniform float height_span : hint_range(0.05, 12.0, 0.05) = 2.5;
uniform float uv_anchor_start : hint_range(0.0, 0.95, 0.01) = 0.08;
uniform vec2 wind_direction = vec2(0.88, 0.48);
uniform float wind_strength : hint_range(0.0, 0.3, 0.002) = 0.055;
uniform float wind_speed : hint_range(0.0, 4.0, 0.05) = 0.78;
uniform float wind_phase = 0.0;
uniform float gust_strength : hint_range(0.0, 1.0, 0.01) = 0.30;

uniform vec3 key_light_direction = vec3(-0.42, 0.84, 0.34);
uniform vec4 shadow_tint : source_color = vec4(0.64, 0.76, 0.70, 1.0);
uniform vec4 light_tint : source_color = vec4(1.0, 0.94, 0.74, 1.0);
uniform float step_center : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float step_softness : hint_range(0.01, 0.35, 0.01) = 0.14;
uniform float saturation : hint_range(0.5, 1.5, 0.01) = 1.08;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.94;

varying vec3 world_normal;

void vertex() {
	float mesh_weight = smoothstep(anchor_height, anchor_height + height_span, VERTEX.y);
	float uv_height = 1.0 - UV.y;
	float uv_weight = smoothstep(uv_anchor_start, 1.0, uv_height);
	float wind_weight = use_uv_anchor ? uv_weight : mesh_weight;
	wind_weight *= wind_weight;

	vec2 origin = MODEL_MATRIX[3].xz;
	float spatial_phase = dot(origin, vec2(0.173, 0.119)) + wind_phase;
	float primary = sin(TIME * wind_speed + spatial_phase);
	float gust = sin(TIME * wind_speed * 0.37 + spatial_phase * 1.83 + 1.2);
	float sway = (primary + gust * gust_strength) * wind_strength * wind_weight;
	vec2 direction = normalize(wind_direction + vec2(0.0001));
	VERTEX.x += direction.x * sway;
	VERTEX.z += direction.y * sway;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec4 source = base_color;
	if (use_albedo_texture) {
		source *= texture(albedo_texture, UV);
	}
	if (use_vertex_color) {
		source *= COLOR;
	}
	if (source.a < alpha_cutoff) {
		discard;
	}

	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 saturated = mix(vec3(luminance), source.rgb, saturation);
	float half_lambert = dot(normalize(world_normal), normalize(key_light_direction)) * 0.5 + 0.5;
	float ramp = smoothstep(step_center - step_softness, step_center + step_softness, half_lambert);
	vec3 tint = mix(shadow_tint.rgb, light_tint.rgb, ramp);
	ALBEDO = clamp(saturated * tint * mix(0.76, 1.04, ramp), vec3(0.0), vec3(1.0));
	ROUGHNESS = roughness;
	METALLIC = 0.0;
}
