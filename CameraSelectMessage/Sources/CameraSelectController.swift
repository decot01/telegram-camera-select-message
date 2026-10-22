import UIKit

/// Public API — same role as `BlackHoleDeleteAnimator` in the reference package.
///
/// Owns the gesture + the two Figma buttons (rail). The host (Telegram chat / Demo)
/// supplies the foundation (composer, video-note capture) and calls:
/// `begin` → `move` → `end` from the existing hold recognizer.
public final class CameraSelectController {
    public let config: CameraSelectConfig
    public let railView: CameraSelectRailView

    /// Facing became available / changed (start or switch capture device here).
    public var onFacingChange: ((CameraSelectFacing) -> Void)?
    /// Finger released with a facing → send that take. `nil` → cancelled / below threshold.
    public var onFinished: ((CameraSelectFacing?) -> Void)?
    /// Live sample for optional host chrome (timer bar, slide-to-cancel tint).
    public var onSample: ((CameraSelectSample, CameraSelectPhase) -> Void)?

    public private(set) var isActive = false
    public private(set) var facing: CameraSelectFacing?

    private let gesture: CameraSelectGesture
    private var lastHapticFacing: CameraSelectFacing?

    public init(config: CameraSelectConfig = .default) {
        self.config = config
        self.gesture = CameraSelectGesture(config: config)
        self.railView = CameraSelectRailView(config: config)

        gesture.onPhaseChange = { [weak self] phase in
            self?.handlePhase(phase)
        }
        gesture.onSample = { [weak self] sample in
            guard let self else { return }
            self.onSample?(sample, self.gesture.phase)
        }
    }

    /// Bundle with optional raster assets (`CameraSelectButtons.png`). Drawn buttons
    /// work without it; the PNG is kept for design reference / future skinning.
    public static func resourceBundle(named name: String = "CameraSelectMessageResourcesBundle") -> Bundle {
        let moduleBundle = Bundle(for: BundleToken.self)
        if let path = moduleBundle.path(forResource: name, ofType: "bundle"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return moduleBundle
    }

    /// Attach the rail above the record button. `anchor` is the button frame in `host`.
    public func attachRail(above anchor: CGRect, in host: UIView) {
        railView.place(above: anchor, in: host)
    }

    public func begin(at point: CGPoint) {
        isActive = true
        facing = nil
        lastHapticFacing = nil
        railView.show(animated: true)
        gesture.begin(at: point)
    }

    public func move(to point: CGPoint) {
        guard isActive else { return }
        gesture.move(to: point)
    }

    /// Ends the gesture. Invokes `onFinished` with facing or `nil`.
    public func end() {
        guard isActive else { return }
        let result = gesture.end()
        tearDownRail()
        onFinished?(result)
    }

    public func cancel() {
        guard isActive else { return }
        gesture.cancel()
        tearDownRail()
        onFinished?(nil)
    }

    // MARK: - Internals

    private func handlePhase(_ phase: CameraSelectPhase) {
        switch phase {
        case .idle:
            railView.setFacing(nil)
            facing = nil
        case .armed, .cancelArmed:
            railView.setFacing(nil)
            if facing != nil {
                facing = nil
            }
        case .recording(let next):
            railView.setFacing(next)
            if facing != next {
                facing = next
                fireHaptic(for: next)
                onFacingChange?(next)
            }
        }
    }

    private func fireHaptic(for facing: CameraSelectFacing) {
        guard config.hapticsEnabled, lastHapticFacing != facing else { return }
        lastHapticFacing = facing
        let style: UIImpactFeedbackGenerator.FeedbackStyle = facing == .back ? .medium : .light
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func tearDownRail() {
        isActive = false
        facing = nil
        lastHapticFacing = nil
        railView.hide(animated: true)
    }
}

private final class BundleToken: NSObject {}
