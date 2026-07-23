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

float smooth_value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local_point = fract(point);
	local_point = local_point * local_point * (3.0 - 2.0 * local_point);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local_point.x), mix(c, d, local_point.x), local_point.y);
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
	float grain = smooth_value_noise(UV * 18.0);
	float edge_wobble = (grain - 0.5) * (shape_mode == 1 ? 0.045 : 0.075);
	float edge_alpha = 1.0 - smoothstep(-edge_softness, edge_softness, distance_to_edge + edge_wobble);
	if (shape_mode == 2) {
		// The ribbon mesh owns the curve, while the shader owns a restrained soft
		// edge. Without this side feather every camera angle exposes a hard
		// quadrilateral and the path reads like an editor strip.
		float side_distance = abs(point.x);
		float side_alpha = 1.0 - smoothstep(0.82, 0.995, side_distance);
		float end_distance = min(UV.y, 1.0 - UV.y);
		float end_alpha = smoothstep(0.0, 0.045, end_distance);
		edge_alpha *= side_alpha;
		edge_alpha *= end_alpha;
		// A soft, directional dapple keeps the trail hand-painted without the
		// blocky checkerboard that the first pass produced. The broad term reads
		// as compacted soil variation; the fine term gives a restrained pebble
		// rhythm that survives zoom changes.
		float broad_dapple = smooth_value_noise(UV * vec2(4.0, 21.0));
		float fine_dapple = smooth_value_noise(UV * vec2(13.0, 58.0));
		grain = mix(broad_dapple, fine_dapple, 0.28);
	}
	ALBEDO = base_color.rgb * mix(0.90, 1.045, grain);
	ALPHA = base_color.a * edge_alpha;
	ROUGHNESS = 1.0;
}
