import CoreImage

// swiftlint:disable identifier_name large_tuple
/// Single channel tone curve defined by 5 control points
/// at fixed x positions: 0.0, 0.25, 0.5, 0.75, 1.0
struct ToneCurve: Codable, Hashable, Sendable {
    /// Output value at input = 0.0 (black point)
    var shadows: Float = 0.0
    /// Output value at input = 0.25
    var darks: Float = 0.25
    /// Output value at input = 0.5
    var midtones: Float = 0.5
    /// Output value at input = 0.75
    var lights: Float = 0.75
    /// Output value at input = 1.0 (white point)
    var highlights: Float = 1.0

    static let identity = ToneCurve()

    var isIdentity: Bool {
        shadows == 0.0 && darks == 0.25 && midtones == 0.5
            && lights == 0.75 && highlights == 1.0
    }

    /// Cubic polynomial coefficients: output = a + b*x + c*x² + d*x³
    ///
    /// We constrain endpoints exactly:
    /// - f(0) = shadows
    /// - f(1) = highlights
    ///
    /// Then solve a small least-squares fit for the interior control points
    /// (x = 0.25, 0.5, 0.75). This preserves the `lights` control point influence
    /// while keeping the same cubic representation expected by CIColorPolynomial.
    var polynomialCoefficients: (a: Float, b: Float, c: Float, d: Float) {
        let y0 = Double(shadows)
        let y1 = Double(darks)
        let y2 = Double(midtones)
        let y3 = Double(lights)
        let y4 = Double(highlights)

        let a = y0
        let sumAtOne = y4 - y0 // b + c + d

        // Solve least-squares for c and d with:
        // f(x) = a + (sumAtOne - c - d)x + cx² + dx³
        //      = a + sumAtOne*x + c(x² - x) + d(x³ - x)
        let xs: [Double] = [0.25, 0.5, 0.75]
        let ys: [Double] = [y1, y2, y3]

        var ata00 = 0.0
        var ata01 = 0.0
        var ata11 = 0.0
        var atb0 = 0.0
        var atb1 = 0.0

        for index in 0..<xs.count {
            let x = xs[index]
            let y = ys[index]
            let p = x * x - x
            let q = x * x * x - x
            let rhs = y - a - sumAtOne * x

            ata00 += p * p
            ata01 += p * q
            ata11 += q * q
            atb0 += p * rhs
            atb1 += q * rhs
        }

        let det = ata00 * ata11 - ata01 * ata01
        if abs(det) <= 1e-12 {
            // Numerically defensive fallback to previous closed-form fit.
            let bigA = y1 - y0
            let bigB = y2 - y0
            let bigC = y4 - y0

            let b = (bigC - 12.0 * bigB + 32.0 * bigA) / 3.0
            let c = 20.0 * bigB - 32.0 * bigA - 2.0 * bigC
            let d = (8.0 * bigC - 48.0 * bigB + 64.0 * bigA) / 3.0
            return (Float(a), Float(b), Float(c), Float(d))
        }

        let c = (atb0 * ata11 - atb1 * ata01) / det
        let d = (ata00 * atb1 - ata01 * atb0) / det
        let b = sumAtOne - c - d

        return (Float(a), Float(b), Float(c), Float(d))
    }

    /// CIVector for CIColorPolynomial: (a, b, c, d)
    var ciVector: CIVector {
        let c = polynomialCoefficients
        return CIVector(x: CGFloat(c.a), y: CGFloat(c.b), z: CGFloat(c.c), w: CGFloat(c.d))
    }
}

/// Per-channel RGBA tone curves
struct RGBACurves: Codable, Hashable, Sendable {
    var r: ToneCurve = .identity
    var g: ToneCurve = .identity
    var b: ToneCurve = .identity
    var a: ToneCurve = .identity

    static let identity = RGBACurves()

    var isIdentity: Bool {
        r.isIdentity && g.isIdentity && b.isIdentity && a.isIdentity
    }
}
// swiftlint:enable identifier_name large_tuple
