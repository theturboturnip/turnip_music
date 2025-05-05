import 'package:turnip_music/library/data/art.dart';
import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';

extension type SongId(int raw) {
  const SongId.c(this.raw);
  static const SongId unspecified = SongId.c(-1);
}

/// A Song is a musical recording which may be present in multiple backends and be attached to multiple Albums.
/// e.g. the same recording of "Down Bad" by Taylor Swift is present both in "THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY"
/// and "THE TORTURED POETS DEPARTMENT" albums on Spotify, and both are available on Apple Music.
/// In this data model, all instances of that recording on Spotify and Apple Music all map to one Song.
/// Notionally equivalent to a Musicbrainz Recording.
class Song {
  final String name;
  final int lengthSeconds;
  final ArtId? art;

  Song({
    required this.name,
    required this.lengthSeconds,
    required this.art,
  });
}

/// A link between a Song and an Album.
class SongToAlbum {
  final SongId songId;
  final AlbumId albumId;
  final int? disc;
  final int? track;

  SongToAlbum({
    required this.songId,
    required this.albumId,
    required this.disc,
    required this.track,
  });
}

/// A link between a Song and an Artist.
/// TODO (songId, order) should be unique - it doesn't make sense for two artists to appear in exactly the same place in a song's listing.
/// The actual connections of Songs to Artists is arbitary and not necessarily connected to the Song or Artist's Musicbrainz.
class SongToArtist {
  final SongId songId;
  final ArtistId artistId;
  // The ordering of this artist in the list of artists for the song.
  // e.g. "Boop" by "Jeff Williams" and "Casey Lee Williams" has
  // { boopId, jeffId, order = 1 }, { boopId, caseyId, order = 2}.
  final int order;

  SongToArtist({
    required this.songId,
    required this.artistId,
    required this.order,
  });
}

extension type BackendSongId(int id) {}

/// Information about a song on a given backend.
/// May or may not be playable, i.e. the MusicBrainz service does not provide a means of playback
/// but it does provide metadata.
/// Separates stable information from unstable information (e.g. device-specific, such as filepaths).
///
/// Stable information is intended to be used to reconstruct connections between logical songs and
/// backend songs if they are swept out from under us.
/// For example, Android Media Store IDs can be flaky. If the media store swaps out the media IDs we can notice
/// by comparing the metadata Android returns for a given ID with the data we have,
/// and then find the new ID of the song by searching the Android Media Store for that metadata.
class BackendSong {
  final SongId logicalSongId;

  // The ID of the backend itself. e.g. "spotify", "androidfilestore"
  final String backend;

  // TODO is this necessary? it was originally intended to allow you to specifically
  // look for metadata matches from "local files" as opposed to "android local files"
  // but we probably don't need to limit metadata matches like that?
  // // The source of the metadata.
  // // Usually a website if applicable e.g.
  // // "spotify.com"
  // // "musicbrainz.org"
  // // "freedb.org"
  // // or
  // // "mp3" if retrieved from a local MP3 file.
  // final String stableMetadataOrigin;

  // A stable ID which *should not contain device-specific info*.
  // For example, a Spotify or MusicBrainz ID is reasonable to use here
  // because those are not device-specific and are unlikely to change over time.
  // Certainly, those services are incredibly unlikely to reuse IDs for other songs.
  // Do not use e.g. Android Media Store IDs or local file paths here, because
  // they will not apply on other user devices.
  // In those cases, set it to null.
  final String? stableId;

  // A potentially unstable ID, which may be used for playback.
  // May be identical to the stableId.
  // If the plugin so chooses it can try to use this unstable ID to play the song
  final String unstableId;
  // Priority within the backend.
  // If the backend has multiple BackendSongs for a given logical Song,
  // it selects one with the highest priority.
  final int playbackPriority;

  // The name of the song
  final String name;
  // The first artist associated with the song, if present
  final String? firstArtist;
  // The first album associated with the song, if present
  final String? firstAlbum;
  // JSON-encoded object with extra metadata that may be parsable based on the 'origin' value.
  final String? extra;
  // A Uri pointing to the song's cover art
  final String? coverArt;

  BackendSong({
    required this.logicalSongId,
    required this.backend,
    required this.stableId,
    required this.unstableId,
    required this.playbackPriority,
    required this.name,
    required this.firstArtist,
    required this.firstAlbum,
    required this.extra,
    required this.coverArt,
  });
}

// TODO it could be beneficial to split the BackendSong stable/unstable data into separate tables
// so we can continually sync stable data between different devices and throw away the unstable tables.
// That also goes for multiple devices using the same plugins e.g. multiple android plugins with mismatching media numbers.
// That can be done in v2. For now it's simpler to assume single BackendSong per backend song.
