import 'dart:io';

/// Service for detecting device type and capabilities
class DeviceInfoService {
  static bool get isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  /// Check if device is a TV device (Android TV or similar)
  /// For now, we assume Android devices are TVs unless explicitly configured otherwise
  /// In a production app, you'd use android_tv package or system properties
  static bool get isTVDevice {
    if (isAndroid) {
      // Check Android system property for TV mode
      // This is a simplified check - in production, use android_tv package
      // For now, we'll assume non-TV devices can use direct input
      return false; // We'll default to allowing direct input on Android
    }
    // Desktop platforms are not TVs
    return false;
  }

  /// Check if device supports direct keyboard input
  static bool get supportsDirectInput {
    return isDesktop || (isAndroid && !isTVDevice);
  }

  /// Check if device should use QR code setup (TV devices)
  static bool get shouldUseQrCodeSetup {
    return !supportsDirectInput;
  }
}

