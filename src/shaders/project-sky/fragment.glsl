#define PI (3.14159265359)
#define CLOUDS_NUM (10.0)
#define STARS_NUM (64.0)
#define DAY_LENGTH (24.0)
#define STAR_COLOR (vec3(1.0))
#define SUN_COLOR (vec3(0.84, 0.62, 0.26))
#define SUN_GLOW_COLOR (vec3(0.9, 0.85, 0.47))
#define MOON_COLOR (vec3(1.0))
#define CLOUD_COLOR (vec3(1.0))
#define CLOUD_SHADOW_COLOR (vec3(0.0))

uniform float uTime;
uniform vec2 uResolution;

varying vec2 vUv;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

float sdfCircle(vec2 position, float radius) {
    return length(position) - radius;
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

float hash(vec2 v) {
    float t = dot(v, vec2(36.5323, 73.945));
    return sin(t);
}

float easeOut(float x, float p) {
    return 1.0 - pow(1.0 - x, p);
}

// Taken from: https://easings.net/
// Translated to GLSL
float easeOutBounce(float x) {
    const float n1 = 7.5625;
    const float d1 = 2.75;

    if (x < 1.0 / d1) {
        return n1 * x * x;
    } else if (x < 2.0 / d1) {
        x -= 1.5 / d1;
        return n1 * x * x + 0.75;
    } else if (x < 2.5 / d1) {
        x -= 2.25 / d1;
        return n1 * x * x + 0.9375;
    } else {
        x -= 2.625 / d1;
        return n1 * x * x + 0.984375;
    }
}

vec3 DrawBackground(float dayTime) {
    vec3 morning = mix(
        vec3(0.44, 0.64, 0.84),
        vec3(0.34, 0.51, 0.94),
        smoothstep(0.0, 1.0, pow(vUv.x * vUv.y, 0.5))
    );
    vec3 midday = mix(
        vec3(0.42, 0.58, 0.75),
        vec3(0.36, 0.46, 0.82),
        smoothstep(0.0, 1.0, pow(vUv.x * vUv.y, 0.5))
    );
    vec3 evening = mix(
        vec3(0.82, 0.51, 0.25),
        vec3(0.88, 0.71, 0.39),
        smoothstep(0.0, 1.0, pow(vUv.x * vUv.y, 0.5))
    );

    vec3 night = mix(
        vec3(0.07, 0.1, 0.19),
        vec3(0.19, 0.2, 0.29),
        smoothstep(0.0, 1.0, pow(vUv.x * vUv.y, 0.5))
    );

    vec3 color;
    if (dayTime < DAY_LENGTH * 0.25) {
        color = mix(
            morning,
            midday,
            smoothstep(0.0, DAY_LENGTH * 0.25, dayTime)
        );
    } else if (dayTime < DAY_LENGTH * 0.5) {
        color = mix(
            midday,
            evening,
            smoothstep(DAY_LENGTH * 0.25, DAY_LENGTH * 0.5, dayTime)
        );
    } else if (dayTime < DAY_LENGTH * 0.75) {
        color = mix(
            evening,
            night,
            smoothstep(DAY_LENGTH * 0.5, DAY_LENGTH * 0.75, dayTime)
        );
    } else {
        color = mix(
            night,
            morning,
            smoothstep(DAY_LENGTH * 0.75, DAY_LENGTH, dayTime)
        );
    }

    return color;
}

float sdfCloud(vec2 pixelCoords) {
    float puff1 = sdfCircle(pixelCoords, 100.0);
    float puff2 = sdfCircle(pixelCoords - vec2(120.0, -10.0), 75.0);
    float puff3 = sdfCircle(pixelCoords + vec2(120.0, 10.0), 75.0);

    return min(puff1, min(puff2, puff3));
}

float sdfMoon(vec2 pixelCoords) {
    return opSubtraction(
        sdfCircle(pixelCoords + vec2(50.0, 0.0), 80.0),
        sdfCircle(pixelCoords, 80.0)
    );
}

float sdfStar(vec2 p, float r, float rf) {
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x, k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0, 1);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

void main() {
    vec2 pixelCoords = vUv * uResolution;
    float dayTime = mod(uTime + 8.0, DAY_LENGTH);
    vec3 color = DrawBackground(dayTime);

    for (float i = 0.0; i < STARS_NUM; i += 1.0) {
        float hashSample = hash(vec2(i * 13.0)) * 0.5 + 0.5;

        float t = saturate(
            inverseLerp(
                dayTime + hashSample * 0.5,
                DAY_LENGTH * 0.5,
                DAY_LENGTH * 0.5 + 1.5
            )
        );

        float fade = 0.0;
        if (dayTime > DAY_LENGTH * 0.9) {
            fade = saturate(
                inverseLerp(
                    dayTime - hashSample * 0.25,
                    DAY_LENGTH * 0.9,
                    DAY_LENGTH * 0.95
                )
            );
        }

        float size = mix(3.5, 2.0, hash(vec2(i * hashSample, uTime * 0.01)));
        vec2 offset =
            vec2(i * 100.0, 0.0) +
            vec2(150.0, uResolution.y * 0.5) * hash(vec2(i, uTime * 0.0001));
        offset += mix(
            vec2(0.0, uResolution.y * 1.2),
            vec2(0.0),
            easeOutBounce(t)
        );

        float rot = mix(-PI, PI, hashSample);

        vec2 pos = pixelCoords - offset;
        pos.x = mod(pos.x, uResolution.x);
        pos = pos - uResolution * vec2(0.5, 0.5);
        pos = rotate2D(rot) * pos;
        pos *= size;

        float star = sdfStar(pos, 10.0, 2.0);
        vec3 starColor = mix(STAR_COLOR, color, smoothstep(0.0, 2.0, star));
        starColor += mix(2.0, 0.0, pow(smoothstep(-5.0, 15.0, star), 0.25));

        color = mix(starColor, color, fade);
    }

    // Sun
    if (dayTime < DAY_LENGTH * 0.75) {
        float t = saturate(inverseLerp(dayTime, 0.0, 1.0));
        vec2 offset =
            vec2(200.0, uResolution.y * 0.8) +
            mix(vec2(0.0, 400.0), vec2(0.0), easeOut(t, 5.0));

        if (dayTime > DAY_LENGTH * 0.5) {
            t = saturate(
                inverseLerp(dayTime, DAY_LENGTH * 0.5, DAY_LENGTH * 0.5 + 1.0)
            );
            offset =
                vec2(200.0, uResolution.y * 0.8) +
                mix(vec2(0.0), vec2(0.0, 400.0), t);
        }

        vec2 pos = pixelCoords - offset;
        float sun = sdfCircle(pos, 100.0);
        color = mix(SUN_COLOR, color, smoothstep(0.0, 2.0, sun));
        // color = mix(color, SUN_GLOW_COLOR, smoothstep(70.0, -70.0, sun));
        float sunGlow = max(0.001, sun);
        sunGlow = saturate(exp(-0.001 * sunGlow * sunGlow));
        color += mix(vec3(0.0), SUN_GLOW_COLOR, sunGlow) * 0.5;
    }

    // Moon
    if (dayTime > DAY_LENGTH * 0.5) {
        float t = saturate(
            inverseLerp(dayTime, DAY_LENGTH * 0.5, DAY_LENGTH * 0.5 + 1.5)
        );
        vec2 offset =
            uResolution * 0.8 +
            mix(vec2(0.0, 400.0), vec2(0.0), easeOutBounce(t));

        if (dayTime > DAY_LENGTH * 0.9) {
            t = saturate(
                inverseLerp(dayTime, DAY_LENGTH * 0.9, DAY_LENGTH * 0.95)
            );
            offset = uResolution * 0.8 + mix(vec2(0.0), vec2(0.0, 400.0), t);
        }

        vec2 pos = pixelCoords - offset;
        pos = rotate2D(PI * -0.2) * pos;
        float moonShadow = sdfMoon(pos + 15.0);
        color = mix(
            CLOUD_SHADOW_COLOR,
            color,
            smoothstep(-50.0, 5.0, moonShadow)
        );
        float moon = sdfMoon(pos);
        color = mix(MOON_COLOR, color, smoothstep(0.0, 2.0, moon));
        float moonGlow = sdfMoon(pos);
        color +=
            mix(MOON_COLOR, vec3(0.0), smoothstep(0.0, 8.0, moonGlow)) * 0.5;
    }

    for (float i = 0.0; i < CLOUDS_NUM; i += 1.0) {
        float hashValue = hash(vec2(i) + vec2(uTime * 0.0001));
        float size = mix(2.0, 1.0, i / CLOUDS_NUM + 0.1 * hashValue);
        float speed = size * 0.25;

        vec2 offset = vec2(
            i * 400.0 + uTime * 100.0 * speed,
            uResolution.y * 0.35 * hashValue
        );
        vec2 pos = pixelCoords - offset;

        pos = mod(pos, uResolution);
        pos = pos - uResolution * 0.5;

        float cloudShadow = sdfCloud(pos * size + 25.0) - 40.0;
        cloudShadow = smoothstep(0.0, -100.0, cloudShadow);
        color = mix(color, CLOUD_SHADOW_COLOR, cloudShadow * 0.5);

        float cloud = sdfCloud(pos * size);
        cloud = smoothstep(0.0, 1.0, cloud);
        color = mix(CLOUD_COLOR, color, cloud);
    }

    gl_FragColor = vec4(color, 1.0);
    // #include <tonemapping_fragment>
    // #include <colorspace_fragment>
}
