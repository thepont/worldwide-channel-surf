import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/providers/settings_provider.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/core/geo_ip_service.dart';
import 'package:worldwide_channel_surf/core/tmdb_service.dart';
import 'package:worldwide_channel_surf/core/device_auth_service.dart';
import 'package:worldwide_channel_surf/core/device_info_service.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';
import 'package:worldwide_channel_surf/features/home/screens/provider_selection_screen.dart';

/// Provider for trending shows based on current region
final trendingShowsProvider = FutureProvider.family<List<ShowSummary>, RegionId>(
  (ref, region) async {
    final apiKey = ref.watch(tmdbApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API key not set');
    }
    final tmdbService = TmdbService(apiKey: apiKey);
    return await tmdbService.getTrendingShows(region);
  },
);

/// Provider for show watch provider
final showWatchProviderProvider = FutureProvider.family<WatchProvider?, ({int showId, RegionId region, String mediaType})>(
  (ref, params) async {
    final apiKey = ref.watch(tmdbApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }
    final tmdbService = TmdbService(apiKey: apiKey);
    return await tmdbService.getShowWatchProvider(
      params.showId,
      params.region,
      params.mediaType,
    );
  },
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the initial IP lookup on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectInitialRegion();
    });
  }

  Future<void> _detectInitialRegion() async {
    // Only detect if no region is already set
    if (ref.read(currentRegionProvider) == null && mounted) {
      final region = await ref.read(geoIpServiceProvider).getRegionFromIp();
      if (mounted && region != null) {
        ref.read(currentRegionProvider.notifier).state = region;
      }
    }
  }

  Future<void> _onShowTap(BuildContext context, ShowSummary show) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get all watch providers for this show across all regions
      final apiKey = ref.read(tmdbApiKeyProvider);
      if (apiKey == null) {
        throw Exception('TMDb API key not set');
      }
      
      final tmdbService = TmdbService(apiKey: apiKey);
      final providers = await tmdbService.getAllWatchProviders(
        show.id,
        show.mediaType,
      );

      // Pop loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (providers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No watch providers found for "${show.name}"'),
            ),
          );
        }
        return;
      }

      // Navigate to provider selection screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProviderSelectionScreen(
              show: show,
              providers: providers,
            ),
          ),
        );
      }
    } catch (e) {
      // Pop loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(tmdbApiKeyProvider);
    final currentRegion = ref.watch(currentRegionProvider);

    // If no API key, show setup screen
    if (apiKey == null) {
      return _ApiKeySetupScreen(
        onSetupComplete: () {
          setState(() {});
        },
      );
    }

    // If no region set, show loading
    if (currentRegion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('International Content Browser'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Main content: Trending shows GridView
    return Scaffold(
      appBar: AppBar(
        title: const Text('International Content Browser'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _RegionDropdown(currentRegion: currentRegion),
          ),
        ],
      ),
      body: _TrendingShowsGrid(
        region: currentRegion,
        onShowTap: (show) => _onShowTap(context, show),
      ),
    );
  }
}

/// Setup screen for TMDb API key (supports multiple setup modes)
class _ApiKeySetupScreen extends ConsumerStatefulWidget {
  final VoidCallback onSetupComplete;

  const _ApiKeySetupScreen({required this.onSetupComplete});

  @override
  ConsumerState<_ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<_ApiKeySetupScreen> {
  // Setup mode: 'direct', 'qr', or 'browser'
  String _setupMode = 'auto'; // Will be determined based on device
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  // Browser setup mode
  String? _serverUrl;
  bool _isServerRunning = false;
  
  // Flag to force browser setup on PC (for testing)
  static const bool _forceBrowserSetup = false; // Set to true for testing

  @override
  void initState() {
    super.initState();
    _determineSetupMode();
  }

  void _determineSetupMode() {
    if (_forceBrowserSetup && DeviceInfoService.isDesktop) {
      _setupMode = 'browser';
      _startSetupServer();
    } else if (DeviceInfoService.supportsDirectInput) {
      _setupMode = 'direct';
    } else {
      _setupMode = 'qr';
      _startSetupServer();
    }
  }

  Future<void> _startSetupServer() async {
    try {
      final authService = ref.read(deviceAuthServiceProvider);
      final url = await authService.startSetupServer(ref);
      
      setState(() {
        _serverUrl = url;
        _isServerRunning = true;
      });

      // Wait for API key from the web form
      authService.waitForApiKey().then((apiKey) async {
        try {
          // Save the key via provider
          await ref.read(tmdbApiKeyProvider.notifier).saveKey(apiKey);
          
          // Verify the key was actually saved
          await Future.delayed(const Duration(milliseconds: 100));
          final savedKey = ref.read(tmdbApiKeyProvider);
          
          if (savedKey != apiKey) {
            throw Exception('Key was not saved correctly. Expected: $apiKey, Got: $savedKey');
          }
          
          // Stop the server
          await authService.stopServer();
          
          if (mounted) {
            widget.onSetupComplete();
          }
        } catch (e, stackTrace) {
          print('Error saving API key from browser: $e');
          print('Stack trace: $stackTrace');
          if (mounted) {
            setState(() {
              _error = 'Failed to save API key: $e';
              _isServerRunning = false;
            });
          }
        }
      }).catchError((e) {
        print('Error waiting for API key: $e');
        if (mounted) {
          setState(() {
            _error = 'Setup timed out or failed: $e';
            _isServerRunning = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start setup server: $e';
      });
    }
  }

  Future<void> _saveDirectInput() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      setState(() {
        _error = 'Please enter your TMDb API key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get notifier before any async operations
      final notifier = ref.read(tmdbApiKeyProvider.notifier);
      await notifier.saveKey(apiKey);
      
      if (!mounted) return;
      
      // Verify the key was actually saved
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Re-check ref is still valid
      if (!mounted) return;
      final savedKey = ref.read(tmdbApiKeyProvider);
      
      if (savedKey != apiKey) {
        throw Exception('Key was not saved correctly. Expected: $apiKey, Got: $savedKey');
      }
      
      if (mounted) {
        widget.onSetupComplete();
      }
    } catch (e, stackTrace) {
      print('Error saving API key: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to save API key: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openBrowserSetup() async {
    if (_serverUrl != null) {
      final uri = Uri.parse(_serverUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _error = 'Could not open browser';
        });
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    if (_isServerRunning) {
      ref.read(deviceAuthServiceProvider).stopServer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          // Mode switcher for desktop (for testing)
          if (DeviceInfoService.isDesktop && !_forceBrowserSetup)
            PopupMenuButton<String>(
              onSelected: (mode) {
                setState(() {
                  _setupMode = mode;
                  if (mode == 'browser' || mode == 'qr') {
                    _startSetupServer();
                  }
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'direct',
                  child: Text('Direct Input'),
                ),
                const PopupMenuItem(
                  value: 'browser',
                  child: Text('Browser Setup'),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.settings, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Worldwide Channel Surf',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To get started, you need to provide your TMDb API key.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get your free API key at:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://www.themoviedb.org/settings/api');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'themoviedb.org/settings/api',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Direct Input Mode (PC/Android non-TV)
              if (_setupMode == 'direct') ...[
                TextField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'TMDb API Key',
                    hintText: 'Paste your API key here',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  obscureText: false,
                  enabled: !_isLoading,
                  onSubmitted: (_) => _saveDirectInput(),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDirectInput,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save & Continue'),
                  ),
                ),
              ]

              // Browser Setup Mode (PC testing)
              else if (_setupMode == 'browser') ...[
                if (_serverUrl != null && _isServerRunning) ...[
                  const Text(
                    'Setup via Browser',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Click the button below to open the setup page in your browser:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openBrowserSetup,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Setup in Browser'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Or visit this URL:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _serverUrl!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ] else if (_error != null) ...[
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startSetupServer,
                    child: const Text('Retry'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Starting setup server...'),
                ],
              ]

              // QR Code Mode (TV devices)
              else if (_setupMode == 'qr') ...[
                if (_serverUrl != null && _isServerRunning) ...[
                  const Text(
                    'Scan this QR code with your phone:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _serverUrl!,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Or visit this URL on your phone:',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _serverUrl!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ] else if (_error != null) ...[
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startSetupServer,
                    child: const Text('Retry'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Starting setup server...'),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Region dropdown widget
class _RegionDropdown extends ConsumerWidget {
  final RegionId currentRegion;

  const _RegionDropdown({required this.currentRegion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Common regions for dropdown
    final regions = ['AU', 'UK', 'US', 'FR', 'DE', 'CA', 'IT', 'ES'];

    return DropdownButton<RegionId>(
      value: currentRegion,
      hint: const Text('Set Region', style: TextStyle(color: Colors.white)),
      underline: Container(),
      icon: const Icon(Icons.public, color: Colors.white),
      dropdownColor: Colors.blueGrey[800],
      style: const TextStyle(color: Colors.white),
      onChanged: (RegionId? newValue) {
        if (newValue != null) {
          ref.read(currentRegionProvider.notifier).state = newValue;
        }
      },
      items: regions.map((region) => DropdownMenuItem<RegionId>(
        value: region,
        child: Text(region),
      )).toList(),
    );
  }
}

/// GridView of trending shows
class _TrendingShowsGrid extends ConsumerWidget {
  final RegionId region;
  final Function(ShowSummary) onShowTap;

  const _TrendingShowsGrid({
    required this.region,
    required this.onShowTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showsAsync = ref.watch(trendingShowsProvider(region));

    return showsAsync.when(
      data: (shows) {
        if (shows.isEmpty) {
          return const Center(
            child: Text('No trending shows found for this region'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: shows.length,
          itemBuilder: (context, index) {
            final show = shows[index];
            return _ShowPosterCard(
              show: show,
              onTap: () => onShowTap(show),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading shows: ${err.toString()}'),
          ],
        ),
      ),
    );
  }
}

/// Show poster card widget
class _ShowPosterCard extends StatelessWidget {
  final ShowSummary show;
  final VoidCallback onTap;

  const _ShowPosterCard({
    required this.show,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: show.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: show.posterUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.tv,
                        size: 48,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.tv,
                      size: 48,
                      color: Colors.grey,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                show.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

