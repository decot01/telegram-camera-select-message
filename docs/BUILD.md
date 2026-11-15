# Building Camera Select for Android

Apply [`changes.patch`](../changes.patch) to a clean checkout of official Telegram Android at commit `7be672ead283d022812d75c729d3a04dd4c2a2c6` (13.2.1 / 7291). Set up the SDK, NDK, signing and local files as described in Telegram's own README.

## Telegram API credentials

Use your own `api_id` and `api_hash` from [my.telegram.org/apps](https://my.telegram.org/apps). See [Telegram's API ID requirements](https://core.telegram.org/api/obtaining_api_id). Published demo credentials can return `API_ID_PUBLISHED_FLOOD`.

Copy [`api.properties.example`](../api.properties.example) to `api.properties` **beside the Telegram source directory**, then fill in the local file:

```text
TelegramBuild/
  api.properties
  Telegram/
```

Gradle reads this file and generates `BuildConfig.CLIENT_API_ID` and `CLIENT_API_HASH`. Missing or malformed values stop the build. Keep the file private; do not commit it.

For an existing production account, leave **Test backend** disabled when signing in. The test backend has separate accounts and chats.

## Toolchain and build

The verified toolchain was JDK 17, Gradle 8.13, Android SDK / Build Tools 36, NDK 27.2.12479018 and CMake 3.22.1. On Windows, use an ASCII path for the source and build directories: CMake/Ninja can fail on Cyrillic paths.

From the Telegram source directory:

```sh
./gradlew :TMessagesProj_App:assembleAfatDebug
```

If the checkout has no `gradlew.bat`, run the wrapper from PowerShell:

```powershell
& "$env:JAVA_HOME/bin/java.exe" -classpath gradle/wrapper/gradle-wrapper.jar org.gradle.wrapper.GradleWrapperMain :TMessagesProj_App:assembleAfatDebug
```

The output is `TMessagesProj_App/build/outputs/apk/afat/debug/app.apk`. The package is `org.telegram.messenger.beta`, installed separately from regular Telegram. The universal build includes ARM 32/64 and x86 32/64. Runtime `DEBUG_VERSION` and `DEBUG_PRIVATE_VERSION` are disabled to avoid expensive debug checks during use.

## Optional: reuse matching native libraries

The feature changes Java code and resources, so C++ does not need to be rebuilt for each iteration. To use this shortcut, obtain `lib/<abi>/libtmessages.49.so` from a verified official APK of the **same version: 13.2.1 (7291)**.

Place the libraries beside the source directory:

```text
TelegramBuild/
  api.properties
  prebuilt-native/
    arm64-v8a/libtmessages.49.so
    armeabi-v7a/libtmessages.49.so
    x86/libtmessages.49.so
    x86_64/libtmessages.49.so
  Telegram/
```

Add `-PusePrebuiltNative=true` to the Gradle task. Without it, the build compiles C++ normally. Prebuilt libraries and APKs are not stored in this repository.

## Gesture and placement checks

From this patch repository:

```sh
python tools/test_gesture.py
```

Python 3 and a JDK are required. Set `JAVA_HOME`, or put `java` and `javac` on `PATH`.

The script compiles the actual gesture and placement classes extracted from the patch. It covers fast swipes, changes before release, cancellation, no automatic recording while holding, and placement across eight densities and six bar positions, including parent offsets for the chat header. The selector's lower edge is placed 80 physical pixels above the input container, with its actual laid-out position used for gesture thresholds.

The v6 APK was built and checked for signing, alignment, all four architectures and the final implementation. The input spacing was manually confirmed on a device. The native recording-bar drawing and locked-recording transition were compared with the original source. There are no automated camera tests on a device or measured S21 frame-rate results.
