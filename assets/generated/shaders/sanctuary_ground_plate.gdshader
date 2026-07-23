shader_type spatial;
render_mode unshaded, cull_disabled;

// The authored plate is mapped across the full 80m x 60m Sanctuary coverage
// quad. Keeping authored and physical extents equal prevents the focused
// camera from exposing a procedural fallback boundary at the plate edge.
uniform sampler2D ground_texture : source_color, filter_linear;
uniform vec2 authored_size = vec2(80.0, 60.0);
uniform vec2 plate_size = vec2(80.0, 60.0);
uniform vec3 forest_skirt_color : source_color = vec3(0.08, 0.16, 0.11);
uniform vec4 lighting_tint : source_color = vec4(1.0);
uniform float lighting_value : hint_range(0.50, 1.20, 0.01) = 1.0;

void fragment() {
	vec2 authored_uv = (UV - vec2(0.5)) * plate_size / authored_size + vec2(0.5);
	vec2 clamped_uv = clamp(authored_uv, vec2(0.0), vec2(1.0));
	vec3 authored_color = texture(ground_texture, clamped_uv).rgb;
	// Sampling a clamped edge row directly produces stretched bands when the
	// camera looks beyond the authored rectangle. Switch to a quiet forest skirt
	// as soon as the fragment leaves the measured art rectangle; no edge row can
	// leak into the camera coverage area.
	float outside_distance = max(max(-authored_uv.x, authored_uv.x - 1.0), max(-authored_uv.y, authored_uv.y - 1.0));
	float skirt_mix = step(0.0, outside_distance);
	ALBEDO = clamp(mix(authored_color, forest_skirt_color, skirt_mix) * lighting_tint.rgb * lighting_value, vec3(0.0), vec3(1.0));
	ROUGHNESS = 1.0;
}
