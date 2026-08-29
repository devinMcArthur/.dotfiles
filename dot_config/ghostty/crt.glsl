// crt.glsl — a CRT that flatters text rather than fighting it.
//
// Toggled by `ghostty-crt` (Super+Alt+C), which writes the custom-shader
// line into crt.conf and reloads Ghostty. ShaderToy conventions: Ghostty
// hands us the terminal in iChannel0.
//
// Everything here is deliberately understated. A full-strength CRT looks
// wonderful in a screenshot and is miserable to read after ten minutes —
// the curvature is slight, the scanlines are a gentle ripple rather than
// black bars, and the aperture mask only tints. Nothing shifts a glyph
// far enough to blur it.

#define CURVE     0.05   // barrel distortion
#define SCANLINE  0.10   // horizontal line depth
#define MASK      0.07   // RGB phosphor tint
#define GLOW      0.16   // phosphor bleed into neighbours
#define VIGNETTE  0.18   // corner falloff

vec2 curve(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
    uv += uv * offset * offset * CURVE * 6.0;
    return uv * 0.5 + 0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv  = fragCoord / iResolution.xy;
    vec2 cuv = curve(uv);

    // Past the glass edge: black bezel, not stretched pixels.
    if (cuv.x < 0.0 || cuv.x > 1.0 || cuv.y < 0.0 || cuv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 col = texture(iChannel0, cuv).rgb;

    // Phosphor bleed: four taps, added back rather than blended, so bright
    // glyphs gain a halo while the background stays black.
    vec2 px = 1.5 / iResolution.xy;
    vec3 bleed = texture(iChannel0, cuv + vec2(px.x, 0.0)).rgb
               + texture(iChannel0, cuv - vec2(px.x, 0.0)).rgb
               + texture(iChannel0, cuv + vec2(0.0, px.y)).rgb
               + texture(iChannel0, cuv - vec2(0.0, px.y)).rgb;
    col += bleed * 0.25 * GLOW;

    // Scanlines from a squared sine: smooth troughs, no hard banding.
    float s = sin(cuv.y * iResolution.y * 3.14159265);
    col *= 1.0 - SCANLINE * s * s;

    // Aperture grille — tint every third column instead of dimming it.
    float m = mod(fragCoord.x, 3.0);
    vec3 mask = m < 1.0 ? vec3(1.0, 1.0 - MASK, 1.0 - MASK)
              : m < 2.0 ? vec3(1.0 - MASK, 1.0, 1.0 - MASK)
                        : vec3(1.0 - MASK, 1.0 - MASK, 1.0);
    col *= mask;

    vec2 v = cuv * (1.0 - cuv);
    col *= pow(v.x * v.y * 16.0, VIGNETTE);

    fragColor = vec4(col, 1.0);
}
