import 'package:worldwide_channel_surf/models/typedefs.dart';

/// Model for TV show information from TMDb API
class ShowSummary {
  final int id;
  final String name;
  final String? posterUrl;
  final String? overview;
  final double? voteAverage;
  final String mediaType; // 'tv' or 'movie'

  const ShowSummary({
    required this.id,
    required this.name,
    this.posterUrl,
    this.overview,
    this.voteAverage,
    this.mediaType = 'tv',
  });

  /// Create from TMDb API JSON response
  factory ShowSummary.fromTmdbJson(Map<String, dynamic> json) {
    return ShowSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? json['title'] as String? ?? 'Unknown',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      mediaType: json['media_type'] as String? ?? 
                 (json['name'] != null ? 'tv' : 'movie'),
    );
  }
}

/// Provider type enumeration (kept for backward compatibility)
/// Maps to WatchProviderType
enum ProviderType {
  free,        // Free streaming (ad-supported or completely free)
  subscription, // Subscription-based streaming (flatrate)
  rent,         // Rental (not used in grouping)
}

/// Watch provider type enumeration (matches TMDb API categories)
enum WatchProviderType {
  flatrate,  // Subscription streaming
  free,      // Free streaming
  ads,       // Free with ads
  rent,      // Rental
  buy,       // Purchase
}

/// Helper to convert ProviderType to WatchProviderType
extension ProviderTypeExtension on ProviderType {
  WatchProviderType toWatchProviderType() {
    switch (this) {
      case ProviderType.free:
        return WatchProviderType.free;
      case ProviderType.subscription:
        return WatchProviderType.flatrate;
      case ProviderType.rent:
        return WatchProviderType.rent;
    }
  }
}

/// Model for watch providers (streaming services) from TMDb API
class WatchProvider {
  final String name;
  final String logoUrl;
  final String deepLink; // The TMDb watch link (themoviedb.org/.../watch)
  final RegionId regionId;
  final ProviderType providerType; // For backward compatibility
  final WatchProviderType type; // New field for detailed type

  const WatchProvider({
    required this.name,
    required this.logoUrl,
    required this.deepLink,
    required this.regionId,
    required this.providerType,
    required this.type,
  });

  /// Get user-friendly display string for provider type
  String get typeDisplay {
    switch (type) {
      case WatchProviderType.flatrate:
        return "Subscription";
      case WatchProviderType.free:
        return "Free";
      case WatchProviderType.ads:
        return "Free (with Ads)";
      case WatchProviderType.rent:
        return "Rent";
      case WatchProviderType.buy:
        return "Buy";
    }
  }

  /// Create from TMDb API JSON response (legacy - uses ProviderType)
  factory WatchProvider.fromTmdbJson(
    Map<String, dynamic> json,
    RegionId regionId,
    int showId,
    String showType, // 'tv' or 'movie'
    ProviderType providerType, // Type of provider (free, subscription, rent)
  ) {
    final providerName = json['provider_name'] as String? ?? 'Unknown';
    final logoPath = json['logo_path'] as String?;
    
    // Construct TMDb watch link
    final deepLink = 'https://www.themoviedb.org/$showType/$showId/watch';

    // Convert ProviderType to WatchProviderType
    final WatchProviderType watchType = providerType.toWatchProviderType();

    return WatchProvider(
      name: providerName,
      logoUrl: logoPath != null
          ? 'https://image.tmdb.org/t/p/w200${logoPath}'
          : 'https://via.placeholder.com/200',
      deepLink: deepLink,
      regionId: regionId,
      providerType: providerType,
      type: watchType,
    );
  }

  /// Create from TMDb API JSON with WatchProviderType
  factory WatchProvider.fromTmdbJsonWithType(
    Map<String, dynamic> json,
    RegionId regionId,
    String deepLink,
    WatchProviderType watchType,
  ) {
    final providerName = json['provider_name'] as String? ?? 'Unknown';
    final logoPath = json['logo_path'] as String?;

    // Map WatchProviderType back to ProviderType for backward compatibility
    ProviderType providerType;
    switch (watchType) {
      case WatchProviderType.free:
      case WatchProviderType.ads:
        providerType = ProviderType.free;
        break;
      case WatchProviderType.flatrate:
        providerType = ProviderType.subscription;
        break;
      case WatchProviderType.rent:
        providerType = ProviderType.rent;
        break;
      case WatchProviderType.buy:
        providerType = ProviderType.rent; // Map buy to rent for compatibility
        break;
    }

    return WatchProvider(
      name: providerName,
      logoUrl: logoPath != null
          ? 'https://image.tmdb.org/t/p/w200${logoPath}'
          : 'https://via.placeholder.com/200',
      deepLink: deepLink,
      regionId: regionId,
      providerType: providerType,
      type: watchType,
    );
  }
}

