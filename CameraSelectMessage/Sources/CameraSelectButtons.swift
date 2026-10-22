import UIKit

// MARK: - The two custom controls (Figma)
//
// Main: vertical pill — video camera + chevron up (further pull → back camera).
// Front: circle — person (short pull → front camera).
// Glass fill matches Telegram / Figma frosted controls (UIVisualEffectView), not a flat paint.

private enum CameraSelectChrome {
    static let icon = UIColor(white: 0.12, alpha: 1)
    static let glassTint = UIColor(white: 1.0, alpha: 0.28)
    static let glassBorder = UIColor(white: 1.0, alpha: 0.55)
    static let activeGlow = UIColor(red: 0.2, green: 0.565, blue: 0.925, alpha: 0.5)
}

/// Shared frosted-glass shell: blur + light tint + hairline highlight.
private final class CameraSelectGlassShell: UIView {
    private let blur: UIVisualEffectView
    private let tintOverlay = UIView()
    private let border = CAShapeLayer()
    private let glow = CALayer()
    var isPill = false

    init(isPill: Bool) {
        self.isPill = isPill
        // Light ultra-thin material ≈ Telegram camera overlay / Figma glass on dark preview.
        blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = false

        glow.shadowColor = CameraSelectChrome.activeGlow.cgColor
        glow.shadowOpacity = 0
        glow.shadowRadius = 10
        glow.shadowOffset = .zero
        glow.backgroundColor = UIColor.white.cgColor
        layer.insertSublayer(glow, at: 0)

        blur.clipsToBounds = true
        addSubview(blur)

        tintOverlay.isUserInteractionEnabled = false
        tintOverlay.backgroundColor = CameraSelectChrome.glassTint
        blur.contentView.addSubview(tintOverlay)

        border.fillColor = nil
        border.strokeColor = CameraSelectChrome.glassBorder.cgColor
        border.lineWidth = 0.5
        layer.addSublayer(border)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        tintOverlay.frame = blur.contentView.bounds
        let radius = bounds.width / 2
        blur.layer.cornerRadius = radius
        glow.frame = bounds
        glow.cornerRadius = radius
        border.path = (isPill
            ? UIBezierPath(roundedRect: bounds.insetBy(dx: 0.25, dy: 0.25), cornerRadius: radius)
            : UIBezierPath(ovalIn: bounds.insetBy(dx: 0.25, dy: 0.25))
        ).cgPath
        border.frame = bounds
    }

    func setActive(_ active: Bool, animated: Bool) {
        let changes = {
            self.glow.shadowOpacity = active ? 0.9 : 0
            self.tintOverlay.backgroundColor = active
                ? UIColor(white: 1, alpha: 0.42)
                : CameraSelectChrome.glassTint
            self.border.strokeColor = (active
                ? UIColor(white: 1, alpha: 0.85)
                : CameraSelectChrome.glassBorder
            ).cgColor
        }
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut], animations: changes)
            let anim = CABasicAnimation(keyPath: "shadowOpacity")
            anim.fromValue = glow.presentation()?.shadowOpacity ?? glow.shadowOpacity
            anim.toValue = active ? 0.9 : 0
            anim.duration = 0.18
            glow.add(anim, forKey: "glow")
            glow.shadowOpacity = active ? 0.9 : 0
        } else {
            changes()
            glow.shadowOpacity = active ? 0.9 : 0
        }
    }
}

/// Vertical pill: camera icon on top, chevron below. Active = main / back camera zone.
public final class CameraSelectMainPillButton: UIView {
    public private(set) var isActive = false
    private let shell = CameraSelectGlassShell(isPill: true)
    private let iconView = MainPillIconView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        addSubview(shell)
        addSubview(iconView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setActive(_ active: Bool, animated: Bool = true) {
        guard active != isActive else { return }
        isActive = active
        shell.setActive(active, animated: animated)
        let changes = { self.transform = active ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity }
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: changes)
        } else {
            changes()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        shell.frame = bounds
        iconView.frame = bounds
    }
}

/// Circle with person icon. Active = front camera zone.
public final class CameraSelectFrontCircleButton: UIView {
    public private(set) var isActive = false
    private let shell = CameraSelectGlassShell(isPill: false)
    private let iconView = FrontCircleIconView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        addSubview(shell)
        addSubview(iconView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func setActive(_ active: Bool, animated: Bool = true) {
        guard active != isActive else { return }
        isActive = active
        shell.setActive(active, animated: animated)
        let changes = { self.transform = active ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity }
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: changes)
        } else {
            changes()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        shell.frame = bounds
        iconView.frame = bounds
    }
}

// MARK: - Icons (stroke on top of glass)

private final class MainPillIconView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let ink = CameraSelectChrome.icon
        ink.setStroke()

        let cam = CGRect(x: bounds.midX - 10, y: bounds.height * 0.18, width: 20, height: 14)
        let body = UIBezierPath(roundedRect: CGRect(x: cam.minX, y: cam.minY, width: 13, height: 14), cornerRadius: 2.5)
        body.lineWidth = 1.7
        body.stroke()
        let lens = UIBezierPath()
        lens.move(to: CGPoint(x: cam.minX + 13, y: cam.minY + 3.5))
        lens.addLine(to: CGPoint(x: cam.maxX, y: cam.minY + 1.5))
        lens.addLine(to: CGPoint(x: cam.maxX, y: cam.maxY - 1.5))
        lens.addLine(to: CGPoint(x: cam.minX + 13, y: cam.maxY - 3.5))
        lens.close()
        lens.lineWidth = 1.7
        lens.stroke()

        let chevron = UIBezierPath()
        let cy = bounds.height * 0.72
        chevron.move(to: CGPoint(x: bounds.midX - 6, y: cy + 3))
        chevron.addLine(to: CGPoint(x: bounds.midX, y: cy - 2))
        chevron.addLine(to: CGPoint(x: bounds.midX + 6, y: cy + 3))
        chevron.lineWidth = 1.7
        chevron.lineCapStyle = .round
        chevron.lineJoinStyle = .round
        chevron.stroke()
    }
}

private final class FrontCircleIconView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let ink = CameraSelectChrome.icon
        ink.setStroke()
        let head = UIBezierPath(ovalIn: CGRect(x: bounds.midX - 5, y: bounds.midY - 10, width: 10, height: 10))
        head.lineWidth = 1.7
        head.stroke()
        let shoulders = UIBezierPath()
        shoulders.addArc(
            withCenter: CGPoint(x: bounds.midX, y: bounds.midY + 12),
            radius: 11,
            startAngle: .pi * 1.15,
            endAngle: .pi * 1.85,
            clockwise: true
        )
        shoulders.lineWidth = 1.7
        shoulders.lineCapStyle = .round
        shoulders.stroke()
    }
}

/// Vertical rail: main pill above, front circle below — placed above the record button.
public final class CameraSelectRailView: UIView {
    public let config: CameraSelectConfig
    public let mainButton = CameraSelectMainPillButton()
    public let frontButton = CameraSelectFrontCircleButton()

    public init(config: CameraSelectConfig = .default) {
        self.config = config
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isHidden = true
        alpha = 0
        addSubview(mainButton)
        addSubview(frontButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override var intrinsicContentSize: CGSize {
        let h = config.mainPillSize.height + config.railSpacing + config.frontButtonSize
        return CGSize(width: max(config.mainPillSize.width, config.frontButtonSize), height: h)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        mainButton.frame = CGRect(
            x: (w - config.mainPillSize.width) / 2,
            y: 0,
            width: config.mainPillSize.width,
            height: config.mainPillSize.height
        )
        frontButton.frame = CGRect(
            x: (w - config.frontButtonSize) / 2,
            y: config.mainPillSize.height + config.railSpacing,
            width: config.frontButtonSize,
            height: config.frontButtonSize
        )
    }

    public func setFacing(_ facing: CameraSelectFacing?, animated: Bool = true) {
        frontButton.setActive(facing == .front, animated: animated)
        mainButton.setActive(facing == .back, animated: animated)
    }

    public func show(animated: Bool = true) {
        isHidden = false
        let changes = { self.alpha = 1; self.transform = .identity }
        transform = CGAffineTransform(translationX: 0, y: 8)
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: changes)
        } else {
            changes()
        }
    }

    public func hide(animated: Bool = true) {
        let changes = {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 8)
        }
        let finish = {
            self.isHidden = true
            self.setFacing(nil, animated: false)
            self.transform = .identity
        }
        if animated {
            UIView.animate(withDuration: 0.15, animations: changes, completion: { _ in finish() })
        } else {
            changes()
            finish()
        }
    }

    /// Places the rail so the front circle sits just above `anchor` (the record button frame in `host`).
    public func place(above anchor: CGRect, in host: UIView) {
        let size = intrinsicContentSize
        let gap: CGFloat = 12
        frame = CGRect(
            x: anchor.midX - size.width / 2,
            y: anchor.minY - gap - size.height,
            width: size.width,
            height: size.height
        )
        if superview !== host {
            host.addSubview(self)
        }
    }
}
