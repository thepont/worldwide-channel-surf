import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _useSystemBrowser = false;

  @override
  void initState() {
    super.initState();
    // Check if we're on a platform that doesn't support webview
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      _useSystemBrowser = true;
      _openInSystemBrowser();
    } else {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
    } catch (e) {
      // Fallback to system browser if webview initialization fails
      _useSystemBrowser = true;
      _openInSystemBrowser();
    }
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
    // If using system browser, show a loading message while opening
    if (_useSystemBrowser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.channelName),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening in your default browser...'),
            ],
          ),
        ),
      );
    }

    // Use webview for mobile platforms
    if (_controller == null) {
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
              _controller?.reload();
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
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

