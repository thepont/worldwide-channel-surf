import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;

// Import webview_cef for desktop platforms (Linux/Windows/macOS)
import 'package:webview_cef/webview_cef.dart' as cef_webview;
// Import webview_flutter for mobile platforms (Android/iOS)
import 'package:webview_flutter/webview_flutter.dart' as mobile_webview;
class BrowserScreen extends ConsumerStatefulWidget {
  final String url;
  final String channelName;

  const BrowserScreen({
    super.key,
    required this.url,
    required this.channelName,
  });

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> with WidgetsBindingObserver {
  mobile_webview.WebViewController? _mobileController;
  cef_webview.WebViewController? _cefController;
  bool _isLoading = true;
  bool _spatialNavInjected = false;
  final bool _isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  MethodChannel? _cefChannel;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer initialization until after first frame is rendered
    // This prevents GTK window creation errors
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Use CEF webview on desktop (Linux/Windows/macOS), webview_flutter on mobile (Android/iOS)
      if (_isDesktop) {
        await _initializeCefWebView();
      } else {
        _initializeMobileWebView();
      }
      // Request focus for keyboard events after webview is ready
      _focusNode.requestFocus();
    });
  }



  Future<void> _initializeCefWebView() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Small delay to ensure GTK is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Create CEF webview controller
      _cefChannel = const MethodChannel('webview_cef');
      final index = DateTime.now().millisecondsSinceEpoch;
      
      // Initialize CEF controller
      _cefController = cef_webview.WebViewController(_cefChannel!, index);
      
      // Configure proxy if VPN is connected (TODO: implement proxy config)
      // CEF proxy can be set via command-line args when starting CEF
      // For now, we'll rely on system routing through VPN
      
      // Initialize and load URL
      // Wrap in try-catch as initialize may fail if CEF isn't ready
      try {
        await _cefController!.initialize(widget.url);
      } catch (e) {
        // If initialize fails due to CEF not being ready, wait and retry
        if (e.toString().contains('_creatingCompleter') || 
            e.toString().contains('LateInitializationError')) {
          print('CEF not ready yet, waiting and retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted || _cefController == null) return;
          
          try {
            await _cefController!.initialize(widget.url);
          } catch (e2) {
            print('Retry failed: $e2');
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      
      if (!mounted) return;
      
      // Inject spatial navigation after page loads
      // Note: CEF may need page load event - check webview_cef API for onPageFinished equivalent
      
      // Listen for loading state
      _cefController!.addListener(() {
        if (mounted) {
          final isReady = _cefController!.value;
          setState(() {
            _isLoading = !isReady;
          });
          // Inject spatial nav when ready
          if (isReady && !_spatialNavInjected) {
            _injectSpatialNavigation(_cefController!);
          }
        }
      });
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Failed to initialize CEF webview: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize browser: $e'),
            action: SnackBarAction(
              label: 'Open in system browser',
              onPressed: _openInSystemBrowser,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _initializeMobileWebView() {
    try {
      _mobileController = mobile_webview.WebViewController()
        ..setJavaScriptMode(mobile_webview.JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          mobile_webview.NavigationDelegate(
            onPageStarted: (String url) {
              _spatialNavInjected = false;
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) async {
              // Inject spatial navigation JavaScript
              await _injectSpatialNavigation(_mobileController!);
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _spatialNavInjected = true;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      print('Failed to initialize mobile webview: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize browser: $e'),
            action: SnackBarAction(
              label: 'Open in system browser',
              onPressed: _openInSystemBrowser,
            ),
          ),
        );
      }
    }
  }

  /// Inject spatial navigation JavaScript into the webview
  Future<void> _injectSpatialNavigation(dynamic controller) async {
    try {
      // Load spatial navigation script from assets
      final script = await rootBundle.loadString('assets/js/spatial_navigation.js');
      
      // Initialize spatial navigation
      final initScript = '''
$script

// Initialize spatial navigation
SpatialNavigation.init();
SpatialNavigation.add({
  selector: 'a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])',
});

// Make all focusable elements navigable
SpatialNavigation.makeFocusable();

// Start spatial navigation
SpatialNavigation.focus();
''';

      if (_isDesktop && _cefController != null) {
        // CEF webview - use executeJavaScript method
        try {
          await _cefController!.executeJavaScript(initScript);
        } catch (e) {
          print('Failed to inject spatial nav in CEF: $e');
        }
      } else if (!_isDesktop && _mobileController != null) {
        // Mobile webview - inject JavaScript
        await _mobileController!.runJavaScript(initScript);
      }
    } catch (e) {
      print('Error injecting spatial navigation: $e');
    }
  }

  /// Handle keyboard events for D-pad navigation
  bool _handleKeyEvent(KeyEvent event) {
    if (!_spatialNavInjected && !_isLoading) {
      return false;
    }

    final isArrowKey = event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select;

    if (event is KeyDownEvent) {
      if (isArrowKey) {
        // Fire and forget - async execution
        _handleArrowKey(event.logicalKey);
        return true;
      } else if (isEnter) {
        _handleEnterKey();
        return true;
      }
    }

    return false;
  }

  Future<void> _handleArrowKey(LogicalKeyboardKey key) async {
    String direction;
    if (key == LogicalKeyboardKey.arrowUp) {
      direction = 'up';
    } else if (key == LogicalKeyboardKey.arrowDown) {
      direction = 'down';
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      direction = 'left';
    } else {
      direction = 'right';
    }

    final script = 'SpatialNavigation.move("$direction");';

    if (_isDesktop && _cefController != null) {
      // CEF webview
      try {
        await _cefController!.executeJavaScript(script);
      } catch (e) {
        print('Failed to execute spatial nav in CEF: $e');
      }
    } else if (!_isDesktop && _mobileController != null) {
      // Mobile webview
      _mobileController!.runJavaScript(script);
    }
  }

  void _handleEnterKey() {
    const script = 'document.activeElement?.click();';

    if (_isDesktop && _cefController != null) {
      // CEF webview
      try {
        _cefController!.executeJavaScript(script);
      } catch (e) {
        print('Failed to execute click in CEF: $e');
      }
    } else if (!_isDesktop && _mobileController != null) {
      // Mobile webview
      _mobileController!.runJavaScript(script);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cefController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openInSystemBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Close this screen after opening in system browser
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${widget.url}'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in KeyboardListener for D-pad navigation
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Desktop: Use CEF webview (Chromium embedded)
    if (_isDesktop) {
      if (_cefController == null || !_cefController!.value) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.channelName),
          ),
          body: Center(
            child: _cefController?.loadingWidget ?? const CircularProgressIndicator(),
          ),
        );
      }
      
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _cefController?.reload();
                setState(() {
                  _isLoading = true;
                  _spatialNavInjected = false;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: _openInSystemBrowser,
              tooltip: 'Open in system browser',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Embedded Chromium browser widget
            _cefController!.webviewWidget,
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      );
    }

    // Mobile: Use webview_flutter (Android/iOS)
    if (_mobileController == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _mobileController?.reload();
              setState(() {
                _spatialNavInjected = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInSystemBrowser,
            tooltip: 'Open in system browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          mobile_webview.WebViewWidget(controller: _mobileController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

