#define range 5.0
#define white vec3(0.2126, 0.7152, 0.0722)

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    float brightness = 0.0;
    float samples = 0.0;
    for (float x = -range; x < range; x += 1.0) {
        for (float y = -range; y < range; y += 1.0) {
            float b = dot(white, Texel(tex, tc + vec2(x, y) / love_ScreenSize.xy).rgb);
            brightness += b;
            samples += 1.0;
        }
    }

    brightness /= samples;

    float contrast = 0.0;
    for (float x = -range; x < range; x += 1.0) {
        for (float y = -range; y < range; y += 1.0) {
            float b = dot(white, Texel(tex, tc + vec2(x, y) / love_ScreenSize.xy).rgb);
            contrast += abs(b - brightness);
        }
    }

    return vec4(max(0.0, pow(1.0 - contrast / samples * 16.0, 2.0)), 0.0, 0.0, 1.0);
}