uniform float factor;
uniform Image grad;
uniform Image mask;

float threshold = 0.00390625;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 screen_coords) {
    float m = Texel(mask, tc).r;
    if (m > threshold && m < 1.0 - threshold) {
        vec2 r = vec2(1.0) / love_ScreenSize.xy;
        vec4 c = Texel(grad, tc);
        c += Texel(tex, tc + vec2(1.0, 0.0) * r);
        c += Texel(tex, tc + vec2(-1.0, 0.0) * r);
        c += Texel(tex, tc + vec2(0.0, 1.0) * r);
        c += Texel(tex, tc + vec2(0.0, -1.0) * r);
        return c * 0.25;
    } else {
        return Texel(tex, tc);
    }
}