import 'package:turnip_music/library/data/art.dart';

extension type AlbumId(int raw) {
  const AlbumId.c(this.raw);
  static const AlbumId unspecified = AlbumId.c(-1);
}

/// A group of Songs released in one unit (potentially of multiple mediums e.g. a multi-disc CD set).
/// Notionally equivalent to a MusicBrainz Release.
class Album {
  final String name;
  final ArtId? art;

  Album({
    required this.name,
    required this.art,
  });
}

extension type AlbumMetadataId(int id) {}

/// Information about a given Album's presence on a specific Backend.
/// An album may be present on any backend multiple times.
/// For example, if someone has set up a separate backend-album for each disc of a overall-album.
/// Crucially this means an association with an AlbumBacking DOES NOT MEAN THAT BACKEND'S ALBUM
/// HAS A ONE-FOR-ONE MAPPING OF BACKEND-SONG TO REAL-SONG.
class BackendAlbum {
  final AlbumId logicalAlbumId;
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
  // The name of the album
  final String name;
  // The first artist associated with the song, if present
  final String? firstArtist;
  // JSON-encoded object with extra metadata that may be parsable based on the 'origin' value.
  final String? extra;
  // A Uri pointing to the album's cover art
  final String? coverArt;
  // JSON-encoded list of (unstable song ID, song name, disc, track)
  final List<(String? unstableSongId, String songName, int disc, int track)> tracks;

  BackendAlbum({
    required this.logicalAlbumId,
    required this.backend,
    required this.stableId,
    required this.unstableId,
    required this.name,
    required this.firstArtist,
    required this.extra,
    required this.coverArt,
    required this.tracks,
  });
}
