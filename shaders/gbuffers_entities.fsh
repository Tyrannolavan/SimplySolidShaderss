 #version 330 compatibility

//  uniform sampler2D lightmap;
 uniform sampler2D gtexture;

 uniform float alphaTestRef = 0.1;

 in vec2 lmcoord;
 in vec2 texcoord;
 in vec4 glcolor;

 /* RENDERTARGETS: 0,1 */
 layout(location = 0) out vec4 color;
 layout(location = 1) out vec4 lightLevelData;


void main() {

  vec4 tex = texture(gtexture, texcoord) * glcolor;

    if (tex.a < alphaTestRef) {
        discard;
    }

  color = tex;
  
  lightLevelData = vec4(lmcoord, 0.0, 1.0);
}