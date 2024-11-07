uniform sampler2D map;

varying float vAngle;
varying vec4 vColor;

mat2 rotate(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = rotate(vAngle) * (gl_PointCoord.xy - 0.5) + 0.5;
    vec4 color = texture2D(map, uv);
    gl_FragColor = vColor * color;
}
