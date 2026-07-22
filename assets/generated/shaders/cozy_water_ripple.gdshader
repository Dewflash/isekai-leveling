shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

// Opaque stylized water for small ponds and route pools. Two low-cost waves
// move only upward-facing vertices; no screen/depth texture or refraction pass.
uniform vec4 deep_color : source_color = vec4(0.12, 0.39, 0.48, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.31, 0.70, 0.71, 1.0);
uniform vec4 foam_color : source_color = vec4(0.66, 0.86, 0.76, 1.0);

uniform vec2 wave_direction_a = vec2(0.88, 0.48);
uniform vec2 wave_direction_b = vec2(-0.34, 0.94);
uniform float wave_frequency : hint_range(0.1, 8.0, 0.05) = 1.55;
uniform float wave_speed : hint_range(0.0, 4.0, 0.05) = 0.72;
uniform float wave_height : hint_range(0.0, 0.12, 0.002) = 0.026;
uniform float flow_scale : hint_range(0.1, 8.0, 0.05) = 2.2;

uniform float foam_start : hint_range(0.1, 0.7, 0.01) = 0.40;
uniform float foam_end : hint_range(0.1, 0.75, 0.01) = 0.50;
uniform float foam_strength : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float color_motion : hint_range(0.0, 0.4, 0.01) = 0.12;

varying vec3 water_world_position;
varying float top_facing;
varying float wave_value;

void vertex() {
	vec3 world_before = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 direction_a = normalize(wave_direction_a + vec2(0.0001));
	vec2 direction_b = normalize(wave_direction_b + vec2(0.0001));
	float wave_a = sin(dot(world_before.xz, direction_a) * wave_frequency + TIME * wave_speed);
	float wave_b = sin(dot(world_before.xz, direction_b) * wave_frequency * 1.37 - TIME * wave_speed * 0.73);
	float combined_wave = wave_a * 0.68 + wave_b * 0.32;

	top_facing = smoothstep(0.48, 0.92, NORMAL.y);
	VERTEX.y += combined_wave * wave_height * top_facing;
	water_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave_value = combined_wave;
}

void fragment() {
	float moving_band = sin((water_world_position.x - water_world_position.z * 0.74) * flow_scale + TIME * wave_speed * 0.8);
	float color_mix = clamp(0.52 + moving_band * color_motion + wave_value * 0.06, 0.0, 1.0);
	vec3 water_color = mix(deep_color.rgb, shallow_color.rgb, color_mix);

	float radial_distance = length(UV - vec2(0.5));
	float edge_foam = smoothstep(foam_start, max(foam_start + 0.001, foam_end), radial_distance) * top_facing;
	water_color = mix(water_color, foam_color.rgb, edge_foam * foam_strength);
	ALBEDO = clamp(water_color, vec3(0.0), vec3(1.0));
}
