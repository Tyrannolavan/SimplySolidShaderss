#version 330 compatibility

 out vec2 lmcoord;
 out vec2 texcoord;
 out vec4 glcolor;
 out vec3 normal;

 // Remember uniforms from before? This is calculated on the CPU, and available for any program!
 // We just tell GLSL we want to use this uniform. It always exists, no matter if we define it here.
 uniform mat4 gbufferModelViewInverse;

void main() {
  gl_Position = ftransform();
  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  glcolor = gl_Color;

   normal = gl_NormalMatrix * gl_Normal; // this gives us the normal in view space
   normal = mat3(gbufferModelViewInverse) * normal; // this converts the normal to world/player space
}