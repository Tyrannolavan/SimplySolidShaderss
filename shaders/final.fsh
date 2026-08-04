#version 330 compatibility

 uniform sampler2D colortex0;
//  uniform sampler2D shadowtex0;

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
  // // This will show the raw shadow-map texture!
  // color.rgb = texture(shadowtex0, texcoord).rgb;
  // return;

  color = texture(colortex0, texcoord);
  color.rgb = pow(color.rgb, vec3(1.1 / 2.2));
}