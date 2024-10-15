uniform float uTime;

varying vec3 vNormal;
varying vec3 vPosition;
varying vec3 vColor;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

void main() {
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);

    float t = sin(modelPosition.y * 20.0 + uTime * 10.0);
    t = remap(t, -1.0, 1.0, 0.0, 0.2);
    modelPosition.xyz += normal * t;

    gl_Position = projectionMatrix * viewMatrix * modelPosition;
    vNormal = (modelMatrix * vec4(normal, 0.0)).xyz;
    vPosition = modelPosition.xyz;
    vColor = mix(
        vec3(0.0, 0.0, 0.5),
        vec3(0.1, 0.5, 0.8),
        smoothstep(0.0, 0.2, t)
    );
}
