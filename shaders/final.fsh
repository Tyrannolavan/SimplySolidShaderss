#version 330 compatibility

/* Fallback definitions for Iris preprocessor */
#define MOTION_BLUR
#define MOTION_BLUR_STRENGTH 0.50 // [0.00 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.00]
#define MOTION_BLUR_QUALITY 1

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform sampler2D colortex0;
uniform sampler2D depthtex0; // Everything (Hands, Items, Entities, Water, Terrain)
uniform sampler2D depthtex1; // Terrain & Entities (Excludes Hands/Items)
uniform sampler2D depthtex2; // Opaque Terrain Only

in vec2 texcoord;

layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, texcoord);

    #ifdef MOTION_BLUR
    float depth0 = texture(depthtex0, texcoord).r;
    float depth1 = texture(depthtex1, texcoord).r;
    float depth2 = texture(depthtex2, texcoord).r;

    // 1. ISOLATION CHECKS
    // Hand/Item check: depthtex0 differs from depthtex1
    bool isHandOrItem = (abs(depth0 - depth1) > 0.00001);

    // Entity / Non-terrain check: depthtex1 differs from depthtex2 (or depth is outside terrain bounds)
    // depth2 tracks solid terrain blocks specifically
    bool isEntityOrTranslucent = (abs(depth1 - depth2) > 0.00001);

    // Sky check: Avoid blurring skybox background
    bool isSky = (depth2 >= 1.0);

    // Only blur if the pixel strictly belongs to solid terrain
    bool isTerrainOnly = !isHandOrItem && !isEntityOrTranslucent && !isSky;

    float motionBlurStrength = float(MOTION_BLUR_STRENGTH);
    int motionBlurSamples = 4 + (MOTION_BLUR_QUALITY * 4);

    if (isTerrainOnly) {
        // Project Terrain to World Space
        vec4 currentScreenPos = vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, depth2 * 2.0 - 1.0, 1.0);
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

        // Multi-pixel boundary edge detection around non-terrain objects
        vec2 pixelSize = 3.0 / vec2(textureSize(colortex0, 0)); 
        bool nearNonTerrainBoundary = false;
        
        // Neighbor sample check (North, South, East, West)
        if (abs(texture(depthtex0, texcoord + vec2(pixelSize.x, 0.0)).r - texture(depthtex2, texcoord + vec2(pixelSize.x, 0.0)).r) > 0.00001) nearNonTerrainBoundary = true;
        if (abs(texture(depthtex0, texcoord - vec2(pixelSize.x, 0.0)).r - texture(depthtex2, texcoord - vec2(pixelSize.x, 0.0)).r) > 0.00001) nearNonTerrainBoundary = true;
        if (abs(texture(depthtex0, texcoord + vec2(0.0, pixelSize.y)).r - texture(depthtex2, texcoord + vec2(0.0, pixelSize.y)).r) > 0.00001) nearNonTerrainBoundary = true;
        if (abs(texture(depthtex0, texcoord - vec2(0.0, pixelSize.y)).r - texture(depthtex2, texcoord - vec2(0.0, pixelSize.y)).r) > 0.00001) nearNonTerrainBoundary = true;

        if (nearNonTerrainBoundary) {
            velocity = vec2(0.0);
        }

        // Apply Blur
        if (dot(velocity, velocity) > 0.000001) {
            vec3 blurredColor = vec3(0.0);
            float totalWeight = 0.0;
            
            for (int i = 0; i < motionBlurSamples; ++i) {
                vec2 offsetTexcoord = texcoord + velocity * (float(i) / float(motionBlurSamples - 1) - 0.5);
                
                if (offsetTexcoord.x >= 0.0 && offsetTexcoord.x <= 1.0 && offsetTexcoord.y >= 0.0 && offsetTexcoord.y <= 1.0) {
                    float sDepth0 = texture(depthtex0, offsetTexcoord).r;
                    float sDepth2 = texture(depthtex2, offsetTexcoord).r;
                    
                    // Discard samples that hit hands, items, entities, or sky
                    if (abs(sDepth0 - sDepth2) > 0.00001 || sDepth2 >= 1.0) {
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
    }
    #endif

    color.rgb = pow(color.rgb, vec3(1.1 / 2.2));
}