 #version 330 compatibility

 uniform sampler2D gtexture;

 uniform float alphaTestRef = 1.0;

 in vec2 lmcoord;
 in vec2 texcoord;
 in vec4 glcolor;

 /* RENDERTARGETS: 0,1 */
 layout(location = 0) out vec4 color;
 layout(location = 1) out vec4 lightLevelData;


void main() {
  color = texture(gtexture, texcoord) * glcolor;

   lightLevelData = vec4(lmcoord, 0.0, 1.0); // this will write to buffer #1, as we defined above!

    if (color.a < alphaTestRef) {
        discard;
    }
 }