// CameraSelectMessage — UIKit demo of the integration (not needed in Telegram-iOS).
// Fake chat = foundation to pin the two Figma buttons onto. Shows the exact host calls:
// attachRail → begin → move → onFacingChange → end.

import AVFoundation
import UIKit

final class DemoViewController: UIViewController {
    private let wallpaper = UIView()
    private let chat = UIScrollView()
    private let chatContent = UIView()
    private let navBar = UIView()
    private let composer = UIView()
    private let inputField = UIView()
    private let recordButton = UIButton(type: .system)
    private let hint = UILabel()
    private let statusLabel = UILabel()

    private let select = CameraSelectController()
    private var recorder: CameraSelectRecorder?
    private var previewHost: UIView?
    private var isHolding = false
    private var bubbles: [UIView] = []

    override var prefersStatusBarHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.055, green: 0.086, blue: 0.129, alpha: 1)

        wallpaper.backgroundColor = UIColor(red: 0.055, green: 0.086, blue: 0.129, alpha: 1)
        view.addSubview(wallpaper)

        buildNav()
        buildChat()
        buildComposer()
        wireSelect()

        // Pre-create recorder off the critical path (like BlackHole prewarm).
        Task { await self.prewarmRecorder() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let b = view.bounds
        let top = view.safeAreaInsets.top
        let bottom = view.safeAreaInsets.bottom
        wallpaper.frame = b
        navBar.frame = CGRect(x: 0, y: 0, width: b.width, height: top + 52)
        layoutNav(top: top)
        composer.frame = CGRect(x: 0, y: b.height - bottom - 56, width: b.width, height: bottom + 56)
        layoutComposer()
        chat.frame = CGRect(x: 0, y: navBar.frame.maxY, width: b.width, height: composer.frame.minY - navBar.frame.maxY)
        layoutBubbles()
        previewHost?.frame = b
    }

    // MARK: - Foundation chrome (Telegram-ish shell only)

    private func buildNav() {
        navBar.backgroundColor = UIColor(red: 0.09, green: 0.13, blue: 0.18, alpha: 0.96)
        view.addSubview(navBar)
        let title = UILabel()
        title.text = "Ava"
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        title.tag = 1
        title.textAlignment = .center
        navBar.addSubview(title)
        let sub = UILabel()
        sub.text = "online"
        sub.textColor = UIColor(white: 0.65, alpha: 1)
        sub.font = .systemFont(ofSize: 13)
        sub.tag = 2
        sub.textAlignment = .center
        navBar.addSubview(sub)
    }

    private func layoutNav(top: CGFloat) {
        navBar.viewWithTag(1)?.frame = CGRect(x: 60, y: top + 6, width: view.bounds.width - 120, height: 22)
        navBar.viewWithTag(2)?.frame = CGRect(x: 60, y: top + 28, width: view.bounds.width - 120, height: 18)
    }

    private func buildChat() {
        chat.alwaysBounceVertical = true
        view.addSubview(chat)
        chat.addSubview(chatContent)

        let texts: [(String, Bool)] = [
            ("send me a video note from the back camera?", false),
            ("pull up on the camera button — a little for front, further for main", true),
        ]
        for (text, outgoing) in texts {
            let bubble = makeBubble(text: text, outgoing: outgoing)
            chatContent.addSubview(bubble)
            bubbles.append(bubble)
        }

        hint.numberOfLines = 0
        hint.textColor = UIColor(white: 0.78, alpha: 1)
        hint.font = .systemFont(ofSize: 13)
        hint.text = "Hold the blue button. Short pull → front (person). Further → main (pill). Release to send · slide left to cancel. No lock."
        hint.backgroundColor = UIColor(red: 0.2, green: 0.45, blue: 0.7, alpha: 0.22)
        hint.layer.cornerRadius = 12
        hint.layer.masksToBounds = true
        hint.textAlignment = .left
        chatContent.addSubview(hint)

        statusLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = UIColor(white: 0.7, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.text = "idle"
        chatContent.addSubview(statusLabel)
    }

    private func makeBubble(text: String, outgoing: Bool) -> UIView {
        let bubble = UIView()
        bubble.backgroundColor = outgoing
            ? UIColor(red: 0.17, green: 0.32, blue: 0.47, alpha: 1)
            : UIColor(red: 0.095, green: 0.145, blue: 0.2, alpha: 1)
        bubble.layer.cornerRadius = 14
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.tag = outgoing ? 1 : 0
        bubble.addSubview(label)
        return bubble
    }

    private func layoutBubbles() {
        let width = view.bounds.width
        var y: CGFloat = 16
        for bubble in bubbles {
            if bubble.accessibilityIdentifier == "circle" {
                let size: CGFloat = 120
                bubble.frame = CGRect(x: width - size - 16, y: y, width: size, height: size)
                bubble.subviews.first?.frame = bubble.bounds
                y = bubble.frame.maxY + 8
                continue
            }
            guard let label = bubble.subviews.first as? UILabel else { continue }
            let size = label.sizeThatFits(CGSize(width: width * 0.72, height: .greatestFiniteMagnitude))
            let frame = CGRect(
                x: label.tag == 1 ? width - size.width - 36 : 12,
                y: y,
                width: size.width + 24,
                height: size.height + 16
            )
            bubble.frame = frame
            label.frame = CGRect(x: 12, y: 8, width: size.width, height: size.height)
            y = frame.maxY + 8
        }
        let hintSize = hint.sizeThatFits(CGSize(width: width - 48, height: .greatestFiniteMagnitude))
        hint.frame = CGRect(x: 16, y: y + 12, width: width - 32, height: hintSize.height + 20)
        hint.textAlignment = .left
        // padding via preferred layout — inset text visually
        statusLabel.frame = CGRect(x: 16, y: hint.frame.maxY + 10, width: width - 32, height: 18)
        chatContent.frame = CGRect(x: 0, y: 0, width: width, height: statusLabel.frame.maxY + 24)
        chat.contentSize = chatContent.bounds.size
    }

    private func buildComposer() {
        composer.backgroundColor = UIColor(red: 0.09, green: 0.13, blue: 0.18, alpha: 1)
        view.addSubview(composer)

        inputField.backgroundColor = UIColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 1)
        inputField.layer.cornerRadius = 18
        inputField.layer.borderWidth = 1
        inputField.layer.borderColor = UIColor(white: 1, alpha: 0.06).cgColor
        composer.addSubview(inputField)
        let placeholder = UILabel()
        placeholder.text = "Message"
        placeholder.textColor = UIColor(white: 0.45, alpha: 1)
        placeholder.font = .systemFont(ofSize: 15)
        placeholder.tag = 10
        inputField.addSubview(placeholder)

        recordButton.backgroundColor = UIColor(red: 0.2, green: 0.565, blue: 0.925, alpha: 1)
        recordButton.tintColor = .white
        recordButton.layer.cornerRadius = 24
        recordButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        recordButton.layer.shadowColor = UIColor(red: 0.2, green: 0.565, blue: 0.925, alpha: 1).cgColor
        recordButton.layer.shadowOpacity = 0.45
        recordButton.layer.shadowRadius = 10
        recordButton.layer.shadowOffset = .zero
        composer.addSubview(recordButton)

        let pan = UILongPressGestureRecognizer(target: self, action: #selector(handleHold(_:)))
        pan.minimumPressDuration = 0.01
        pan.allowableMovement = 10_000
        recordButton.addGestureRecognizer(pan)
    }

    private func layoutComposer() {
        let bottom = view.safeAreaInsets.bottom
        let y: CGFloat = 8
        recordButton.frame = CGRect(x: composer.bounds.width - 56, y: y, width: 48, height: 48)
        inputField.frame = CGRect(x: 12, y: y + 4, width: recordButton.frame.minX - 24, height: 40)
        inputField.viewWithTag(10)?.frame = CGRect(x: 14, y: 10, width: 120, height: 20)
        _ = bottom
    }

    // MARK: - Camera select (the feature)

    private func wireSelect() {
        select.onFacingChange = { [weak self] facing in
            guard let self else { return }
            self.statusLabel.text = facing == .front ? "recording · front" : "recording · main"
            Task { await self.ensurePreview(facing: facing) }
        }
        select.onFinished = { [weak self] facing in
            guard let self else { return }
            self.isHolding = false
            self.hidePreview()
            if let facing {
                self.statusLabel.text = "sent · \(facing == .front ? "front" : "main")"
                self.appendCircle(facing: facing)
            } else {
                self.statusLabel.text = "cancelled"
            }
        }
        select.onSample = { [weak self] sample, phase in
            if case .cancelArmed = phase {
                self?.statusLabel.text = "release to cancel"
            } else if case .armed = phase {
                self?.statusLabel.text = "pull up · front / further · main"
            }
            _ = sample
        }
    }

    @objc private func handleHold(_ gr: UILongPressGestureRecognizer) {
        let location = gr.location(in: view)
        switch gr.state {
        case .began:
            isHolding = true
            let anchor = recordButton.convert(recordButton.bounds, to: view)
            select.attachRail(above: anchor, in: view)
            select.begin(at: location)
            statusLabel.text = "armed"
            UIView.animate(withDuration: 0.12) {
                self.recordButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }
        case .changed:
            select.move(to: location)
        case .ended, .cancelled, .failed:
            select.end()
            UIView.animate(withDuration: 0.12) {
                self.recordButton.transform = .identity
            }
        default:
            break
        }
    }

    private func prewarmRecorder() async {
        let rec = CameraSelectRecorder()
        do {
            try await rec.prepare()
            await MainActor.run { self.recorder = rec }
        } catch {
            await MainActor.run { self.statusLabel.text = "camera unavailable (sim ok for gesture)" }
        }
    }

    private func ensurePreview(facing: CameraSelectFacing) async {
        guard let recorder else { return }
        do {
            try recorder.setFacing(facing)
            if !recorder.isRecording {
                recorder.startRecording()
            }
        } catch {
            // Simulator without camera still demos the rail.
        }
        await MainActor.run {
            if self.previewHost == nil {
                let host = UIView(frame: self.view.bounds)
                host.backgroundColor = .black
                host.isUserInteractionEnabled = false
                host.alpha = 0
                self.view.insertSubview(host, belowSubview: self.select.railView)
                let layer = recorder.previewLayer
                layer.frame = host.bounds
                host.layer.addSublayer(layer)
                self.previewHost = host
                UIView.animate(withDuration: 0.2) { host.alpha = 1 }
            } else {
                self.previewHost?.layer.sublayers?.first?.frame = self.previewHost?.bounds ?? .zero
            }
            // Keep rail + composer chrome above preview.
            self.view.bringSubviewToFront(self.select.railView)
            self.view.bringSubviewToFront(self.composer)
        }
    }

    private func hidePreview() {
        guard let host = previewHost else { return }
        UIView.animate(withDuration: 0.15, animations: { host.alpha = 0 }) { _ in
            host.removeFromSuperview()
        }
        previewHost = nil
        Task { _ = await recorder?.stopRecording() }
    }

    private func appendCircle(facing: CameraSelectFacing) {
        let size: CGFloat = 120
        let circle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        circle.backgroundColor = facing == .front
            ? UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1)
            : UIColor(red: 0.25, green: 0.45, blue: 0.35, alpha: 1)
        circle.layer.cornerRadius = size / 2
        circle.layer.borderWidth = 3
        circle.layer.borderColor = UIColor(red: 0.2, green: 0.565, blue: 0.925, alpha: 1).cgColor
        let label = UILabel(frame: circle.bounds)
        label.text = facing == .front ? "front" : "main"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.tag = 1
        circle.addSubview(label)
        // Mark as fixed-size outgoing circle for layoutBubbles.
        circle.accessibilityIdentifier = "circle"
        chatContent.addSubview(circle)
        bubbles.append(circle)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        chat.setContentOffset(CGPoint(x: 0, y: max(0, chat.contentSize.height - chat.bounds.height)), animated: true)
    }
}

@main
final class DemoAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = DemoSceneDelegate.self
        return configuration
    }
}

final class DemoSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = DemoViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
