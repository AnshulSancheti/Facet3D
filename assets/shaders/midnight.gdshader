shader_type canvas_item;
render_mode unshaded;
uniform bool sculpture_visible = true;
void fragment() {
	vec2 uv = UV;
	vec3 color = mix(vec3(0.055,0.083,0.145),vec3(0.18,0.21,0.30),smoothstep(0.0,1.0,uv.y));
	vec2 halo = (uv-vec2(0.45,0.46))*vec2(1.0,0.72);
	color += vec3(0.085,0.078,0.12)*exp(-dot(halo,halo)*9.0);
	// Painted pool of reflected moonlight and a broad, soft floating shadow.
	if (sculpture_visible) {
		vec2 pool = (uv-vec2(0.5,0.73))*vec2(1.0,5.6);
		color += vec3(0.065,0.09,0.105)*exp(-dot(pool,pool)*14.0);
		vec2 shadow = (uv-vec2(0.5,0.735))*vec2(1.0,8.0);
		color *= 1.0-0.26*exp(-dot(shadow,shadow)*28.0);
	}
	float grain = fract(sin(dot(FRAGCOORD.xy,vec2(12.9898,78.233)))*43758.5453);
	color += (grain-0.5)*0.006;
	float vignette = smoothstep(0.25,0.85,distance(uv,vec2(0.5)));
	COLOR = vec4(color*(1.0-vignette*0.22),1.0);
}
