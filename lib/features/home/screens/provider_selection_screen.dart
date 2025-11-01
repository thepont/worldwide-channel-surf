import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:worldwide_channel_surf/models/show_details.dart';
import 'package:worldwide_channel_surf/models/typedefs.dart';
import 'package:worldwide_channel_surf/features/browser/screens/browser_screen.dart';
import 'package:worldwide_channel_surf/core/vpn_orchestrator_service.dart';
import 'package:worldwide_channel_surf/providers/vpn_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen to display all available watch providers and regions for a show
/// Allows user to select which provider/region to use before opening browser
class ProviderSelectionScreen extends ConsumerStatefulWidget {
  final ShowSummary show;
  final List<WatchProvider> providers;

  const ProviderSelectionScreen({
    super.key,
    required this.show,
    required this.providers,
  });

  @override
  ConsumerState<ProviderSelectionScreen> createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends ConsumerState<ProviderSelectionScreen> {
  bool _isConnecting = false;
  String? _error;

  /// Filter and group providers by service name and type (free vs subscription)
  /// Returns a map: ProviderType -> (service name -> regions map)
  Map<ProviderType, Map<String, Map<RegionId, WatchProvider>>> _groupProvidersByTypeAndService() {
    final Map<ProviderType, Map<String, Map<RegionId, WatchProvider>>> grouped = {};
    
    for (final provider in widget.providers) {
      // Filter out buy and rent providers
      if (provider.providerType == ProviderType.rent) {
        continue; // Skip rent providers
      }
      
      // Initialize type group if needed
      if (!grouped.containsKey(provider.providerType)) {
        grouped[provider.providerType] = {};
      }
      
      final typeGroup = grouped[provider.providerType]!;
      
      // Initialize service if needed
      if (!typeGroup.containsKey(provider.name)) {
        typeGroup[provider.name] = {};
      }
      
      // Use region as key - if same service has multiple providers in same region,
      // keep the first one (shouldn't happen but just in case)
      if (!typeGroup[provider.name]!.containsKey(provider.regionId)) {
        typeGroup[provider.name]![provider.regionId] = provider;
      }
    }
    
    return grouped;
  }

  Future<void> _onProviderSelected(WatchProvider provider) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    // Check if VPN config exists for this region
    final vpnConfigs = ref.read(vpnConfigListProvider);
    final hasVpnConfig = vpnConfigs.any((config) => config.regionId == provider.regionId);

    if (!hasVpnConfig) {
      setState(() {
        _error = 'No VPN configured for region ${provider.regionId}. Please configure a VPN for this region first.';
        _isConnecting = false;
      });
      return;
    }

    try {
      // Connect to VPN if needed
      final orchestrator = ref.read(vpnOrchestratorProvider);
      final result = await orchestrator.connectToRegion(
        ref,
        provider.regionId,
      );

      // Handle VPN connection result
      switch (result) {
        case VpnConnectionResult.successVpn:
        case VpnConnectionResult.successNoVpnNeeded:
          // Navigate to browser screen with VPN connected to the provider's region
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BrowserScreen(
                  url: provider.deepLink,
                  channelName: widget.show.name,
                ),
              ),
            );
          }
          break;

        case VpnConnectionResult.errorNoConfigFound:
          setState(() {
            _error = 'No VPN configured for region ${provider.regionId}';
            _isConnecting = false;
          });
          break;

        case VpnConnectionResult.errorFailedToConnect:
          setState(() {
            _error = 'Failed to connect to VPN for region ${provider.regionId}';
            _isConnecting = false;
          });
          break;
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedProviders = _groupProvidersByTypeAndService();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.show.name),
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to VPN...'),
                ],
              ),
            )
          : _buildContent(groupedProviders),
    );
  }

  Widget _buildContent(Map<ProviderType, Map<String, Map<RegionId, WatchProvider>>> groupedProviders) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    // Get VPN configs once
    final vpnConfigs = ref.read(vpnConfigListProvider);
    
    // Build list of sections: Free first, then Subscription
    final List<Widget> sections = [];
    
    // Free section
    final freeProviders = groupedProviders[ProviderType.free];
    if (freeProviders != null && freeProviders.isNotEmpty) {
      sections.add(
        _buildProviderSection(
          title: 'Free',
          icon: Icons.monetization_on,
          iconColor: Colors.green,
          providers: freeProviders,
          vpnConfigs: vpnConfigs,
        ),
      );
    }
    
    // Subscription section
    final subscriptionProviders = groupedProviders[ProviderType.subscription];
    if (subscriptionProviders != null && subscriptionProviders.isNotEmpty) {
      sections.add(
        _buildProviderSection(
          title: 'Subscription',
          icon: Icons.subscriptions,
          iconColor: Colors.blue,
          providers: subscriptionProviders,
          vpnConfigs: vpnConfigs,
        ),
      );
    }
    
    if (sections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No watch providers found for this content',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: sections,
    );
  }

  Widget _buildProviderSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Map<String, Map<RegionId, WatchProvider>> providers,
    required List vpnConfigs,
  }) {
    final services = providers.keys.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
        // Services in this section
        ...services.map((serviceName) {
          final regionsMap = providers[serviceName]!;
          final regions = regionsMap.keys.toList()..sort();
          final firstProvider = regionsMap.values.first;

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: firstProvider.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: firstProvider.logoUrl!,
                      width: 50,
                      height: 50,
                      placeholder: (context, url) => const SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.movie, size: 50),
                    )
                  : const Icon(Icons.movie, size: 50),
              title: Text(
                serviceName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: regions.map((region) {
                    final hasVpnConfig = vpnConfigs.any((config) => config.regionId == region);
                    final provider = regionsMap[region]!;
                    
                    return InkWell(
                      onTap: hasVpnConfig ? () => _onProviderSelected(provider) : null,
                      child: Chip(
                        label: Text(region),
                        backgroundColor: hasVpnConfig 
                            ? Colors.blue[100] 
                            : Colors.grey[300],
                        labelStyle: TextStyle(
                          color: hasVpnConfig ? Colors.blue[900] : Colors.grey[600],
                          fontWeight: hasVpnConfig ? FontWeight.w600 : FontWeight.normal,
                        ),
                        avatar: Icon(
                          hasVpnConfig ? Icons.check_circle : Icons.info_outline,
                          size: 16,
                          color: hasVpnConfig ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}

