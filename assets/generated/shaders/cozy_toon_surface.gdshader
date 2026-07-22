shader_type spatial;
render_mode cull_back, depth_draw_opaque, specular_disabled;

// Conservative opaque-material toon treatment for Compatibility/mobile.
// It leaves Godot's normal light pass intact and only shapes the base albedo,
// so it still works when mobile vertex lighting disables custom light().
uniform vec4 base_color : source_color = vec4(0.62, 0.42, 0.28, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_vertex_color = false;

uniform vec3 key_light_direction = vec3(-0.42, 0.84, 0.34);
uniform vec4 shadow_tint : source_color = vec4(0.72, 0.82, 0.78, 1.0);
uniform vec4 light_tint : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform float step_center : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float step_softness : hint_range(0.01, 0.35, 0.01) = 0.12;
uniform float shadow_value : hint_range(0.35, 1.0, 0.01) = 0.72;
uniform float light_value : hint_range(0.75, 1.25, 0.01) = 1.04;

uniform float saturation : hint_range(0.5, 1.5, 0.01) = 1.08;
uniform float contrast : hint_range(0.75, 1.35, 0.01) = 1.06;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.9;
uniform float rim_strength : hint_range(0.0, 0.4, 0.01) = 0.08;

varying vec3 world_normal;

vec3 apply_chroma(vec3 color) {
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	vec3 saturated = mix(vec3(luminance), color, saturation);
	return clamp((saturated - vec3(0.5)) * contrast + vec3(0.5), vec3(0.0), vec3(1.0));
}

void vertex() {
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

	vec3 light_direction = normalize(key_light_direction);
	float half_lambert = dot(normalize(world_normal), light_direction) * 0.5 + 0.5;
	float ramp = smoothstep(step_center - step_softness, step_center + step_softness, half_lambert);
	vec3 ramp_tint = mix(shadow_tint.rgb, light_tint.rgb, ramp);
	float ramp_value = mix(shadow_value, light_value, ramp);

	ALBEDO = clamp(apply_chroma(source.rgb) * ramp_tint * ramp_value, vec3(0.0), vec3(1.0));
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	RIM = rim_strength;
	RIM_TINT = 1.0;
}
