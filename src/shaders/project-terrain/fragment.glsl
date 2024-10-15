varying vec2 vUv;
uniform vec2 uResolution;
uniform float uTime;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

float sdfSphere(vec3 position, float radius) {
    return length(position) - radius;
}

float sdfBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdfFloor(vec3 position) {
    return position.y;
}

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/
//
// https://www.shadertoy.com/view/lsf3WH
// SimonDev: Renamed function to "Math_Random" from "hash"
float Math_Random(
    vec2 p // replace this by something better
) {
    p = 50.0 * fract(p * 0.3183099 + vec2(0.71, 0.113));
    return -1.0 + 2.0 * fract(p.x * p.y * (p.x + p.y));
}

float noise(vec2 coords) {
    vec2 texSize = vec2(1.0);
    vec2 pc = coords * texSize;
    vec2 base = floor(pc);

    float s1 = Math_Random((base + vec2(0.0, 0.0)) / texSize);
    float s2 = Math_Random((base + vec2(1.0, 0.0)) / texSize);
    float s3 = Math_Random((base + vec2(0.0, 1.0)) / texSize);
    float s4 = Math_Random((base + vec2(1.0, 1.0)) / texSize);

    vec2 f = smoothstep(0.0, 1.0, fract(pc));

    float px1 = mix(s1, s2, f.x);
    float px2 = mix(s3, s4, f.x);
    float result = mix(px1, px2, f.y);
    return result;
}

float noiseFBM(vec2 p, int octaves, float persistence, float lacunarity) {
    float amplitude = 0.5;
    float total = 0.0;

    for (int i = 0; i < octaves; ++i) {
        float noiseValue = noise(p);
        total += noiseValue * amplitude;
        amplitude *= persistence;
        p = p * lacunarity;
    }

    return total;
}

struct MaterialData {
    vec3 color;
    float dist;
};

vec3 RED = vec3(1.0, 0.0, 0.0);
vec3 GREEN = vec3(0.0, 1.0, 0.0);
vec3 BLUE = vec3(0.0, 0.0, 1.0);
vec3 YELLOW = vec3(1.0, 1.0, 0.0);
vec3 PURPLE = vec3(1.0, 0.0, 1.0);
vec3 GRAY = vec3(0.5, 0.5, 0.5);
vec3 WHITE = vec3(1.0, 1.0, 1.0);
vec3 LAND_COLOR = vec3(0.33, 0.26, 0.18);
vec3 WATER_COLOR = vec3(0.32, 0.32, 1.0);
vec3 DEEP_WATER_COLOR = vec3(0.02, 0.02, 0.19);
vec3 SUN_COLOR = vec3(1.0, 0.9, 0.8);

void swapData(inout MaterialData a, float newDist, vec3 newColor) {
    a.color = mix(a.color, newColor, step(newDist, a.dist));
    a.dist = min(a.dist, newDist);
}

// Calculating the overall SDF
MaterialData map(vec3 position) {
    float waterLevel = 0.45;
    float noiseSample = noiseFBM(position.xz * 0.5, 1, 0.5, 2.0);
    noiseSample = abs(noiseSample);
    noiseSample *= 1.5;
    // noiseSample += noiseFBM(position.xz * 4.0, 6, 0.5, 2.0) * 0.1;
    // noiseSample += noiseFBM(position.xz * 5.0, 3, 0.3, 4.0) * 0.1;
    noiseSample += noiseFBM(position.xz * 12.0, 2, 0.1, 9.0) * 0.051;
    vec3 landColor = mix(
        LAND_COLOR,
        LAND_COLOR * 0.25,
        smoothstep(waterLevel - 0.05, waterLevel, noiseSample)
    );
    MaterialData result = MaterialData(landColor, position.y + noiseSample);
    vec3 waterColor = mix(
        WATER_COLOR,
        DEEP_WATER_COLOR,
        smoothstep(waterLevel - 0.05, waterLevel + 0.14, noiseSample)
    );
    waterColor = mix(
        waterColor,
        WHITE,
        smoothstep(waterLevel + 0.0125, waterLevel, noiseSample)
    );
    swapData(result, position.y + waterLevel, waterColor);
    return result;
}

MaterialData RayCast(
    vec3 cameraOrigin,
    vec3 cameraDirection,
    int numSteps,
    float startDist,
    float maxDist
) {
    // Ray Marching loop
    const float MIN_DIST = 0.00001;
    MaterialData material = MaterialData(vec3(0.0), startDist);
    MaterialData defaultMaterial = MaterialData(vec3(0.0), -1.0);

    for (int i = 0; i < numSteps; i++) {
        vec3 pos = cameraOrigin + cameraDirection * material.dist;
        MaterialData result = map(pos);

        if (abs(result.dist) < material.dist * MIN_DIST) {
            break;
        }
        material.dist += result.dist;
        material.color = result.color;
        if (material.dist > maxDist) {
            return defaultMaterial;
        }
    }

    return material;
}

vec3 CalculateNormal(vec3 pos) {
    const float EPS = 0.0001;
    vec3 n = vec3(
        map(pos + vec3(EPS, 0.0, 0.0)).dist -
            map(pos - vec3(EPS, 0.0, 0.0)).dist,
        map(pos + vec3(0.0, EPS, 0.0)).dist -
            map(pos - vec3(0.0, EPS, 0.0)).dist,
        map(pos + vec3(0.0, 0.0, EPS)).dist -
            map(pos - vec3(0.0, 0.0, EPS)).dist
    );
    return normalize(n);
}

vec3 CalculateLighting(vec3 pos, vec3 normal, vec3 lightColor, vec3 lightDir) {
    float dp = saturate(dot(normal, lightDir));
    return lightColor * dp;
}

float CalculateShadow(vec3 pos, vec3 lightDir) {
    MaterialData result = RayCast(pos, lightDir, 64, 0.01, 10.0);
    return step(result.dist, 0.0);
}

float CalculateAO(vec3 pos, vec3 normal) {
    float ao = 0.0;
    float stepSize = 0.1;
    for (float i = 0.0; i < 5.0; ++i) {
        float distFactor = 1.0 / pow(2.0, i);
        ao +=
            distFactor * (i * stepSize - map(pos + normal * i * stepSize).dist);
    }
    return 1.0 - ao;
}

// Sphere Tracing
vec3 RayMarch(vec3 cameraOrigin, vec3 cameraDirection) {
    MaterialData material = RayCast(
        cameraOrigin,
        cameraDirection,
        256,
        1.0,
        1000.0
    );
    vec3 pos = cameraOrigin + cameraDirection * material.dist;
    vec3 lightDir = normalize(vec3(-0.5, 0.2, -0.6));
    float sunFactor = pow(saturate(dot(lightDir, cameraDirection)), 8.0);

    float skyT = exp(saturate(cameraDirection.y) * -40.0);
    vec3 skyColor = mix(vec3(0.025, 0.065, 0.5), vec3(0.4, 0.5, 1.0), skyT);
    vec3 fogColor = mix(skyColor, SUN_COLOR, sunFactor);

    if (material.dist < 0.0) {
        return fogColor;
    }

    vec3 ambient = vec3(0.01);
    vec3 normal = CalculateNormal(pos);
    vec3 lighting = CalculateLighting(pos, normal, WHITE, lightDir);
    float shadowed = CalculateShadow(pos, lightDir);
    lighting *= shadowed;
    float ao = CalculateAO(pos, normal);
    lighting *= ao;

    vec3 color = material.color * (lighting + ambient);

    float fogDist = distance(cameraOrigin, pos);
    float inscatter =
        1.0 - exp(-fogDist * fogDist * mix(0.002, 0.006, sunFactor));
    float extinction = exp(-fogDist * fogDist * 0.01);
    // inscatter *= 0.005;
    // extinction *= 0.005;

    color = color * extinction + fogColor * inscatter;
    return color;
}

mat3 makeCameraMatrix(vec3 cameraOrigin, vec3 cameraLookAt, vec3 cameraUp) {
    vec3 z = normalize(cameraLookAt - cameraOrigin);
    vec3 x = normalize(cross(z, cameraUp));
    vec3 y = cross(x, z);
    return mat3(x, y, z);
}

void main() {
    vec2 pixelCoords = (vUv - 0.5) * uResolution;
    vec3 color = vec3(0.0);

    // vec3 rayDir = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));
    // vec3 rayOrigin = vec3(0.0);

    float t = uTime * 0.5;
    vec3 rayDir = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));
    vec3 rayOrigin = vec3(3.0, 0.75, -3.0) * vec3(cos(t), 1.0, sin(t));
    vec3 rayLookAt = vec3(0.0);
    mat3 camera = makeCameraMatrix(rayOrigin, rayLookAt, vec3(0.0, 1.0, 0.0));

    color = RayMarch(rayOrigin, camera * rayDir);

    color = pow(color, vec3(1.0 / 2.2));
    gl_FragColor = vec4(color, 1.0);
}
