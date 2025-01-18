import 'package:turnip_music/library/data/tag_album.dart';
import 'package:turnip_music/library/data/tag_artist.dart';

extension type SongId(int id) {}

/// A Song is a musical recording which may be present in multiple backends and be attached to multiple Albums.
/// e.g. the same recording of "Down Bad" by Taylor Swift is present both in "THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY"
/// and "THE TORTURED POETS DEPARTMENT" albums on Spotify, and both are available on Apple Music.
/// In this data model, all instances of that recording on Spotify and Apple Music all map to one Song.
/// Notionally equivalent to a Musicbrainz Recording.
class Song {
  final String? musicBrainzId;
  final String name;
  final int lengthSeconds;

  Song({
    required this.musicBrainzId,
    required this.name,
    required this.lengthSeconds,
  });
}

/// A link between a Song and an Album.
/// TODO (albumId, disc, track) should be unique - different songs shouldn't both appear in the same place on the same album.
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
  }); // May be negative, which means none/unknown?
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

extension type SongBackingId(int id) {}

/// Information about a given Song's presence on a specific Backend.
/// A Song may be present on a given Backend multiple times - it is easy to have duplicate mp3 files.
class SongBacking {
  final SongId songId;
  // The ID of the backend itself. e.g. "spotify", "androidfilestore"
  final String backendId;
  // A unique ID within this backend
  final String idInBackend;
  // A set of fallback metadata within the backend which can be used if the main id falls out from under you.
  // Unlikely to be useful in e.g. Spotify's case, but local files can be flaky.
  final List<String> fallbackMetadataInBackend;
  // Priority within the backend.
  // If the backend has multiple SongBackings for a given songId, it selects one with the highest priority.
  final int priorityInBackend;
  // A Uri pointing to the song's cover art dictated by this backend.
  final String? coverArtInBackend;

  SongBacking({
    required this.songId,
    required this.backendId,
    required this.idInBackend,
    required this.fallbackMetadataInBackend,
    required this.priorityInBackend,
    required this.coverArtInBackend,
  });
}
