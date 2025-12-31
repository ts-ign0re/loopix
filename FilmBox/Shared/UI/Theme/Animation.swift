import SwiftUI

// MARK: - Animation Duration

/// Standard animation durations
enum AnimationDuration {

    /// 0.1s - Instant feedback (micro interactions)
    static let instant: Double = 0.1

    /// 0.15s - Very fast transitions
    static let ultraFast: Double = 0.15

    /// 0.2s - Fast transitions (button press, toggle)
    static let fast: Double = 0.2

    /// 0.25s - Medium-fast transitions
    static let mediumFast: Double = 0.25

    /// 0.3s - Normal transitions (default)
    static let normal: Double = 0.3

    /// 0.4s - Medium-slow transitions
    static let mediumSlow: Double = 0.4

    /// 0.5s - Slow transitions (page transitions)
    static let slow: Double = 0.5

    /// 0.8s - Emphasis transitions (dramatic reveals)
    static let emphasis: Double = 0.8

    /// 1.0s - Long transitions
    static let long: Double = 1.0
}

// MARK: - Animation Curves

/// Standard animation curves following Apple's motion guidelines
enum AnimationCurve {

    /// Standard ease out - starts fast, slows down
    static let easeOut = Animation.easeOut(duration: AnimationDuration.normal)

    /// Standard ease in - starts slow, speeds up
    static let easeIn = Animation.easeIn(duration: AnimationDuration.normal)

    /// Standard ease in out - slow start and end
    static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)

    /// Linear animation
    static let linear = Animation.linear(duration: AnimationDuration.normal)

    /// Spring animation - natural bounce
    static let spring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0
    )

    /// Bouncy spring - more playful
    static let bouncy = Animation.spring(
        response: 0.5,
        dampingFraction: 0.6,
        blendDuration: 0
    )

    /// Stiff spring - quick settle
    static let stiff = Animation.spring(
        response: 0.3,
        dampingFraction: 0.9,
        blendDuration: 0
    )

    /// Smooth curve - custom bezier
    static let smooth = Animation.timingCurve(0.4, 0, 0.2, 1, duration: AnimationDuration.normal)

    /// Interactive spring for drag gestures
    static let interactive = Animation.interactiveSpring(
        response: 0.3,
        dampingFraction: 0.8,
        blendDuration: 0
    )

    // MARK: - Specific Use Cases

    /// For button press feedback
    static let buttonPress = Animation.easeOut(duration: AnimationDuration.instant)

    /// For modal presentation
    static let modalPresent = Animation.spring(
        response: 0.35,
        dampingFraction: 0.85,
        blendDuration: 0
    )

    /// For modal dismissal
    static let modalDismiss = Animation.easeOut(duration: AnimationDuration.fast)

    /// For tab switching
    static let tabSwitch = Animation.easeInOut(duration: AnimationDuration.fast)

    /// For filter selection
    static let filterSelect = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )

    /// For slider value changes
    static let sliderChange = Animation.linear(duration: AnimationDuration.instant)

    /// For image transitions
    static let imageTransition = Animation.easeInOut(duration: AnimationDuration.normal)

    /// For loading states
    static let loading = Animation.linear(duration: AnimationDuration.long).repeatForever(autoreverses: false)

    /// For pulse effects
    static let pulse = Animation.easeInOut(duration: AnimationDuration.slow).repeatForever(autoreverses: true)
}

// MARK: - Transition Styles

/// Standard view transitions
enum TransitionStyle {

    /// Opacity fade
    static let fade = AnyTransition.opacity

    /// Scale with fade
    static let scale = AnyTransition.scale.combined(with: .opacity)

    /// Slide from bottom
    static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)

    /// Slide from top
    static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)

    /// Slide from leading
    static let slideLeading = AnyTransition.move(edge: .leading).combined(with: .opacity)

    /// Slide from trailing
    static let slideTrailing = AnyTransition.move(edge: .trailing).combined(with: .opacity)

    /// Modal presentation style
    static let modal = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    /// Toast notification style
    static let toast = AnyTransition.asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .opacity
    )

    /// Photo zoom style
    static let photoZoom = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
}

// MARK: - Haptic Feedback

/// Haptic feedback styles
enum HapticStyle {

    case selection
    case light
    case medium
    case heavy
    case success
    case warning
    case error

    /// Trigger the haptic feedback
    func trigger() {
        switch self {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()

        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)

        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Haptics Manager

/// Centralized haptic feedback manager
final class Haptics {

    static let shared = Haptics()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        prepare()
    }

    /// Prepare generators for reduced latency
    func prepare() {
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
    }

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func light() {
        lightImpactGenerator.impactOccurred()
    }

    func medium() {
        mediumImpactGenerator.impactOccurred()
    }

    func heavy() {
        heavyImpactGenerator.impactOccurred()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}

// MARK: - View Extensions

extension View {

    /// Apply standard animation
    func standardAnimation() -> some View {
        animation(AnimationCurve.smooth, value: UUID())
    }

    /// Apply spring animation
    func springAnimation() -> some View {
        animation(AnimationCurve.spring, value: UUID())
    }

    /// Trigger haptic on tap
    func hapticOnTap(_ style: HapticStyle = .light) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                style.trigger()
            }
        )
    }

    /// Animated visibility
    func animatedVisibility(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .animation(AnimationCurve.easeOut, value: isVisible)
    }

    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                        .onAppear {
                            withAnimation(AnimationCurve.loading) {
                                phase = 1
                            }
                        }
                    }
                }
                .mask(content)
            )
    }
}

// MARK: - Button Press Effect

struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat
    let opacity: CGFloat

    init(scale: CGFloat = 0.96, opacity: CGFloat = 0.8) {
        self.scale = scale
        self.opacity = opacity
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? opacity : 1)
            .animation(AnimationCurve.buttonPress, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static func pressable(scale: CGFloat = 0.96, opacity: CGFloat = 0.8) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale, opacity: opacity)
    }
}

// MARK: - Preview

#Preview("Animation Demo") {
    struct AnimationDemo: View {
        @State private var isAnimating = false
        @State private var showModal = false

        var body: some View {
            VStack(spacing: Spacing.lg) {
                // Spring animation
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .scaleEffect(isAnimating ? 1.2 : 1)
                    .animation(AnimationCurve.bouncy, value: isAnimating)

                Button("Toggle Animation") {
                    isAnimating.toggle()
                    Haptics.shared.medium()
                }
                .buttonStyle(.pressable)

                Button("Show Modal") {
                    showModal = true
                    Haptics.shared.light()
                }

                Spacer()
            }
            .padding()
            .sheet(isPresented: $showModal) {
                Text("Modal Content")
                    .transition(TransitionStyle.modal)
            }
        }
    }

    return AnimationDemo()
}
