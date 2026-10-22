# Telegram-iOS: submodules/TelegramUI/Components/Chat/CameraSelectMessage/BUILD
# Sources/*.swift + Resources/CameraSelectButtons.png (design reference)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:resources.bzl", "apple_resource_bundle")
load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

filegroup(
    name = "CameraSelectMessageResources",
    srcs = glob(["Resources/**/*"]),
    visibility = ["//visibility:public"],
)

plist_fragment(
    name = "CameraSelectMessageResourcesBundleInfoPlist",
    extension = "plist",
    template = """
    <key>CFBundleIdentifier</key>
    <string>org.telegram.CameraSelectMessageResources</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleName</key>
    <string>CameraSelectMessage</string>
    """,
)

apple_resource_bundle(
    name = "CameraSelectMessageResourcesBundle",
    infoplists = [":CameraSelectMessageResourcesBundleInfoPlist"],
    resources = [":CameraSelectMessageResources"],
)

swift_library(
    name = "CameraSelectMessage",
    module_name = "CameraSelectMessage",
    srcs = glob(["Sources/**/*.swift"]),
    copts = ["-warnings-as-errors"],
    data = [":CameraSelectMessageResourcesBundle"],
    deps = [],
    visibility = ["//visibility:public"],
)
