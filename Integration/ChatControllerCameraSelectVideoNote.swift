// Telegram-iOS integration:
//   submodules/TelegramUI/Sources/Chat/ChatControllerCameraSelectVideoNote.swift
// Add "//submodules/TelegramUI/Components/Chat/CameraSelectMessage" to TelegramUI/BUILD deps.
//
// Wire into the existing video-note / InstantVideo hold path (the control that today
// starts a circle on press-and-hold and uses slide-up for lock). We keep hold + slide
// left cancel; we replace lock with camera facing via CameraSelectController.

import Foundation
import UIKit
import Display
import CameraSelectMessage

extension ChatControllerImpl {
    /// Prepares camera-select for the next video-note hold.
    /// Returns nil when Reduce Motion is on — fall back to the stock front-only recorder.
    func prepareCameraSelectVideoNote() -> CameraSelectController? {
        if UIAccessibility.isReduceMotionEnabled {
            return nil
        }
        let controller = CameraSelectController(config: .default)
        // Host keeps InstantVideoController / Camera; we only publish facing.
        controller.onFacingChange = { [weak self] facing in
            self?.applyVideoNoteFacing(facing)
        }
        return controller
    }

    /// Call from the composer video-note press recognizer (.began / .changed / .ended),
    /// same place that currently drives lock + cancel.
    ///
    /// Suggested shape (names vary by Telegram-iOS revision):
    ///
    ///   // .began
    ///   let select = self.prepareCameraSelectVideoNote()
    ///   let buttonFrame = recordButton.convert(recordButton.bounds, to: panelView)
    ///   select?.attachRail(above: buttonFrame, in: panelView)
    ///   select?.begin(at: location)
    ///   // do NOT start InstantVideo yet — wait for onFacingChange
    ///
    ///   // .changed
    ///   select?.move(to: location)
    ///
    ///   // .ended
    ///   select?.end()  // onFinished(facing) → send or discard
    ///
    /// Important: do not present the lock capsule on this path. Voice lock stays as-is.
    func applyVideoNoteFacing(_ facing: CameraSelectFacing) {
        // Map onto Telegram's capture stack, e.g.:
        // self.videoRecorderValue?.setCameraPosition(facing == .front ? .front : .back)
        // if self.videoRecorderValue == nil { self.startInstantVideoRecording(...) }
        _ = facing
    }
}

/*
 Hook checklist (mirror BlackHoleDelete README step 3):

 1. Module — copy CameraSelectMessage/ →
    submodules/TelegramUI/Components/Chat/CameraSelectMessage/

 2. BUILD — deps += "//submodules/TelegramUI/Components/Chat/CameraSelectMessage"

 3. Recognizer — in the InstantVideo / video-note hold handler:
      • .began  → prepareCameraSelectVideoNote() + attachRail + begin
      • .changed → move
      • .ended → end; send if facing != nil
      • Skip lock UI for video notes (hold-only).

 4. Capture — onFacingChange sets device position and starts / switches the
    existing InstantVideoController. Do not use CameraSelectRecorder in production.

 5. Cancel — pullX past cancelDistance or release below frontPull → discard.
*/
