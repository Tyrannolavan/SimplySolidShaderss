#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;

uniform float alphaTestRef = 0.1;

uniform mat4 gbufferModelViewInverse;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

in vec3 viewNormal;
in vec3 viewPos;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color *= texture(lightmap, lmcoord);
	if (color.a < alphaTestRef) {
		discard;
	}

	vec3 N = normalize(viewNormal);
	vec3 V = normalize(-viewPos);

	float fresnel = pow(1.0 - max(dot(N, V), 0.0), 5.0);

	vec3 reflectDir = reflect(-V, N);
	vec3 worldReflect = mat3(gbufferModelViewInverse) * reflectDir;

	vec3 fakeSkyColor = mix(vec3(0.4, 0.6, 0.9), vec3(0.7, 0.85, 1.0), max(worldReflect.y, 0.0));

	color.rgb = mix(color.rgb, fakeSkyColor, fresnel * 0.25);
}
