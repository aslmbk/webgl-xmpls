uniform float uTime;

varying vec3 vNormal;
varying vec3 vPosition;

mat3 rotateY(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

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

float easeInBounce(float x) {
    return 1.0 - easeOutBounce(1.0 - x);
}

float easeInOutBounce(float x) {
    return x < 0.5
        ? (1.0 - easeOutBounce(1.0 - 2.0 * x)) / 2.0
        : (1.0 + easeOutBounce(2.0 * x - 1.0)) / 2.0;
}

void main() {
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    modelPosition.xyz *= easeOutBounce(clamp(uTime - 1.0, 0.0, 1.0));
    // modelPosition.xyz *= easeInBounce(clamp(uTime, 0.0, 1.0));
    // modelPosition.xyz *= easeInOutBounce(clamp(uTime, 0.0, 1.0));

    gl_Position = projectionMatrix * viewMatrix * modelPosition;
    vNormal = (modelMatrix * vec4(normal, 0.0)).xyz;
    vPosition = modelPosition.xyz;
}
