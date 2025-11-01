import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:worldwide_channel_surf/providers/settings_provider.dart';

/// Service for phone-based TV setup via local web server
/// Creates a local HTTP server that serves an HTML form for TMDb API key entry
class DeviceAuthService {
  HttpServer? _server;
  final int _port = 8080;
  final Completer<String> _keyCompleter = Completer<String>();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Start the local web server and return the URL to display
  Future<String> startSetupServer(WidgetRef ref) async {
    if (_server != null) {
      return await _getServerUrl();
    }

    final router = Router();

    // Serve the HTML form
    router.get('/', (Request request) {
      return Response.ok(_getSetupHtml(), headers: {
        'Content-Type': 'text/html; charset=utf-8',
      });
    });

    // Handle form submission
    router.post('/save', (Request request) async {
      final body = await request.readAsString();
      final params = Uri.splitQueryString(body);
      final apiKey = params['api_key']?.trim();

      if (apiKey == null || apiKey.isEmpty) {
        return Response.badRequest(
          body: 'API key is required',
          headers: {'Content-Type': 'text/plain'},
        );
      }

      // Complete the completer with the API key
      // The caller (home_screen) will handle saving via provider
      if (!_keyCompleter.isCompleted) {
        _keyCompleter.complete(apiKey);
      }

      return Response.ok(
        _getSuccessHtml(),
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    });

    try {
      // Get local IP address
      final ipAddress = await _networkInfo.getWifiIP() ?? 
                       await _networkInfo.getWifiGatewayIP() ?? 
                       'localhost';

      _server = await shelf_io.serve(
        router,
        ipAddress == 'localhost' 
            ? InternetAddress.loopbackIPv4 
            : InternetAddress(ipAddress),
        _port,
      );

      return 'http://$_server!.address.host:$_port';
    } catch (e) {
      throw Exception('Failed to start setup server: $e');
    }
  }

  /// Wait for the API key to be submitted via the web form
  Future<String> waitForApiKey() async {
    return await _keyCompleter.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () {
        throw TimeoutException('Setup timeout - no key received');
      },
    );
  }

  /// Stop the setup server
  Future<void> stopServer() async {
    try {
      await _keyCompleter.future.timeout(
        const Duration(seconds: 1),
      );
    } catch (_) {
      // Ignore timeout if already completed
    }
    
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }

  /// Get the server URL for display
  Future<String> _getServerUrl() async {
    if (_server == null) {
      throw Exception('Server not started');
    }
    return 'http://${_server!.address.host}:$_port';
  }

  String _getSetupHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TV Setup - Worldwide Channel Surf</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-top: 0;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #555;
            font-weight: 500;
        }
        input[type="text"] {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
            box-sizing: border-box;
        }
        button {
            background: #2196F3;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 4px;
            font-size: 16px;
            cursor: pointer;
            width: 100%;
        }
        button:hover {
            background: #1976D2;
        }
        .info {
            background: #e3f2fd;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
            font-size: 14px;
            color: #1976d2;
        }
        .info a {
            color: #1976d2;
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📺 TV Setup</h1>
        <div class="info">
            <strong>Get your TMDb API key:</strong><br>
            Visit <a href="https://www.themoviedb.org/settings/api" target="_blank">themoviedb.org/settings/api</a>
            and create a free API key. Then paste it below.
        </div>
        <form id="setupForm">
            <div class="form-group">
                <label for="api_key">TMDb API Key:</label>
                <input type="text" id="api_key" name="api_key" required 
                       placeholder="Paste your API key here">
            </div>
            <button type="submit">Save & Continue</button>
        </form>
    </div>
    <script>
        document.getElementById('setupForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const apiKey = document.getElementById('api_key').value;
            const formData = new URLSearchParams();
            formData.append('api_key', apiKey);
            
            fetch('/save', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: formData
            })
            .then(response => response.text())
            .then(html => {
                document.body.innerHTML = html;
            })
            .catch(error => {
                alert('Error: ' + error);
            });
        });
    </script>
</body>
</html>
''';
  }

  String _getSuccessHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Setup Complete</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .success-icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            color: #4CAF50;
            margin-top: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon">✅</div>
        <h1>Setup Complete!</h1>
        <p>Your TMDb API key has been saved successfully.</p>
        <p>You can now close this page. The TV app will update automatically.</p>
    </div>
</body>
</html>
''';
  }
}

final deviceAuthServiceProvider = Provider<DeviceAuthService>((ref) => DeviceAuthService());

