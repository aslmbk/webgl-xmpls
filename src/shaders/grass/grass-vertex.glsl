#define PI (3.14159265359)

uniform vec4 uGrassParams;
uniform float uTime;
uniform sampler2D uTileDataTexture;

varying vec3 vColor;
varying vec4 vGrassData;
varying vec3 vNormal;
varying vec3 vWorldPosition;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}

uvec2 murmurHash21(uint src) {
    const uint M = 0x5bd1e995u;
    uvec2 h = uvec2(1190494759u, 2147483647u);
    src *= M;
    src ^= src >> 24u;
    src *= M;
    h *= M;
    h ^= src;
    h ^= h >> 13u;
    h *= M;
    h ^= h >> 15u;
    return h;
}

// 2 outputs, 1 input
vec2 hash21(float src) {
    uvec2 h = murmurHash21(floatBitsToUint(src));
    return uintBitsToFloat((h & 0x007fffffu) | 0x3f800000u) - 1.0;
}

uint murmurHash13(uvec3 src) {
    const uint M = 0x5bd1e995u;
    uint h = 1190494759u;
    src *= M;
    src ^= src >> 24u;
    src *= M;
    h *= M;
    h ^= src.x;
    h *= M;
    h ^= src.y;
    h *= M;
    h ^= src.z;
    h ^= h >> 13u;
    h *= M;
    h ^= h >> 15u;
    return h;
}

// 1 output, 3 inputs
float hash13(vec3 src) {
    uint h = murmurHash13(floatBitsToUint(src));
    return uintBitsToFloat((h & 0x007fffffu) | 0x3f800000u) - 1.0;
}

vec2 quickHash(float p) {
    vec2 r = vec2(
        dot(vec2(p), vec2(17.43267, 23.8934543)),
        dot(vec2(p), vec2(13.98342, 37.2435232))
    );
    return fract(sin(r) * 1743.54892229);
}

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
//
// https://www.shadertoy.com/view/Xsl3Dl
vec3 hash(vec3 p) {
    p = vec3(
        dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6))
    );
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float easeOut(float x, float t) {
    return 1.0 - pow(1.0 - x, t);
}

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(vec3(c, 0, s), vec3(0, 1, 0), vec3(-s, 0, c));
}

mat3 rotateAxis(vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(
        oc * axis.x * axis.x + c,
        oc * axis.x * axis.y - axis.z * s,
        oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s,
        oc * axis.y * axis.y + c,
        oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,
        oc * axis.y * axis.z + axis.x * s,
        oc * axis.z * axis.z + c
    );
}

vec3 bezier(vec3 P0, vec3 P1, vec3 P2, vec3 P3, float t) {
    return (1.0 - t) * (1.0 - t) * (1.0 - t) * P0 +
    3.0 * (1.0 - t) * (1.0 - t) * t * P1 +
    3.0 * (1.0 - t) * t * t * P2 +
    t * t * t * P3;
}

vec3 bezierGrad(vec3 P0, vec3 P1, vec3 P2, vec3 P3, float t) {
    return 3.0 * (1.0 - t) * (1.0 - t) * (P1 - P0) +
    6.0 * (1.0 - t) * t * (P2 - P1) +
    3.0 * t * t * (P3 - P2);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    vec3 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(
            mix(
                dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0)),
                dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0)),
                u.x
            ),
            mix(
                dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0)),
                dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0)),
                u.x
            ),
            u.y
        ),
        mix(
            mix(
                dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0)),
                dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0)),
                u.x
            ),
            mix(
                dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0)),
                dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0)),
                u.x
            ),
            u.y
        ),
        u.z
    );
}

vec3 terrainHeight(vec3 worldPos) {
    return vec3(worldPos.x, noise(worldPos * 0.1) * 2.0, worldPos.z);
}

const vec3 BASE_COLOUR = vec3(0.1, 0.4, 0.04);
const vec3 TIP_COLOUR = vec3(0.5, 0.7, 0.3);

void main() {
    int GRASS_SEGMENTS = int(uGrassParams.x);
    int GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;
    float GRASS_PATCH_SIZE = uGrassParams.y;
    float GRASS_WIDTH = uGrassParams.z;
    float GRASS_HEIGHT = uGrassParams.w;

    vec2 hashedInstanceID = hash21(float(gl_InstanceID)) * 2.0 - 1.0;
    vec3 grassOffset =
        vec3(hashedInstanceID.x, 0.0, hashedInstanceID.y) * GRASS_PATCH_SIZE;

    grassOffset = terrainHeight(grassOffset);

    vec3 grassBladeWorldPosition = (modelMatrix * vec4(grassOffset, 1.0)).xyz;
    vec3 hashValue = hash(grassBladeWorldPosition);
    float grassType = saturate(hashValue.z) > 0.975 ? 1.0 : 0.0;
    grassType = 0.0;

    float angle = remap(hashValue.x, -1.0, 1.0, -PI, PI);

    vec4 tileData = texture2D(
        uTileDataTexture,
        vec2(-grassBladeWorldPosition.x, grassBladeWorldPosition.z) /
            GRASS_PATCH_SIZE *
            0.5 +
            0.5
    );

    // Stiffness
    float stiffness = mix(1.0, 0.25, grassType); // - tileData.x * 0.85;
    float tileGrassHeight =
        mix(1.0, 1.5, grassType) * remap(hashValue.x, -1.0, 1.0, 0.5, 1.0);

    // Figure out vertex id, > GRASS_VERTICES is other side
    int vertFB_ID = gl_VertexID % (GRASS_VERTICES * 2);
    int vertID = vertFB_ID % GRASS_VERTICES;

    // 0 = left, 1 = right
    int xTest = vertID & 0x1;
    int zTest = vertFB_ID >= GRASS_VERTICES ? 1 : -1;
    float xSide = float(xTest);
    float zSide = float(zTest);
    float heightPercent = float(vertID - xTest) / (float(GRASS_SEGMENTS) * 2.0);

    float width = GRASS_WIDTH;
    width *= easeOut(1.0 - heightPercent, 2.0) * tileGrassHeight;
    // width *= mix(
    //     easeOut(1.0 - heightPercent, 2.0) * tileGrassHeight,
    //     1.0,
    //     grassType
    // );
    // width *= smoothstep(0.0, 0.25, 1.0 - heightPercent);
    float height = GRASS_HEIGHT * tileGrassHeight;

    // Calculate the vertex position
    float x = (xSide - 0.5) * width;
    float y = heightPercent * height;
    float z = 0.0;

    float windStrength =
        noise(vec3(grassBladeWorldPosition.xz * 0.05, 0.0) + uTime) * 0.2;
    float windAngle = 0.0;
    vec3 windAxis = vec3(cos(windAngle), 0.0, sin(windAngle));
    float windLeanAngle = windStrength * 1.5 * heightPercent * stiffness;

    float randomLeanAnimation =
        noise(vec3(grassBladeWorldPosition.xz, uTime * 4.0)) *
        (windStrength * 0.5 + 0.125);
    float leanFactor = 1.0 + randomLeanAnimation;
    leanFactor = remap(hashValue.y, -1.0, 1.0, -0.5, 0.5) + randomLeanAnimation;
    leanFactor = 1.0;

    // Add the bezier curve for bend
    vec3 p1 = vec3(0.0);
    vec3 p2 = vec3(0.0, 0.33, 0.0);
    vec3 p3 = vec3(0.0, 0.66, 0.0);
    vec3 p4 = vec3(0.0, cos(leanFactor), sin(leanFactor));
    vec3 curve = bezier(p1, p2, p3, p4, heightPercent);

    // Calculate normal
    vec3 curveGrad = bezierGrad(p1, p2, p3, p4, heightPercent);
    mat2 curveRot90 =
        mat2(
             0.0,  1.0,
            -1.0,  0.0
        ) *
        -zSide;

    y = curve.y * height;
    z = curve.z * height;

    mat3 rotationMatrix = rotateAxis(windAxis, windLeanAngle) * rotateY(angle);
    vec3 grassLocalPosition = rotationMatrix * vec3(x, y, z) + grassOffset;
    vec3 grassLocalNormal =
        rotationMatrix * vec3(0.0, curveRot90 * curveGrad.yz);

    // Blend normal
    float distanceBlend = smoothstep(
        0.0,
        10.0,
        distance(cameraPosition, grassBladeWorldPosition)
    );
    grassLocalNormal = mix(
        grassLocalNormal,
        vec3(0.0, 1.0, 0.0),
        distanceBlend * 0.5
    );
    grassLocalNormal = normalize(grassLocalNormal);

    // Viewspace thicken
    vec4 mvPosition = modelViewMatrix * vec4(grassLocalPosition, 1.0);

    vec3 viewDir = normalize(cameraPosition - grassBladeWorldPosition);
    vec3 grassFaceNormal = rotationMatrix * vec3(0.0, 0.0, -zSide);

    float viewDotNormal = saturate(dot(grassFaceNormal, viewDir));
    float viewSpaceThickenFactor =
        easeOut(1.0 - viewDotNormal, 4.0) * smoothstep(0.0, 0.2, viewDotNormal);

    mvPosition.x +=
        viewSpaceThickenFactor * (xSide - 0.5) * width * 0.5 * -zSide;

    gl_Position = projectionMatrix * mvPosition;

    // vColor = mix(BASE_COLOUR, TIP_COLOUR, heightPercent);
    float noiseValue = noise(grassBladeWorldPosition * 0.05);
    float hashColour = hash13(grassBladeWorldPosition);
    vColor = vec3(remap(round(hashColour * 4.0) / 4.0, 0.0, 1.0, 0.5, 1.0));
    vColor *=
        mix(
            vec3(1.0),
            vec3(1.0, 1.0, 0.25),
            remap(noiseValue, -1.0, 1.0, 0.0, 1.0)
        ) *
        0.5;

    vGrassData = vec4(x, heightPercent, xSide, grassType);
    vNormal = normalize((modelMatrix * vec4(grassLocalNormal, 0.0)).xyz);
    vWorldPosition = (modelMatrix * vec4(grassLocalPosition, 1.0)).xyz;
}
