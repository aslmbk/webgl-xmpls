varying vec2 vUv;

/*
Объяснение того как работает интерполяция
с помощью линии, которая делит экран на две части.
В верхней части экрана интерполяция точно линейная,
а в нижней части экрана интерполяция сглаживается с помощью smoothstep.
*/

void main() {
    vec3 red = vec3(1.0, 0.0, 0.0);
    vec3 blue = vec3(0.0, 0.0, 1.0);

    vec3 top = mix(red, blue, vUv.x);
    vec3 bottom = mix(red, blue, smoothstep(0.0, 1.0, vUv.x));

    vec3 color = mix(bottom, top, step(0.5, vUv.y));

    float divider = smoothstep(0.0, 0.005, abs(vUv.y - 0.5));
    color = mix(vec3(1.0), color, divider);

    float topLineX = abs(vUv.y - mix(0.5, 1.0, vUv.x));
    float topLine = smoothstep(0.0, 0.005, topLineX);
    color = mix(vec3(1.0), color, topLine);

    float bottomLineX = abs(vUv.y - mix(0.0, 0.5, smoothstep(0.0, 1.0, vUv.x)));
    float bottomLine = smoothstep(0.0, 0.005, bottomLineX);
    color = mix(vec3(1.0), color, bottomLine);

    gl_FragColor = vec4(color, 1.0);
    // #include <tonemapping_fragment>
    // #include <colorspace_fragment>
}
