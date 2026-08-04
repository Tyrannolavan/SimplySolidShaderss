#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16F;
const int colortex2Format = RGBA16F;
*/

uniform sampler2D depthtex0;
uniform int dimension;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 sunlightColor = vec3(1.0);
const vec3 ambientColor = vec3(0.5);

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {

  // Yes
  vec2 lightmap = texture(colortex1, texcoord).xy;
  vec3 encodedNormal = texture(colortex2, texcoord).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);
  vec3 lightVector = normalize(shadowLightPosition);
  vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

  color = texture(colortex0, texcoord);
  color.rgb = clamp(color.rgb, 0.0, 1.0);
  color.rgb = pow(color.rgb, vec3(2.2));

  // Sky Color and Brightness yee
  float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {

      // Nether Sky
      if (dimension == -1) {
        color.rgb *= 2.0;
      } 
      
      // End Sky
      else if (dimension == 2) {
        color.rgb *= 2.0;
      }

        color.rgb = pow(color.rgb, vec3 (1.0/2.2));
        return; // let's skip whats beneath us - the lighting apply logic!
    }

  // Base Minecraft Brightness :3
  vec3 blocklight = lightmap.x * blocklightColor;
  vec3 skylight = lightmap.y * skylightColor;
  vec3 ambient = ambientColor;
  vec3 sunlight = sunlightColor * clamp(dot(worldLightVector, normal), 1.2, 0.0) * lightmap.y;
  vec3 tint = vec3(0.4, 0.2, 0.1); // The tint :3

  // Final Color Out :D
  color.rgb *= blocklight + skylight + ambient + sunlight + tint;
  color.a = 1.0;
}