#version 330 compatibility

#define MOTION_BLUR

#ifdef MOTION_BLUR
const int MOTION_BLUR_LEVEL = 2;   // [0 1 2 3 4]
const int MOTION_BLUR_QUALITY = 1; // [0 1 2 3]

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex0; // Tracks overall scene depth maps (with hand)
uniform sampler2D depthtex1; // Tracks terrain depth maps only (ignores hand)

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
  color = texture(colortex0, texcoord);

    #ifdef MOTION_BLUR
    float depth = texture(depthtex0, texcoord).r;
    float terrainDepth = texture(depthtex1, texcoord).r;

    // Isolate the hand mask boundaries
    bool isHandModel = (depth != terrainDepth);

    float motionBlurStrength = float(MOTION_BLUR_LEVEL) * 0.25;
    int motionBlurSamples = 4 + (MOTION_BLUR_QUALITY * 4);

    // Project to World Space using terrain depth to track world block coordinates
    vec4 currentScreenPos = vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, terrainDepth * 2.0 - 1.0, 1.0);
    
    vec4 viewPos = gbufferProjectionInverse * currentScreenPos;
    viewPos /= viewPos.w;
    vec4 worldPos = gbufferModelViewInverse * viewPos;
    worldPos.xyz += cameraPosition;

    // Project back to Previous Frame
    vec4 previousSummaryPos = worldPos;
    previousSummaryPos.xyz -= previousCameraPosition;
    vec4 prevViewPos = gbufferPreviousModelView * previousSummaryPos;
    vec4 prevScreenPos = gbufferPreviousProjection * prevViewPos;
    prevScreenPos /= prevScreenPos.w;

    // Calculate screen velocity vector
    vec2 prevTexcoord = prevScreenPos.xy * 0.5 + 0.5;
    vec2 velocity = (texcoord - prevTexcoord) * motionBlurStrength;

    // --- CRITICAL LEAK FIX: BOUNDARY VELOCITY CLAMPING ---
    // Look up 2 pixels in every directional axis around the current coordinate.
    // If ANY neighboring pixel hits your hand, kill the velocity vector completely to prevent color bleeding.
    vec2 pixelSize = 2.0 / vec2(textureSize(colortex0, 0)); 
    bool nearHandBoundary = false;
    
    if (!isHandModel) {
        if (texture(depthtex0, texcoord + vec2(pixelSize.x, 0.0)).r != texture(depthtex1, texcoord + vec2(pixelSize.x, 0.0)).r) nearHandBoundary = true;
        if (texture(depthtex0, texcoord - vec2(pixelSize.x, 0.0)).r != texture(depthtex1, texcoord - vec2(pixelSize.x, 0.0)).r) nearHandBoundary = true;
        if (texture(depthtex0, texcoord + vec2(0.0, pixelSize.y)).r != texture(depthtex1, texcoord + vec2(0.0, pixelSize.y)).r) nearHandBoundary = true;
        if (texture(depthtex0, texcoord - vec2(0.0, pixelSize.y)).r != texture(depthtex1, texcoord - vec2(0.0, pixelSize.y)).r) nearHandBoundary = true;
    }

    // Completely block velocity calculation near the hand boundaries
    if (nearHandBoundary || isHandModel) {
        velocity = vec2(0.0);
    }

    // Only process blur if we are on terrain and moving
    if (terrainDepth < 1.0 && dot(velocity, velocity) > 0.000001) {
        vec3 blurredColor = vec3(0.0);
        float totalWeight = 0.0;
        
        for (int i = 0; i < motionBlurSamples; ++i) {
            vec2 offsetTexcoord = texcoord + velocity * (float(i) / float(motionBlurSamples - 1) - 0.5);
            
            if (offsetTexcoord.x >= 0.0 && offsetTexcoord.x <= 1.0 && offsetTexcoord.y >= 0.0 && offsetTexcoord.y <= 1.0) {
                float sampleHandCheck = texture(depthtex0, offsetTexcoord).r;
                float sampleTerrainCheck = texture(depthtex1, offsetTexcoord).r;
                
                // If a blur step hits a hand pixel, fallback to original pixel color
                if (sampleHandCheck != sampleTerrainCheck) {
                    blurredColor += color.rgb; 
                } else {
                    blurredColor += texture(colortex0, offsetTexcoord).rgb;
                }
                totalWeight += 1.0;
            }
        }
        
        if (totalWeight > 0.0) {
            color.rgb = blurredColor / totalWeight;
        }
    }
    #endif

  color.rgb = pow(color.rgb, vec3(1.1 / 2.2));
}
