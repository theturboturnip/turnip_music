extension type AlbumId(int id) {}

/// A group of Songs released in one unit (potentially of multiple mediums e.g. a multi-disc CD set).
/// Notionally equivalent to a MusicBrainz Release.
class Album {
  final String? musicBrainzId;
  final String name;
  // TODO releaseType

  Album({
    required this.musicBrainzId,
    required this.name,
  });
}

extension type AlbumBackingId(int id) {}

/// Information about a given Album's presence on a specific Backend.
/// An album may be present on any backend multiple times, but it's usually unlikely.
class AlbumBacking {
  final AlbumId albumId;
  final String backendId;
  // A theoretically unique ID within the backend
  final String idInBackend;
  // A set of fallback metadata within the backend which can be used if the main id falls out from under you.
  // Unlikely to be useful in e.g. Spotify's case, but local files can be flaky.
  final List<String> fallbackMetadataInBackend;
  // A Uri pointing to the album's cover art dictated by this backend.
  final String? coverArtInBackend;

  AlbumBacking({
    required this.albumId,
    required this.backendId,
    required this.idInBackend,
    required this.fallbackMetadataInBackend,
    required this.coverArtInBackend,
  });
}
