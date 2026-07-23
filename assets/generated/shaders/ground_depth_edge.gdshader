shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

// Opaque visual-only ground treatment. It deepens patch edges and cylinder
// sides without moving vertices, changing physics, or requiring depth textures.
uniform vec4 base_color : source_color = vec4(0.44, 0.53, 0.36, 1.0);
uniform vec4 edge_color : source_color = vec4(0.27, 0.35, 0.27, 1.0);
uniform float edge_width : hint_range(0.01, 0.45, 0.01) = 0.16;
uniform float side_depth : hint_range(0.35, 1.0, 0.01) = 0.72;
uniform float macro_scale : hint_range(0.02, 1.0, 0.01) = 0.22;
uniform float macro_variation : hint_range(0.0, 0.15, 0.005) = 0.045;
uniform float detail_scale : hint_range(0.15, 8.0, 0.05) = 1.85;
uniform float detail_variation : hint_range(0.0, 0.08, 0.005) = 0.025;
uniform float saturation : hint_range(0.6, 1.4, 0.01) = 1.05;
uniform float contrast : hint_range(0.75, 1.3, 0.01) = 1.04;

varying vec3 world_position;
varying vec3 world_normal;

vec3 apply_chroma(vec3 color) {
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	vec3 saturated = mix(vec3(luminance), color, saturation);
	return clamp((saturated - vec3(0.5)) * contrast + vec3(0.5), vec3(0.0), vec3(1.0));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_factor = smoothstep(0.0, edge_width, edge_distance);
	float top_factor = smoothstep(0.28, 0.82, world_normal.y);

	float macro_a = sin((world_position.x + world_position.z * 0.63) * macro_scale);
	float macro_b = sin((world_position.z - world_position.x * 0.41) * macro_scale * 1.73 + 1.7);
	float variation = 1.0 + (macro_a * 0.62 + macro_b * 0.38) * macro_variation;
	// Deterministic, world-anchored dapple keeps the meadow from reading as one
	// smooth painted oval. It uses no runtime clock, texture, alpha, or screen sampling,
	// so presentation cannot drift from placement geometry or animate on pause.
	float detail_a = sin(world_position.x * detail_scale + sin(world_position.z * 1.31));
	float detail_b = cos(world_position.z * detail_scale * 1.17 + sin(world_position.x * 0.87));
	float dapple = detail_a * 0.56 + detail_b * 0.44;
	float detail = 1.0 + dapple * detail_variation;

	vec3 edge_mixed = mix(edge_color.rgb, base_color.rgb, edge_factor);
	vec3 grounded = edge_mixed * mix(side_depth, 1.0, top_factor) * variation * detail;
	ALBEDO = apply_chroma(grounded);
}
