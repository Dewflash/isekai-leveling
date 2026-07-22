shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

// Visual-only shell for pickups, caches, and capstones. Apply to a duplicate
// mesh child, never to the authoritative base mesh or collision shape.
uniform vec4 glow_color : source_color = vec4(0.34, 0.86, 0.76, 0.72);
uniform float intensity : hint_range(0.0, 2.0, 0.02) = 1.08;
uniform float rim_power : hint_range(0.5, 8.0, 0.1) = 2.4;
uniform float minimum_fill : hint_range(0.0, 0.5, 0.01) = 0.08;
uniform float pulse_speed : hint_range(0.0, 8.0, 0.05) = 2.1;
uniform float pulse_depth : hint_range(0.0, 0.5, 0.01) = 0.16;
uniform float shell_expand : hint_range(0.0, 0.12, 0.002) = 0.018;
uniform float scan_speed : hint_range(0.0, 4.0, 0.05) = 0.55;
uniform float scan_density : hint_range(0.0, 8.0, 0.1) = 1.4;
uniform float scan_strength : hint_range(0.0, 1.0, 0.01) = 0.24;

varying float local_height;

void vertex() {
	local_height = VERTEX.y;
	VERTEX += NORMAL * shell_expand;
}

void fragment() {
	float fresnel = pow(clamp(1.0 - dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	float pulse = 1.0 - pulse_depth + (sin(TIME * pulse_speed) * 0.5 + 0.5) * pulse_depth;
	float scan_phase = fract(TIME * scan_speed + local_height * scan_density);
	float scan_up = smoothstep(0.30, 0.48, scan_phase);
	float scan_down = 1.0 - smoothstep(0.52, 0.70, scan_phase);
	float scan = scan_up * scan_down;
	float shell_mask = max(minimum_fill, fresnel) * (1.0 + scan * scan_strength);

	vec3 glow = glow_color.rgb * intensity * pulse;
	ALBEDO = glow;
	EMISSION = glow;
	ALPHA = clamp(glow_color.a * shell_mask * pulse, 0.0, 1.0);
}
