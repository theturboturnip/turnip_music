import 'package:turnip_music/library/data/art.dart';

extension type ArtistId(int raw) {
  const ArtistId.c(this.raw);
  static const ArtistId unspecified = ArtistId.c(-1);
}

class Artist {
  final String name;
  final ArtId? art;

  Artist({
    required this.name,
    required this.art,
  });
}

extension type ArtistBackingId(int id) {}

/// Information about a given Artist's presence on a specific Backend.
/// An artist may be present on any backend multiple times, but it's usually unlikely.
class BackendArtist {
  final ArtistId logicalArtistId;
  // // The source of the metadata.
  // // Usually a website if applicable e.g.
  // // "spotify.com"
  // // "musicbrainz.org"
  // // "freedb.org"
  // // or
  // // "mp3" if retrieved from a set of local MP3 files.
  // final String origin;
  // The ID of the backend itself. e.g. "spotify", "androidfilestore"
  final String backend;
  // A stable ID which *should not contain device-specific info*.
  // For example, a Spotify or MusicBrainz ID is reasonable to use here
  // because those are not device-specific and are unlikely to change over time.
  // Certainly, those services are incredibly unlikely to reuse IDs for other songs.
  // Do not use e.g. Android Media Store IDs or local file paths here, because
  // they will not apply on other user devices.
  // In those cases, set it to null.
  final String? stableId;
  // A potentially unstable ID.
  // May be identical to the stableId.
  final String unstableId;
  // The name of the artist
  final String name;
  // JSON-encoded object with extra metadata that may be parsable based on the 'origin' value.
  final String? extra;
  // A Uri pointing to the album's cover art
  final String? coverArt;

  BackendArtist({
    required this.logicalArtistId,
    required this.backend,
    required this.stableId,
    required this.unstableId,
    required this.name,
    required this.extra,
    required this.coverArt,
  });
}
