# Build Configuration Notes

This document tracks critical build configuration settings that were necessary to run the application. Use this as a reference if your local changes are overwritten by a `git pull` or other external updates.

## Gradle Configuration

- **File**: `android/gradle/wrapper/gradle-wrapper.properties`
- **Required Version**: `8.4`
- **Setting**: `distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip`
- **Reason**: Needed to satisfy the minimum requirements of the Android Gradle Plugin used in this project.

## Flutter/Dart Dependencies

- **File**: `pubspec.yaml`
- **Note**: Ensure that `flutter pub get` is run after any changes. If dependencies are overwritten, review the `pubspec.lock` or run `flutter pub upgrade` carefully.
- **Dependency Changes**: During the initial run, 15 dependencies were updated/resolved.

## iOS Identification

- **Physical Device ID**: `00008110-000425181E68401E`
- **Simulator ID**: `apple_ios_simulator`
- **Signing**: Requires a Development Team to be configured in Xcode (`ios/Runner.xcworkspace`).
