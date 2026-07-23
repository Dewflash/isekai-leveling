shader_type spatial;
render_mode unshaded, cull_disabled;

// The authored plate remains a fixed-scale 64m x 48m composition. The larger
// quad is only a coverage skirt for camera travel; clamping the forest edge
// keeps that skirt quiet instead of stretching or visibly repeating the art.
uniform sampler2D ground_texture : source_color, filter_linear;
uniform vec2 authored_size = vec2(44.0, 32.0);
uniform vec2 plate_size = vec2(64.0, 48.0);
uniform vec3 forest_skirt_color : source_color = vec3(0.08, 0.16, 0.11);

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
	ALBEDO = mix(authored_color, forest_skirt_color, skirt_mix);
	ROUGHNESS = 1.0;
}
