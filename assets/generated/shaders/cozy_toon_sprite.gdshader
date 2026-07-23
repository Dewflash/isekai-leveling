shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, specular_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_disable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec3 key_light_direction = vec3(-0.42, 0.84, 0.34);
uniform vec4 shadow_tint : source_color = vec4(0.72, 0.82, 0.78, 1.0);
uniform vec4 light_tint : source_color = vec4(1.0, 0.94, 0.82, 1.0);
uniform float step_center : hint_range(0.0, 1.0, 0.01) = 0.52;
uniform float step_softness : hint_range(0.01, 0.35, 0.01) = 0.12;
uniform float shadow_value : hint_range(0.35, 1.0, 0.01) = 0.72;
uniform float light_value : hint_range(0.75, 1.25, 0.01) = 1.04;
// World-clock grade is supplied by the Sanctuary presentation layer. Keeping
// it in the authored sprite shader makes illustrated buildings and props move
// with the same day/night state as the ground instead of remaining at noon.
uniform vec4 world_lighting_tint : source_color = vec4(1.0);
uniform float world_lighting_value : hint_range(0.50, 1.20, 0.01) = 1.0;
// Construction presentation is an optional per-sprite layer. A value of zero
// preserves the operational toon treatment; one renders a blueprint envelope;
// two reveals an authored silhouette from the ground up as materials arrive.
uniform int construction_mode = 0;
uniform float construction_progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 construction_outline_color : source_color = vec4(0.46, 1.0, 0.88, 1.0);
uniform vec4 construction_fill_color : source_color = vec4(0.84, 0.94, 0.78, 1.0);
uniform vec4 construction_grid_color : source_color = vec4(0.46, 1.0, 0.88, 1.0);
uniform float construction_outline_strength : hint_range(0.0, 1.0, 0.01) = 0.92;
uniform float construction_grid_scale : hint_range(1.0, 32.0, 1.0) = 10.0;

varying vec3 key_light_direction_view;

void vertex() {
	// material_override replaces Sprite3D's generated billboard material. Rebuild
	// the full-camera billboard here so every illustrated card keeps its authored
	// world height/scale under the fixed 3/4 camera instead of becoming an oblique
	// plane. Preserve each node's measured local scale on the camera basis.
	vec3 object_scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);
	mat4 billboard_model = MODEL_MATRIX;
	billboard_model[0] = vec4(normalize(INV_VIEW_MATRIX[0].xyz) * object_scale.x, 0.0);
	billboard_model[1] = vec4(normalize(INV_VIEW_MATRIX[1].xyz) * object_scale.y, 0.0);
	billboard_model[2] = vec4(normalize(INV_VIEW_MATRIX[2].xyz) * object_scale.z, 0.0);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard_model;
	// NORMAL is view-space in fragment(). Convert the authoritative world-space
	// key direction once per vertex so the ramp does not change with camera yaw.
	key_light_direction_view = normalize((VIEW_MATRIX * vec4(key_light_direction, 0.0)).xyz);
}

void fragment() {
	// Sprite3D modulation/tint is supplied through COLOR. Keep it in the
	// shader contract so blueprint ghosts, construction-stage tinting, and
	// runtime fade transitions remain visible instead of being discarded by
	// the custom material.
	vec4 source = texture(albedo_texture, UV) * base_color * COLOR;
	float half_lambert = dot(normalize(NORMAL), normalize(key_light_direction_view)) * 0.5 + 0.5;
	float ramp = smoothstep(step_center - step_softness, step_center + step_softness, half_lambert);
	vec3 ramp_tint = mix(shadow_tint.rgb, light_tint.rgb, ramp);
	float ramp_value = mix(shadow_value, light_value, ramp);
	vec3 lit_color = clamp(source.rgb * ramp_tint * ramp_value * world_lighting_tint.rgb * world_lighting_value, vec3(0.0), vec3(1.0));
	if (construction_mode == 0) {
		ALBEDO = lit_color;
		ALPHA = source.a;
	} else {
		vec2 texel = 1.0 / vec2(textureSize(albedo_texture, 0));
		float neighbour_alpha = 0.0;
		neighbour_alpha = max(neighbour_alpha, texture(albedo_texture, UV + vec2(texel.x * 1.5, 0.0)).a);
		neighbour_alpha = max(neighbour_alpha, texture(albedo_texture, UV - vec2(texel.x * 1.5, 0.0)).a);
		neighbour_alpha = max(neighbour_alpha, texture(albedo_texture, UV + vec2(0.0, texel.y * 1.5)).a);
		neighbour_alpha = max(neighbour_alpha, texture(albedo_texture, UV - vec2(0.0, texel.y * 1.5)).a);
		float silhouette_edge = clamp(neighbour_alpha - source.a, 0.0, 1.0);
		float grid_line = max(
			step(0.92, fract(UV.x * construction_grid_scale)),
			step(0.92, fract(UV.y * construction_grid_scale))
		);
		if (construction_mode == 1) {
			// Blueprint mode is an authored silhouette envelope, not a generic
			// rectangle. The source alpha defines the exact building shape and the
			// grid/edge accents explain that the site is still unbuilt.
			ALBEDO = mix(construction_grid_color.rgb, construction_outline_color.rgb, silhouette_edge);
			ALPHA = max(source.a * 0.16, silhouette_edge * construction_outline_strength);
			ALPHA = max(ALPHA, grid_line * source.a * 0.38);
		} else {
			float reveal = smoothstep(1.0 - construction_progress - 0.055, 1.0 - construction_progress + 0.055, UV.y);
			float reveal_line = 1.0 - smoothstep(0.0, 0.045, abs(UV.y - (1.0 - construction_progress)));
			vec3 partial_color = mix(construction_fill_color.rgb, lit_color, reveal * 0.72);
			ALBEDO = mix(construction_outline_color.rgb, partial_color, reveal);
			ALPHA = max(source.a * mix(0.20, 0.92, reveal), silhouette_edge * construction_outline_strength);
			ALPHA = max(ALPHA, reveal_line * source.a * 0.86);
			ALPHA = max(ALPHA, grid_line * source.a * (1.0 - reveal) * 0.36);
		}
		ALPHA *= COLOR.a;
	}
	ROUGHNESS = 0.92;
}
