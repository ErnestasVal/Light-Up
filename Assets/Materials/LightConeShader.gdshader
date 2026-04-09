shader_type spatial;
render_mode blend_add, depth_draw_never, cull_front, unshaded, shadows_disabled;

// ─── Appearance ────────────────────────────────────────────────────────────
uniform vec4  beam_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);

// How bright the beam is at the tip vs the base
uniform float tip_brightness  : hint_range(0.0, 4.0) = 1.8;
uniform float base_brightness : hint_range(0.0, 4.0) = 0.3;

// Radial edge softness: how far in from the cone surface the beam fades
uniform float edge_softness : hint_range(0.01, 1.0) = 0.35;

// Overall opacity multiplier
uniform float opacity : hint_range(0.0, 1.0) = 0.35;

// Controls how dusty/dense the centre of the beam looks
uniform float beam_density : hint_range(0.5, 8.0) = 2.0;

// ─── Noise / flicker ───────────────────────────────────────────────────────
uniform sampler2D noise_texture : hint_default_white;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.18;
uniform float noise_scroll_speed : hint_range(0.0, 4.0) = 0.4;
uniform float noise_scale : hint_range(0.5, 8.0) = 2.5;

// ─── Varyings ──────────────────────────────────────────────────────────────
varying vec3 v_obj_pos;   // vertex position in object space

void vertex() {
    v_obj_pos = VERTEX;
}

void fragment() {
    // ── Cone coordinate system ─────────────────────────────────────────────
    // Tip is at Y = 0, base opens downward (negative Y).
    // We remap Y so t = 0 at tip, t = 1 at base.
    // The cone's local radius at any slice equals abs(y) * (base_radius / height),
    // but because we work in normalised object space we can use the XZ magnitude
    // relative to y directly — the mesh already encodes this correctly.

    float y        = v_obj_pos.y;              // 0 at tip, negative going to base
    float t        = clamp(-y, 0.0, 1.0);     // 0=tip ... 1=base  (assumes height = 1)

    // Radial distance from cone axis in object space, normalised by the
    // expected radius at this slice (radius grows linearly with depth)
    float r_raw    = length(v_obj_pos.xz);
    float r_norm   = (t > 0.0001) ? (r_raw / t) : 0.0;  // 0=axis ... 1=surface

    // ── Edge fade ──────────────────────────────────────────────────────────
    // Soft falloff toward the cone surface so there is no hard silhouette
    float edge_fade = 1.0 - smoothstep(1.0 - edge_softness, 1.0, r_norm);

    // ── Axial brightness ───────────────────────────────────────────────────
    // Bright near tip, dims toward base
    float axial = mix(tip_brightness, base_brightness, pow(t, beam_density));

    // ── Radial glow profile ────────────────────────────────────────────────
    // Brightest on axis, falls off toward surface
    float radial = exp(-r_norm * r_norm * 3.5);

    // ── Noise / particle shimmer ───────────────────────────────────────────
    vec2 noise_uv = vec2(t * noise_scale, r_norm * noise_scale)
                    + vec2(0.0, TIME * noise_scroll_speed);
    float noise   = texture(noise_texture, noise_uv).r;
    float shimmer = 1.0 + (noise - 0.5) * 2.0 * noise_strength;

    // ── Combine ────────────────────────────────────────────────────────────
    float intensity = axial * radial * edge_fade * shimmer;
    float alpha     = clamp(intensity * opacity, 0.0, 1.0);

    ALBEDO = beam_color.rgb;
    ALPHA  = alpha;
}
