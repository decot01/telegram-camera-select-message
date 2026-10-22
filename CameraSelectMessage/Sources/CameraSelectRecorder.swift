import AVFoundation
import UIKit

/// Stand-in capture for the standalone Demo. Telegram-iOS should keep its own
/// InstantVideo / Camera pipeline and only consume `CameraSelectFacing` from
/// `CameraSelectController.onFacingChange`.
public final class CameraSelectRecorder: NSObject {
    public private(set) var facing: CameraSelectFacing = .front
    public private(set) var isRunning = false
    public var isRecording: Bool { movieOutput.isRecording }

    private let session = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private let movieOutput = AVCaptureMovieFileOutput()
    private var outputURL: URL?
    private var continuation: CheckedContinuation<URL?, Never>?

    public lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    public func prepare() async throws {
        session.beginConfiguration()
        session.sessionPreset = .high
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        try attach(.front)
        session.commitConfiguration()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
                cont.resume()
            }
        }
        isRunning = true
    }

    public func setFacing(_ facing: CameraSelectFacing) throws {
        guard self.facing != facing else { return }
        session.beginConfiguration()
        try attach(facing)
        session.commitConfiguration()
    }

    public func startRecording() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("video-note-\(UUID().uuidString).mp4")
        outputURL = url
        guard !movieOutput.isRecording else { return }
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    public func stopRecording() async -> URL? {
        guard movieOutput.isRecording else { return outputURL }
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.movieOutput.stopRecording()
        }
    }

    public func shutdown() {
        if movieOutput.isRecording { movieOutput.stopRecording() }
        session.stopRunning()
        isRunning = false
    }

    private func attach(_ facing: CameraSelectFacing) throws {
        if let videoInput {
            session.removeInput(videoInput)
            self.videoInput = nil
        }
        let position: AVCaptureDevice.Position = facing == .front ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
                ?? AVCaptureDevice.default(for: .video) else {
            throw CameraSelectError.noCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraSelectError.cannotAddInput }
        session.addInput(input)
        videoInput = input
        self.facing = facing
    }
}

public enum CameraSelectError: Error {
    case noCamera
    case cannotAddInput
}

extension CameraSelectRecorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        continuation?.resume(returning: error == nil ? outputFileURL : nil)
        continuation = nil
    }
}
