# Embedded Browser with VPN Proxy Solution

## Goal
Create a single browser window inside the Flutter app that routes ONLY its traffic through the VPN tunnel, while the rest of the app and system traffic remains unaffected.

## Architecture

### Components Needed:

1. **Local Proxy Server** (`lib/core/proxy_service.dart`)
   - Runs on localhost (e.g., port 8888)
   - Binds HTTP client to VPN interface (tun0/tun1)
   - Forwards browser requests through VPN tunnel
   - Routes responses back to webview

2. **Native WebView Widget** (Platform Channels)
   - Linux: WebKitGTK embedded widget
   - Uses platform channels to communicate with Flutter
   - Configured to use `http://localhost:8888` as proxy
   - Handles navigation, loading states, etc.

3. **Browser Screen Update**
   - Removes system browser fallback
   - Always uses embedded webview
   - Shows VPN status indicator
   - Handles proxy configuration

## Implementation Approaches

### Option A: Platform Channels + WebKitGTK (Recommended for Linux)

**Pros:**
- Native performance
- Full control over proxy settings
- Works well on Linux
- Can bind to specific network interface

**Cons:**
- Requires C/C++ code for platform channels
- More complex implementation
- Platform-specific code

**Implementation Steps:**
1. Create C++ plugin for Linux webview
2. Use WebKitGTK API to create embedded webview
3. Configure WebKitGTK to use HTTP proxy
4. Create MethodChannel for Flutter communication
5. Handle events (navigation, loading, etc.)

### Option B: Try to Fix webview_flutter for Linux

**Pros:**
- Uses existing package
- Less platform-specific code

**Cons:**
- webview_flutter doesn't officially support Linux
- May require fork/patches
- Limited proxy configuration options
- May not be able to bind to VPN interface

### Option C: Process-Based Embedded Browser

**Pros:**
- Can use any browser (Chromium, Firefox, etc.)
- Full proxy control via command-line args

**Cons:**
- Not truly embedded (separate window)
- Complex window embedding on Linux
- Process management overhead

## Recommended Implementation: Option A

### File Structure:
```
lib/
  core/
    proxy_service.dart          # Local proxy server
    vpn_interface_service.dart   # VPN interface detection
  features/
    browser/
      screens/
        browser_screen.dart      # Updated to use embedded webview
      widgets/
        native_webview.dart      # Platform channel wrapper
linux/
  libwebview/
    webview_plugin.cc            # C++ WebKitGTK implementation
    webview_plugin.h
```

### Key Technologies:
- **Proxy**: Dart `shelf` package for HTTP proxy server
- **WebView**: WebKitGTK via GObject Introspection or C bindings
- **Platform Channels**: Flutter MethodChannel/EventChannel

### Proxy Binding Strategy:
Since we can't directly bind HttpClient to an interface in Dart, we'll:
1. Detect VPN interface (tun0, etc.)
2. Use `ip route` to ensure proxy traffic routes through VPN
3. Or use platform channels to create network-bound HTTP client in C++

### Next Steps:
1. ✅ Create proxy service skeleton (done)
2. ⏳ Implement VPN interface detection
3. ⏳ Create Linux native webview plugin
4. ⏳ Integrate proxy with webview
5. ⏳ Update browser screen

## Alternative: Simpler Approach

If platform channels are too complex, we could:
1. Start local proxy server bound to VPN
2. Launch a minimal browser (like `surf` or custom Chromium) with proxy settings
3. Embed browser window using X11 embedding (complex but possible)

This is still complex but avoids writing C++ code for WebKitGTK.

## Questions to Consider:
1. Are you willing to add C++ code for Linux webview?
2. Should we prioritize getting this working on Linux first, then other platforms?
3. Do you have experience with WebKitGTK or platform channels?
4. Would a simpler approach (separate browser window with proxy) be acceptable?

