import CoreGraphics
import Foundation

/// Pure gesture resolver — no UIKit.
/// Maps finger deltas to front / main camera zones. No lock phase.
public final class CameraSelectGesture {
    public var config: CameraSelectConfig
    public private(set) var phase: CameraSelectPhase = .idle
    public private(set) var sample = CameraSelectSample()

    public var onPhaseChange: ((CameraSelectPhase) -> Void)?
    public var onSample: ((CameraSelectSample) -> Void)?

    private var origin: CGPoint?

    public init(config: CameraSelectConfig = .default) {
        self.config = config
    }

    public func begin(at point: CGPoint) {
        origin = point
        sample = CameraSelectSample()
        setPhase(.armed)
        onSample?(sample)
    }

    public func move(to point: CGPoint) {
        guard let origin else { return }
        sample = CameraSelectSample(pullUp: origin.y - point.y, pullX: point.x - origin.x)
        onSample?(sample)

        if sample.pullX <= -config.cancelDistance {
            setPhase(.cancelArmed)
            return
        }
        if sample.pullUp >= config.backPull {
            setPhase(.recording(.back))
        } else if sample.pullUp >= config.frontPull {
            setPhase(.recording(.front))
        } else {
            setPhase(.armed)
        }
    }

    /// - Returns: facing to send, or `nil` to discard.
    @discardableResult
    public func end() -> CameraSelectFacing? {
        defer { reset() }
        if case .recording(let facing) = phase {
            return facing
        }
        return nil
    }

    public func cancel() {
        reset()
    }

    public func facing(for sample: CameraSelectSample) -> CameraSelectFacing? {
        if sample.pullUp >= config.backPull { return .back }
        if sample.pullUp >= config.frontPull { return .front }
        return nil
    }

    private func setPhase(_ next: CameraSelectPhase) {
        guard phase != next else { return }
        phase = next
        onPhaseChange?(next)
    }

    private func reset() {
        origin = nil
        sample = CameraSelectSample()
        phase = .idle
    }
}
