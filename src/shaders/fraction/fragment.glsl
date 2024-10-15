uniform vec2 uResolution;

varying vec2 vUv;

void main() {
    vec3 red = vec3(1.0, 0.0, 0.0);
    vec3 blue = vec3(0.0, 0.0, 1.0);
    vec3 white = vec3(1.0, 1.0, 1.0);
    vec3 black = vec3(0.0, 0.0, 0.0);
    vec3 yellow = vec3(1.0, 1.0, 0.0);

    vec3 color = vec3(0.75);

    vec2 center = vUv - 0.5;
    vec2 cell = fract(center * uResolution / 110.0);
    cell = abs(cell - 0.5);
    float distToCell = 1.0 - 2.0 * max(cell.x, cell.y);
    float cellLine = smoothstep(0.0, 0.05, distToCell);

    float xAxis = smoothstep(0.0, 0.003, abs(vUv.x - 0.5));
    float yAxis = smoothstep(0.0, 0.003, abs(vUv.y - 0.5));

    vec2 pos = center * uResolution / 110.0;
    float line1 = smoothstep(0.0, 0.075, abs(pos.y - pos.x));

    color = mix(black, color, cellLine);
    color = mix(blue, color, xAxis);
    color = mix(red, color, yAxis);
    color = mix(yellow, color, line1);

    gl_FragColor = vec4(color, 1.0);
    // #include <tonemapping_fragment>
    // #include <colorspace_fragment>
}
