uniform float uTime;
uniform vec2 uResolution;

varying vec2 vUv;

vec3 RED = vec3(1.0, 0.25, 0.25);
vec3 GREEN = vec3(0.25, 1.0, 0.25);
vec3 BLUE = vec3(0.25, 0.25, 1.0);
vec3 YELLOW = vec3(1.0, 1.0, 0.5);
vec3 PURPLE = vec3(1.0, 0.25, 1.0);

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

vec3 BackgroundColor() {
    float distFromCenter = length(abs(vUv - 0.5));
    float vignette = 1.0 - distFromCenter;
    vignette = smoothstep(0.0, 0.7, vignette);
    vignette = remap(vignette, 0.0, 1.0, 0.3, 1.0);
    return vec3(vignette);
}

vec3 drawGrid(vec3 color, vec3 lineColor, float cellSpacing, float lineWidth) {
    vec2 center = vUv - 0.5;
    vec2 cellPosition = abs(
        fract(center * uResolution / vec2(cellSpacing)) - 0.5
    );
    float distToEdge =
        (0.5 - max(cellPosition.x, cellPosition.y)) * cellSpacing;
    float lines = smoothstep(0.0, lineWidth, distToEdge);

    color = mix(lineColor, color, lines);

    return color;
}

float sdfCircle(vec2 position, float radius) {
    return length(position) - radius;
}

float sdfLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

    return length(pa - ba * h);
}

float sdfBox(vec2 position, vec2 size) {
    vec2 halfSize = size * 0.5;
    vec2 q = abs(position) - halfSize;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

// Inigo Quilez
// https://iquilezles.org/articles/distfunctions2d/
float sdfHexagon(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

float sdfTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r / k;
    if (p.x + k * p.y > 0.0) p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    p.x -= clamp(p.x, -2.0 * r, 0.0);
    return -length(p) * sign(p.y);
}

mat2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

float opIntersection(float d1, float d2) {
    return max(d1, d2);
}

float softMax(float a, float b, float k) {
    return log(exp(k * a) + exp(k * b)) / k;
}

float softMin(float a, float b, float k) {
    return -softMax(-a, -b, k);
}

float softMinValue(float a, float b, float k) {
    float h = exp(-b * k) / (exp(-a * k) + exp(-b * k));
    // float h = remap(a - b, -1.0 / k, 1.0 / k, 0.0, 1.0);
    return h;
}

void main() {
    vec2 pixelCoords = (vUv - 0.5) * uResolution;
    vec3 color = BackgroundColor();
    color = drawGrid(color, vec3(0.5), 10.0, 1.0);
    color = drawGrid(color, vec3(0.0), 100.0, 2.0);

    float a = sdfCircle(pixelCoords + vec2(-450.0), 100.0);
    color = mix(RED * 0.5, color, step(0.0, a));
    color = mix(RED, color, smoothstep(-3.0, -2.0, a));

    float b = sdfLine(
        pixelCoords + 450.0,
        vec2(-100.0, -50.0),
        vec2(200.0, -75.0)
    );
    color = mix(GREEN, color, step(5.0, b));

    float c = sdfBox(pixelCoords + vec2(450.0, -450.0), vec2(300.0, 100.0));
    color = mix(BLUE, color, step(0.0, c));

    float d = sdfHexagon(pixelCoords + vec2(-440.0, 450.0), 100.0);
    color = mix(PURPLE, color, step(0.0, d));

    float e = sdfTriangle(pixelCoords + vec2(0.0, -450.0), 100.0);
    color = mix(YELLOW, color, step(0.0, e));

    float box = sdfBox(rotate2D(uTime * 0.5) * pixelCoords, vec2(400.0, 150.0));
    float f1 = sdfCircle(pixelCoords - vec2(-300.0, -150.0), 150.0);
    float f2 = sdfCircle(pixelCoords - vec2(300.0, -150.0), 150.0);
    float f3 = sdfCircle(pixelCoords - vec2(0.0, 200.0), 150.0);
    float f = opUnion(opUnion(f1, f2), f3);

    vec3 sdfColor = mix(
        RED,
        BLUE,
        smoothstep(0.0, 1.0, softMinValue(box, f, 0.01))
    );

    f = softMin(box, f, 0.05);
    color = mix(sdfColor * 0.5, color, smoothstep(-1.0, 1.0, f));
    color = mix(sdfColor, color, smoothstep(-5.0, 0.0, f));

    gl_FragColor = vec4(color, 1.0);
    // #include <tonemapping_fragment>
    // #include <colorspace_fragment>
}
