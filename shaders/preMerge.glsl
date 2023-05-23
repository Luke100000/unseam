uniform Image second;
uniform Image blend;

vec4 effect(vec4 color, Image first, vec2 tc, vec2 sc) {
    vec4 c1 = Texel(first, tc);
    vec4 c2 = Texel(second, tc);
    float b = Texel(blend, tc).r;
    return mix(c1, c2, b);
}