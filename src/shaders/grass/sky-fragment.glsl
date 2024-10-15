uniform vec2 uResolution;

vec3 COLOR_LIGHT_BLUE = vec3(0.42, 0.65, 0.85);
vec3 COLOR_BRIGHT_BLUE = vec3(0.01, 0.2, 1.0);
vec3 COLOR_LIGHT_RED = vec3(0.85, 0.28, 0.28);
vec3 COLOR_DARK_YELLOW = vec3(0.25, 0.25, 0.0625);

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution.xy;

    float blueT = pow(
        smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x),
        0.5
    );
    float yellowT =
        1.0 - pow(smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x), 0.1);
    float blackT =
        1.0 - pow(smoothstep(0.0, 0.5, uv.x) * smoothstep(1.0, 0.5, uv.y), 0.2);
    blackT *= smoothstep(0.0, 1.0, uv.y) * smoothstep(1.0, 0.0, uv.x);

    vec3 color = mix(COLOR_LIGHT_BLUE, COLOR_BRIGHT_BLUE, blueT);
    color = mix(color, COLOR_DARK_YELLOW, yellowT * 0.75);
    color = mix(color, vec3(0.0), blackT * 0.75);
    color = pow(color, vec3(1.0 / 2.2));

    gl_FragColor = vec4(color, 1.0);
}
