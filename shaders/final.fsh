#version 330 compatibility

#define MOTION_BLUR // This creates your On/Off toggle

#ifdef MOTION_BLUR
// Removing the '//' from the front makes OptiFine/Iris turn these into menu sliders automatically!
const float MOTION_BLUR_STRENGTH = 1.0; // [0.0 0.5 1.0 1.5 2.0]
const int MOTION_BLUR_SAMPLES = 8; // [4 8 12 16 24]

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

    #ifdef MOTION_BLUR
    float depth = texture(depthtex0, texcoord).r;

    // 1. Get current clip space position
    vec4 currentScreenPos = vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    
    // 2. Transform to World Space
    vec4 viewPos = gbufferProjectionInverse * currentScreenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition;

    // 3. Project back to Previous Frame
    vec4 previousSummaryPos = worldPos;
    previousSummaryPos.xyz -= previousCameraPosition;
    vec4 prevViewPos = gbufferPreviousModelView * previousSummaryPos;
    vec4 prevScreenPos = gbufferPreviousProjection * prevViewPos;
    prevScreenPos /= prevScreenPos.w;

    // 4. Calculate screen velocity vector using the menu sliders directly
    vec2 prevTexcoord = prevScreenPos.xy * 0.5 + 0.5;
    vec2 velocity = (texcoord - prevTexcoord) * MOTION_BLUR_STRENGTH;

    // 5. Accumulate samples along the velocity path
    if (depth < 1.0 && dot(velocity, velocity) > 0.000001) {
        vec3 blurredColor = color.rgb;
        float totalWeight = 1.0;
        
        for (int i = 1; i < MOTION_BLUR_SAMPLES; ++i) {
            vec2 offsetTexcoord = texcoord + velocity * (float(i) / float(MOTION_BLUR_SAMPLES - 1) - 0.5);
            if (offsetTexcoord.x >= 0.0 && offsetTexcoord.x <= 1.0 && offsetTexcoord.y >= 0.0 && offsetTexcoord.y <= 1.0) {
                blurredColor += texture(colortex0, offsetTexcoord).rgb;
                totalWeight += 1.0;
            }
        }
        color.rgb = blurredColor / totalWeight;
    }
    #endif

  color.rgb = pow(color.rgb, vec3(1.1 / 2.2));
}
