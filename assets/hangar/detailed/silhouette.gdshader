shader_type canvas_item;

uniform sampler2D silhouette : filter_linear, repeat_disable;
uniform vec2 uv_offset;
uniform vec2 uv_scale;

void fragment() {
	vec2 mask_uv = (UV - uv_offset) / uv_scale;
	vec2 edge = 3.0 / vec2(textureSize(silhouette, 0));
	float alpha = texture(silhouette, mask_uv).a;
	alpha = min(alpha, texture(silhouette, mask_uv + vec2(edge.x, 0.0)).a);
	alpha = min(alpha, texture(silhouette, mask_uv - vec2(edge.x, 0.0)).a);
	alpha = min(alpha, texture(silhouette, mask_uv + vec2(0.0, edge.y)).a);
	alpha = min(alpha, texture(silhouette, mask_uv - vec2(0.0, edge.y)).a);
	COLOR.a *= alpha;
}
