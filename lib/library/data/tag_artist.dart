import 'package:uuid/uuid.dart';

extension type ArtistId(int id) {}

class Artist {
  final Uuid? musicBrainzId;
  final String name;

  Artist({
    required this.musicBrainzId,
    required this.name,
  });
}

extension type ArtistBackingId(int id) {}

/// Information about a given Artist's presence on a specific Backend.
/// An artist may be present on any backend multiple times, but it's usually unlikely.
class ArtistBacking {
  final ArtistId artistId;
  final String backendId;
  // A theoretically unique ID within this backend
  final String idInBackend;
  // A fallback identifier within the backend which can be used if the main id falls out from under you.
  // Unlikely to be useful in e.g. Spotify's case, but local files can be flaky.
  final String fallbackIdInBackend;
  // TODO?
  final Uri coverArtInBackend;

  ArtistBacking({
    required this.artistId,
    required this.backendId,
    required this.idInBackend,
    required this.fallbackIdInBackend,
    required this.coverArtInBackend,
  });
}
