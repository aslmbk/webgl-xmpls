uniform sampler2D sizeOverLife;
uniform sampler2D colorOverLife;
uniform sampler2D twinkleOverLife;
uniform float time;
uniform float spinSpeed;

attribute float life;

varying float vAngle;
varying vec4 vColor;

void main() {
    float sampleSize = texture2D(sizeOverLife, vec2(life, 0.5)).r;
    vec4 sampleColor = texture2D(colorOverLife, vec2(life, 0.5));
    float sampleTwinkle = texture2D(twinkleOverLife, vec2(life, 0.5)).r;

    float twinkle = mix(
        1.0,
        sin(time * 20.0 + float(gl_VertexID)) * 0.5 + 0.5,
        sampleTwinkle
    );

    vec4 mvPosition = viewMatrix * modelMatrix * vec4(position, 1.0);
    gl_Position = projectionMatrix * mvPosition;
    gl_PointSize = sampleSize * 300.0;
    gl_PointSize *= 1.0 / -mvPosition.z;
    vAngle = spinSpeed * time + float(gl_VertexID) * 6.28;
    vColor = sampleColor;
    vColor.a *= twinkle;
}
