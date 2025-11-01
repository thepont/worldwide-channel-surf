import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:worldwide_channel_surf/providers/show_details_provider.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';
import 'package:worldwide_channel_surf/providers/user_settings_provider.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';

/// Show details screen - the central hub for viewing content and selecting providers
class ShowDetailsScreen extends ConsumerWidget {
  final int showId;
  final String mediaType; // 'tv' or 'movie'

  const ShowDetailsScreen({
    super.key,
    required this.showId,
    this.mediaType = 'tv',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(showDetailsProvider((showId: showId, mediaType: mediaType)));
    final optionsAsync = ref.watch(watchOptionsProvider((showId: showId, mediaType: mediaType)));
    final currentRegion = ref.watch(currentRegionProvider);
    final vpnConfigs = ref.watch(vpnConfigListProvider);

    return Scaffold(
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text("Error: ${err.toString()}"),
            ],
          ),
        ),
        data: (details) {
          final backdropPath = details['backdrop_path'] as String?;
          final backdropUrl = backdropPath != null
              ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
              : null;
          final name = details['name'] as String? ?? details['title'] as String? ?? 'No Title';
          final overview = details['overview'] as String? ?? 'No description available.';

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Backdrop
              if (backdropUrl != null)
                CachedNetworkImage(
                  imageUrl: backdropUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black),
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                )
              else
                Container(color: Colors.black),

              // Faded Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.9),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.5, 0.8],
                  ),
                ),
              ),

              // Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 5, color: Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Overview
                      Text(
                        overview,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Where to Watch",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Watch Options List
                      optionsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, st) => Center(
                          child: Text(
                            "Error: ${err.toString()}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (options) {
                          if (options.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'No watch providers found for this content',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: options.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final option = options[index];
                              final bool isLocal = option.regionId == currentRegion;
                              final hasVpnConfig = vpnConfigs.any(
                                (config) => config.regionId == option.regionId,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: _WatchOptionTile(
                                  option: option,
                                  isLocal: isLocal,
                                  hasVpnConfig: hasVpnConfig,
                                  showName: name,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom Widget for the Watch Option Tile with glass effect
class _WatchOptionTile extends ConsumerWidget {
  final WatchProvider option;
  final bool isLocal;
  final bool hasVpnConfig;
  final String showName;

  const _WatchOptionTile({
    required this.option,
    required this.isLocal,
    required this.hasVpnConfig,
    required this.showName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: ListTile(
            // Focusable for D-pad - auto-focus the first local option
            autofocus: isLocal && hasVpnConfig,
            leading: option.logoUrl.isNotEmpty && !option.logoUrl.contains('placeholder')
                ? CachedNetworkImage(
                    imageUrl: option.logoUrl,
                    width: 50,
                    height: 50,
                    placeholder: (context, url) => const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.hide_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  )
                : const Icon(Icons.hide_image, color: Colors.white, size: 50),
            title: Text(
              option.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${option.regionId}  •  ${option.typeDisplay}",
              style: TextStyle(
                color: isLocal && hasVpnConfig
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
            ),
            trailing: isLocal && hasVpnConfig
                ? const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    shadows: [
                      Shadow(blurRadius: 5, color: Colors.black),
                    ],
                  )
                : hasVpnConfig
                    ? const Icon(Icons.vpn_lock, color: Colors.white38)
                    : const Icon(Icons.info_outline, color: Colors.grey),
            enabled: hasVpnConfig,
            onTap: hasVpnConfig
                ? () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 15),
                            Text(
                              isLocal
                                  ? "Loading..."
                                  : "Connecting to ${option.regionId} VPN...",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    // Connect to VPN (Orchestrator handles the "isLocal" logic)
                    final orchestrator = ref.read(vpnOrchestratorProvider);
                    final result = await orchestrator.connectToRegion(
                      ref,
                      option.regionId,
                    );

                    // Close loading dialog
                    if (context.mounted) {
                      Navigator.pop(context);
                    }

                    // Handle result
                    switch (result) {
                      case VpnConnectionResult.successVpn:
                      case VpnConnectionResult.successNoVpnNeeded:
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrowserScreen(
                                url: option.deepLink,
                                channelName: showName,
                              ),
                            ),
                          );
                        }
                        break;
                      case VpnConnectionResult.errorNoConfigFound:
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Error: No VPN configured for region: ${option.regionId}",
                              ),
                            ),
                          );
                        }
                        break;
                      case VpnConnectionResult.errorFailedToConnect:
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error: Failed to connect to VPN."),
                            ),
                          );
                        }
                        break;
                    }
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

