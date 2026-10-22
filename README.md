# Camera Select — pull-up camera choice for video notes

Recording a video note usually means the front camera. This feature keeps Telegram’s
**hold** interaction, but maps the vertical pull to **which camera** you use — not to a lock.

- Pull up a little → **front** (person circle)
- Pull further → **main** (camera + chevron pill)
- Release → send · slide left → cancel
- **No lock** for video notes (hold-only; voice lock unchanged)

What we ship is small on purpose: **two overlay buttons** + gesture + public controller.
The chat chrome is only a foundation to pin them onto (same idea as the BlackHole demo shell).

Pure UIKit, no SwiftUI, no dependencies. iOS 15+.

▶︎ [Media/demo.mp4](Media/demo.mp4) — record from the UIKit demo and drop the file here.

## Repository

| Path | What |
|---|---|
| `CameraSelectMessage/` | Drop-in Telegram-iOS module (`submodules/TelegramUI/Components/Chat/CameraSelectMessage`). |
| `CameraSelectMessage/BUILD` | Bazel `swift_library` + resource bundle (Figma button reference PNG). |
| `CameraSelectMessage/Sources/CameraSelectConfig.swift` | Thresholds and chrome sizes. |
| `CameraSelectMessage/Sources/CameraSelectGesture.swift` | Pure Swift gesture resolver. |
| `CameraSelectMessage/Sources/CameraSelectButtons.swift` | **The two custom controls** — main pill + front circle with frosted glass (`UIVisualEffectView`). |
| `CameraSelectMessage/Sources/CameraSelectController.swift` | Public API (`begin` / `move` / `end`, rail attach, callbacks). |
| `CameraSelectMessage/Sources/CameraSelectRecorder.swift` | Demo-only AVFoundation stand-in — **not** used inside Telegram. |
| `Integration/ChatControllerCameraSelectVideoNote.swift` | Hook into InstantVideo / video-note hold (`ChatControllerImpl`). |
| `Demo/` | Standalone UIKit demo — `build-demo.sh` → simulator (no Xcode project). |
| `Media/demo.mp4` | Screen recording for the contest. |

## How it works

```
composer record button (Telegram)
  └─ hold recognizer
        .began   → CameraSelectController.attachRail + begin
        .changed → move
        .ended   → end → onFinished(facing?)
  └─ CameraSelectRailView          ← only custom UI we own
        main pill   camera + ⌃     (back zone)
        front circle person        (front zone)
  └─ onFacingChange(facing)        → Telegram InstantVideo / Camera position
```

* **Voice-lock DNA, different meaning.** Same vertical pull muscle memory; zones are
  cameras; there is no locked hands-free state for circles.
* **Recording starts at the first camera zone** (`frontPull`), not on bare press.
* **Cancel** mirrors Telegram: slide left past `cancelDistance`.

## Integration into Telegram-iOS

1. **Module.** Copy `CameraSelectMessage/` to
   `submodules/TelegramUI/Components/Chat/CameraSelectMessage/` as is.
2. **TelegramUI.** Add `"//submodules/TelegramUI/Components/Chat/CameraSelectMessage"`
   to `deps` in `submodules/TelegramUI/BUILD` and put
   `Integration/ChatControllerCameraSelectVideoNote.swift` into
   `submodules/TelegramUI/Sources/Chat/`.
3. **Hook.** In the video-note press-and-hold path (InstantVideo), drive the controller
   from the existing recognizer and **skip the lock capsule** on this path:

   ```swift
   // .began
   let select = self.prepareCameraSelectVideoNote()
   let buttonFrame = recordButton.convert(recordButton.bounds, to: panelView)
   select?.attachRail(above: buttonFrame, in: panelView)
   select?.begin(at: location)

   // .changed
   select?.move(to: location)

   // .ended
   select?.end() // onFinished → send or discard
   ```

4. **Capture.** On `onFacingChange`, set the capture device position and start / switch
   the existing InstantVideo controller. Do **not** ship `CameraSelectRecorder` into Telegram.

### What the integration does

* Pins the two Figma buttons above the record control.
* Resolves facing from pull distance; fires haptics at zone thresholds.
* Leaves voice-message lock, slide-to-cancel, and Telegram’s encoder untouched.

## Standalone demo

Requires macOS + Xcode CLT (same as [black-hole-delete](https://github.com/riveauxmia/telegram-black-hole-delete)):

```sh
Demo/build-demo.sh "iPhone 16 Pro"
xcrun simctl launch --terminate-running-process "iPhone 16 Pro" demo.cameraselectmessage.kit
```

Hold the blue button → pull to the person circle (front) or the camera pill (main) →
release to drop a circle into the fake chat. Simulator without a camera still demos the rail.

## Parameters

`CameraSelectConfig` — defaults tuned to the Figma marks:

| Parameter | Default | Meaning |
|---|---|---|
| `frontPull` | 56 pt | Short pull → front + start |
| `backPull` | 132 pt | Further pull → main |
| `cancelDistance` | 72 pt | Slide left to cancel |
| `frontButtonSize` | 44 pt | Person circle |
| `mainPillSize` | 44×72 pt | Camera + chevron pill |
| `railSpacing` | 16 pt | Gap between the two marks |
| `hapticsEnabled` | true | Light @ front, medium @ main |

## Notes and limits

* Single-camera devices still show both marks; hardware may map both to one device.
* Reduce Motion: `prepareCameraSelectVideoNote()` returns nil → stock front-only path.
* Mid-hold camera switch can hitch; Telegram’s capture stack may restart the session.
* Permissions: same camera + mic as today’s video notes.

## Why this fits Telegram

Circles are often “show what I see”, not only selfies. Teaching a new button is expensive;
teaching **one more inch on a gesture people already know** is cheap. We only add two
overlay marks — the rest is Telegram.
