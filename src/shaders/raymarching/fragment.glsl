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

void swapData(inout MaterialData a, float newDist, vec3 newColor) {
    a.color = mix(a.color, newColor, step(newDist, a.dist));
    a.dist = min(a.dist, newDist);
}

// Calculating the overall SDF
MaterialData map(vec3 position) {
    float dist = sdfFloor(position - vec3(0.0, -2.0, 0.0));
    MaterialData result = MaterialData(GRAY, dist);
    dist = sdfSphere(position - vec3(-3.0, 0.0, 5.0), 1.0);
    swapData(result, dist, RED);
    dist = sdfBox(position - vec3(-3.0, 1.5, 5.0), vec3(1.0));
    swapData(result, dist, BLUE);
    dist = sdfBox(position - vec3(1.5, -1.5, 3.0), vec3(0.5));
    swapData(result, dist, GREEN);
    dist = sdfBox(position - vec3(-1.5, -1.4, 3.0), vec3(0.5));
    swapData(result, dist, YELLOW);
    dist = sdfBox(
        position - vec3(3.0, 1.0, 20.0 + sin(uTime) * 18.0),
        vec3(2.0)
    );
    swapData(result, dist, PURPLE);
    return result;
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
    float d = 0.01;
    for (int i = 0; i < 64; ++i) {
        float distToScene = map(pos + lightDir * d).dist;
        if (distToScene < 0.001) {
            return 0.0;
        }
        d += distToScene;
    }
    return 1.0;
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
    vec3 pos;
    vec3 skyColor = vec3(0.0, 0.35, 1.0);
    MaterialData material = MaterialData(vec3(0.0), 0.0);
    const int NUM_STEPS = 256;
    const float MAX_DIST = 1000.0;
    const float MIN_DIST = 0.00005;
    for (int i = 0; i < NUM_STEPS; i++) {
        pos = cameraOrigin + cameraDirection * material.dist;
        MaterialData result = map(pos);

        if (result.dist < MIN_DIST) {
            break;
        }
        material.dist += result.dist;
        material.color = result.color;
        if (material.dist > MAX_DIST) {
            return skyColor;
        }
    }

    vec3 ambient = vec3(0.03);
    vec3 lightDir = normalize(vec3(1.0, 2.0, -1.0));
    vec3 normal = CalculateNormal(pos);
    vec3 lighting = CalculateLighting(pos, normal, WHITE, lightDir);
    float shadowed = CalculateShadow(pos, lightDir);
    lighting *= shadowed;
    float ao = CalculateAO(pos, normal);
    lighting *= ao;

    vec3 color = material.color * (lighting + ambient);

    float fogFactor = 1.0 - exp(-pos.z * 0.03);
    color = mix(color, skyColor, fogFactor);
    return color;
}

void main() {
    vec2 pixelCoords = (vUv - 0.5) * uResolution;
    vec3 color = vec3(0.0);

    vec3 rayDir = normalize(vec3(pixelCoords * 2.0 / uResolution.y, 1.0));
    vec3 rayOrigin = vec3(0.0);

    color = RayMarch(rayOrigin, rayDir);

    color = pow(color, vec3(1.0 / 2.2));
    gl_FragColor = vec4(color, 1.0);
}
