shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_prepass_alpha;

// Presentation-only ground decal. The mesh size is the requested world-space
// extent; this shader supplies a soft ellipse for contact shadows or a rounded
// rectangle for paths/ground dressing without creating a second collision shape.
uniform vec4 base_color : source_color = vec4(0.12, 0.16, 0.12, 0.22);
uniform int shape_mode = 0; // 0 = feathered ellipse, 1 = rounded rectangle, 2 = mesh-defined ribbon
uniform float corner_radius : hint_range(0.02, 0.45, 0.01) = 0.18;
uniform float edge_softness : hint_range(0.002, 0.20, 0.002) = 0.045;
uniform float ellipse_radius : hint_range(0.60, 1.05, 0.01) = 0.92;

float hash21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}

float rounded_box_sdf(vec2 point, vec2 half_extent, float radius) {
	vec2 q = abs(point) - half_extent + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 point = UV * 2.0 - vec2(1.0);
	float distance_to_edge;
	if (shape_mode == 0) {
		distance_to_edge = length(point) - ellipse_radius;
	} else if (shape_mode == 1) {
		float radius = min(corner_radius, 0.49);
		distance_to_edge = rounded_box_sdf(point, vec2(1.0 - radius), radius);
	} else {
		distance_to_edge = -1.0;
	}
	float grain = hash21(floor(UV * 18.0));
	float edge_wobble = (grain - 0.5) * (shape_mode == 1 ? 0.065 : 0.10);
	float edge_alpha = 1.0 - smoothstep(-edge_softness, edge_softness, distance_to_edge + edge_wobble);
	if (shape_mode == 2) {
		// Keep the side boundary owned by the measured ribbon mesh. The mesh's
		// sampled points provide the organic curve; the shader adds only subtle
		// world-facing variation so the path does not read as a flat editor strip.
		grain = hash21(floor(UV * vec2(7.0, 34.0)));
	}
	ALBEDO = base_color.rgb * mix(0.94, 1.035, grain);
	ALPHA = base_color.a * edge_alpha;
	ROUGHNESS = 1.0;
}
