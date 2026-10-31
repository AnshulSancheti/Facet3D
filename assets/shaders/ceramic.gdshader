shader_type spatial;
render_mode diffuse_burley;
uniform vec4 clay_color : source_color = vec4(0.45,0.48,0.62,1.0);
void fragment() {
	float grain = sin(VERTEX.x*87.0)*sin(VERTEX.y*91.0)*sin(VERTEX.z*79.0);
	ALBEDO = clay_color.rgb*(1.0+grain*0.007);
	ROUGHNESS = 0.55;
	METALLIC = 0.0;
	SPECULAR = 0.32;
}
