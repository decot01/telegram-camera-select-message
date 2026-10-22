import CoreGraphics
import Foundation

/// Thresholds for the video-note camera-select pull.
/// Same muscle memory as voice-message lock, different meaning: facing, not lock.
public struct CameraSelectConfig: Equatable, Sendable {
    /// Short pull (pt) → front camera. Default matches the person-circle mark height.
    public var frontPull: CGFloat
    /// Further pull (pt) → main / back camera. Default matches the pill mark.
    public var backPull: CGFloat
    /// Slide left (pt) → cancel (same as Telegram voice / video notes).
    public var cancelDistance: CGFloat
    public var maxDuration: TimeInterval
    public var hapticsEnabled: Bool
    /// Diameter of the front (person) circle button.
    public var frontButtonSize: CGFloat
    /// Size of the main (camera + chevron) pill.
    public var mainPillSize: CGSize
    /// Gap between the two marks along the rail.
    public var railSpacing: CGFloat

    public init(
        frontPull: CGFloat = 56,
        backPull: CGFloat = 132,
        cancelDistance: CGFloat = 72,
        maxDuration: TimeInterval = 60,
        hapticsEnabled: Bool = true,
        frontButtonSize: CGFloat = 44,
        mainPillSize: CGSize = CGSize(width: 44, height: 72),
        railSpacing: CGFloat = 16
    ) {
        self.frontPull = frontPull
        self.backPull = backPull
        self.cancelDistance = cancelDistance
        self.maxDuration = maxDuration
        self.hapticsEnabled = hapticsEnabled
        self.frontButtonSize = frontButtonSize
        self.mainPillSize = mainPillSize
        self.railSpacing = railSpacing
    }

    public static let `default` = CameraSelectConfig()
}

public enum CameraSelectFacing: Equatable, Sendable {
    case front
    case back
}

public enum CameraSelectPhase: Equatable, Sendable {
    case idle
    /// Finger down, below `frontPull` — rail visible, not recording yet.
    case armed
    case recording(CameraSelectFacing)
    case cancelArmed
}

public struct CameraSelectSample: Equatable, Sendable {
    /// Positive = up from the press origin.
    public var pullUp: CGFloat
    /// Negative = left.
    public var pullX: CGFloat

    public init(pullUp: CGFloat = 0, pullX: CGFloat = 0) {
        self.pullUp = pullUp
        self.pullX = pullX
    }
}
