//11-tap 1.6 Sigma

uniform vec2 dir;

uniform Image contrast;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float sum = Texel(texture, tc).r * 0.245484;

    float strength = Texel(contrast, tc).r;
    vec2 d = dir * strength;

    sum += Texel(texture, tc - d * 5.0).r * 0.002166;
    sum += Texel(texture, tc - d * 4.0).r * 0.011902;
    sum += Texel(texture, tc - d * 3.0).r * 0.044758;
    sum += Texel(texture, tc - d * 2.0).r * 0.115233;
    sum += Texel(texture, tc - d).r * 0.203199;

    sum += Texel(texture, tc + d).r * 0.203199;
    sum += Texel(texture, tc + d * 2.0).r * 0.115233;
    sum += Texel(texture, tc + d * 3.0).r * 0.044758;
    sum += Texel(texture, tc + d * 4.0).r * 0.011902;
    sum += Texel(texture, tc + d * 5.0).r * 0.002166;

    float border = 1.0 / love_ScreenSize.x;

    if (tc.x < 0.5) {
        sum = max(sum, pow(1.0 + border - tc.x, 16.0));
    } else {
        sum = min(sum, 1.0 - pow(tc.x + border, 16.0));
    }

    sum = clamp(sum, 0.0, 1.0);

    return vec4(sum, sum, sum, 1.0);
}