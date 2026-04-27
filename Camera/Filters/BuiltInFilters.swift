import Foundation

enum BuiltInFilters {

    /// Index of the Neutral filter — default selection & scroll anchor
    static let neutralIndex = 8

    static let all: [CameraFilter] = [
        // ── B&W (left of Neutral) ──────────────────────────
        .retro,
        .triX,
        .bwXX,
        .tmax3200,
        .panF,
        .delta,
        .hp5,
        .slate,

        // ── Center ─────────────────────────────────────────
        .clean,

        // ── Color (right of Neutral) ───────────────────────
        .portra,
        .ektar,
        .pro400H,
        .classicChrome,
        .halide,
        .copper,
        .fern,
        .flare,
        .frost,
        .velvia,
        .diode,
        .chrome,
        .provia,
        .superia,
        .ultra,

        // ── Premium Cinematic Pack (far right) ──────────────
        .cinematic,
        .black,
        .dreamy,
        .skylight,
        .darkOrange,
        .orangeBlue,
        .darkMoody
    ]
}
