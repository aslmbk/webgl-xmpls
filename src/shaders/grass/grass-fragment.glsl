uniform vec2 uResolution;
uniform float uTime;
uniform sampler2DArray uGrassAtlas;

varying vec3 vColor;
varying vec4 vGrassData;
varying vec3 vNormal;
varying vec3 vWorldPosition;
float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

float easeOut(float x, float t) {
    return 1.0 - pow(1.0 - x, t);
}

vec3 hemiLight(vec3 normal, vec3 groundColour, vec3 skyColour) {
    return mix(groundColour, skyColour, 0.5 * normal.y + 0.5);
}

vec3 lambertLight(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColour) {
    float wrap = 0.5;
    float dotNL = saturate((dot(normal, lightDir) + wrap) / (1.0 + wrap));
    vec3 lighting = vec3(dotNL);

    float backlight = saturate((dot(viewDir, -lightDir) + wrap) / (1.0 + wrap));
    vec3 scatter = vec3(pow(backlight, 2.0));

    lighting += scatter;

    return lighting * lightColour;
}

vec3 phongSpecular(vec3 normal, vec3 lightDir, vec3 viewDir) {
    float dotNL = saturate(dot(normal, lightDir));

    vec3 r = normalize(reflect(-lightDir, normal));
    float phongValue = max(0.0, dot(viewDir, r));
    phongValue = pow(phongValue, 32.0);

    vec3 specular = dotNL * vec3(phongValue);

    return specular;
}

void main() {
    float grassX = vGrassData.x;
    float grassY = vGrassData.y;
    float grassType = vGrassData.w;
    vec3 normal = normalize(vNormal);
    vec3 viewDir = normalize(cameraPosition - vWorldPosition);

    // vec3 baseColor = mix(
    //     vColor * 0.75,
    //     vColor,
    //     smoothstep(0.125, 0.0, abs(grassX))
    // );

    vec2 uv = vGrassData.zy;
    vec4 baseColor = texture2D(uGrassAtlas, vec3(uv, grassType));
    baseColor.xyz *=
        mix(0.75, 1.0, smoothstep(0.125, 0.0, abs(grassX))) * vColor;

    if (baseColor.w < 0.5) discard;

    vec3 c1 = vec3(1.0, 1.0, 0.75);
    vec3 c2 = vec3(0.05, 0.05, 0.25);
    vec3 ambientLighting = hemiLight(normal, c2, c1);

    vec3 lightDir = normalize(vec3(-1.0, 0.5, 1.0));
    vec3 lightColour = vec3(1.0);
    vec3 diffuseLighting = lambertLight(normal, viewDir, lightDir, lightColour);

    vec3 specular =
        phongSpecular(normal, lightDir, viewDir) * easeOut(grassY, 4.0);

    // Fake AO
    float ao = remap(pow(grassY, 2.0), 0.0, 1.0, 0.0625, 1.0);

    vec3 lighting = ambientLighting + diffuseLighting;

    vec3 color = baseColor.xyz * lighting + specular * baseColor.xyz;
    color *= ao;
    color = pow(color, vec3(1.0 / 2.2));
    gl_FragColor = vec4(color, 1.0);
}
