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
	ALBEDO = clamp(source.rgb * ramp_tint * ramp_value, vec3(0.0), vec3(1.0));
	ALPHA = source.a;
	ROUGHNESS = 0.92;
}
