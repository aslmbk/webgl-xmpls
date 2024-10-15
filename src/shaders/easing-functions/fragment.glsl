uniform samplerCube uEnvironmentMap;

varying vec3 vNormal;
varying vec3 vPosition;

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

vec3 linearTosRGB(vec3 value) {
    vec3 lt = vec3(lessThanEqual(value, vec3(0.0031308)));
    vec3 v1 = value * 12.92;
    vec3 v2 = pow(value, vec3(0.41666)) * 1.055 - vec3(0.055);
    return mix(v2, v1, lt);
}

vec3 linearToGamma(vec3 value) {
    return pow(value, vec3(1.0 / 2.2));
}

void main() {
    vec3 normal = normalize(vNormal);
    vec3 baseColor = vec3(0.5);
    vec3 lighting = vec3(0.0);

    vec3 ambient = vec3(0.2);
    vec3 skyColor = vec3(0.0, 0.3, 0.6);
    vec3 groundColor = vec3(0.4, 0.3, 0.25);

    float hemiMix = remap(normal.y, -1.0, 1.0, 0.0, 1.0);
    vec3 hemi = mix(groundColor, skyColor, hemiMix);

    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    vec3 lightColor = vec3(1.0, 1.0, 0.9);
    float dp = max(0.0, dot(lightDir, normal));
    vec3 diffuse = dp * lightColor * 0.8;

    vec3 viewDir = normalize(cameraPosition - vPosition);
    vec3 phongDir = normalize(reflect(-lightDir, normal));
    float phong = max(0.0, dot(viewDir, phongDir));
    phong = pow(phong, 64.0);
    vec3 specular = vec3(phong);

    vec3 iblCoord = normalize(reflect(-viewDir, normal));
    vec3 ibl = textureCube(uEnvironmentMap, iblCoord).rgb;
    specular += ibl * 0.5;

    float fresnel = 1.0 - max(0.0, dot(viewDir, normal));
    fresnel = pow(fresnel, 2.0);
    specular *= fresnel;

    lighting = ambient + hemi + diffuse;

    vec3 color = baseColor * lighting + specular;
    color = linearTosRGB(color);
    // color = linearToGamma(color);

    gl_FragColor = vec4(color, 1.0);
    // #include <tonemapping_fragment>
    // #include <colorspace_fragment>
}
