shader_type canvas_item;
render_mode unshaded;
uniform vec3 palette[16];
void fragment(){
	vec4 source=COLOR;
	if(source.a<0.5){discard;}
	float distance_best=100.0;
	vec3 picked=palette[0];
	for(int i=0;i<16;i++){
		vec3 delta=source.rgb-palette[i];
		float d=dot(delta,delta);
		if(d<distance_best){distance_best=d;picked=palette[i];}
	}
	COLOR=vec4(picked,1.0);
}
