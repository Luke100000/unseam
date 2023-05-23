//11-tap 1.6 Sigma

uniform vec2 dir;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float sum = Texel(texture, tc).r * 0.245484;

    sum += Texel(texture, tc - dir * 5.0).r * 0.002166;
    sum += Texel(texture, tc - dir * 4.0).r * 0.011902;
    sum += Texel(texture, tc - dir * 3.0).r * 0.044758;
    sum += Texel(texture, tc - dir * 2.0).r * 0.115233;
    sum += Texel(texture, tc - dir).r * 0.203199;

    sum += Texel(texture, tc + dir).r * 0.203199;
    sum += Texel(texture, tc + dir * 2.0).r * 0.115233;
    sum += Texel(texture, tc + dir * 3.0).r * 0.044758;
    sum += Texel(texture, tc + dir * 4.0).r * 0.011902;
    sum += Texel(texture, tc + dir * 5.0).r * 0.002166;

    float minSum = pow(1.0 - abs(tc.x - 0.5), 16.0);

    sum = max(minSum, sum);

    return vec4(sum, sum, sum, 1.0);
}