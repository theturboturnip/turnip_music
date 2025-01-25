import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

abstract class MusicbrainzRequest extends Equatable {
  Uri toUri({String scheme = "http", String host = "musicbrainz.org"}) {
    return _toUri(scheme, host);
  }

  Uri _toUri(String scheme, String host);
}

String luceneEscape(String text) {
  // https://lucene.apache.org/core/4_3_0/queryparser/org/apache/lucene/queryparser/classic/package-summary.html#Escaping_Special_Characters
  return text.replaceAllMapped(
    RegExp(r"""([+\-!(){}[]^"~*?:\\/])|(&&)|(\|\|)"""),
    (match) => "\\${match.group(0)}",
  );
}

// See https://musicbrainz.org/doc/MusicBrainz_API/Search#Release
final class MusicbrainzReleaseSearch extends MusicbrainzRequest {
  final List<String> nameParts;
  final int? atLeastNTracks;
  final int offset;

  MusicbrainzReleaseSearch({
    required this.nameParts,
    required this.atLeastNTracks,
    this.offset = 0,
  });

  @override
  Uri _toUri(String scheme, String host) {
    final formattedReleaseQuery = nameParts.map((namePart) => 'release:"${luceneEscape(namePart)}"').join(" AND ");
    final nTracksQuery = (atLeastNTracks != null) ? "tracks:[$atLeastNTracks:1000]" : null;

    final toplevelQueryGroups = [formattedReleaseQuery, nTracksQuery].whereType<String>();

    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: ["ws", "2", "release"],
      queryParameters: {
        "fmt": "json",
        if (offset > 0) "offset": offset.toString(),
        "query": toplevelQueryGroups.map((part) => "($part)").join(" AND "),
      },
    );
  }

  @override
  List<Object?> get props => [nameParts, atLeastNTracks, offset];
}

@JsonSerializable()
class MusicbrainzReleaseSearchResultMedia {
  final String format;
  @JsonKey(name: "disc-count")
  // Unsure exactly what this means - can be zero or one, or maybe more?
  final int discCount;
  @JsonKey(name: "track-count")
  final int trackCount;

  MusicbrainzReleaseSearchResultMedia({
    required this.format,
    required this.discCount,
    required this.trackCount,
  });

  factory MusicbrainzReleaseSearchResultMedia.fromJson(Map<String, dynamic> json) => _$MusicbrainzReleaseSearchResultMediaFromJson(json);

  Map<String, dynamic> toJson() => _$MusicbrainzReleaseSearchResultMediaToJson(this);
}

@JsonSerializable()
class MusizbrainzReleaseSearchResult {
  // Musicbrainz ID for the release
  final String id;
  // Search score for the release i.e. similarity to query
  final int score;
  // Title of the release
  final String title;
  // Total number of tracks in the release across all medias
  @JsonKey(name: "track-count")
  final int trackCount;
  // Number of medias making up this release
  @JsonKey(name: "count")
  final int mediaCount;
  // The medias making up this release
  final List<MusicbrainzReleaseSearchResultMedia> media;

  MusizbrainzReleaseSearchResult({
    required this.id,
    required this.score,
    required this.title,
    required this.trackCount,
    required this.mediaCount,
    required this.media,
  });

  factory MusizbrainzReleaseSearchResult.fromJson(Map<String, dynamic> json) => _$MusizbrainzReleaseSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MusizbrainzReleaseSearchResultToJson(this);
}

@JsonSerializable()
class MusizbrainzReleaseSearchResults {
  // Date/Time when the search result was collected
  final String created;
  // Number of search results returned
  final int count;
  // Offset in the index for this particular search.
  // Matches the offset requested in MusicbrainzReleaseSearch::offset.
  // e.g. if the first page had count=25, and you want to get more results, request offset=25 (TODO or 26?)
  final int offset;
  // The releases
  final List<MusizbrainzReleaseSearchResult> releases;

  MusizbrainzReleaseSearchResults({
    required this.created,
    required this.count,
    required this.offset,
    required this.releases,
  });

  factory MusizbrainzReleaseSearchResults.fromJson(Map<String, dynamic> json) => _$MusizbrainzReleaseSearchResultsFromJson(json);

  Map<String, dynamic> toJson() => _$MusizbrainzReleaseSearchResultsToJson(this);
}

// See https://musicbrainz.org/doc/MusicBrainz_API#Lookups
class MusicbrainzReleaseLookup extends MusicbrainzRequest {
  final String id;

  MusicbrainzReleaseLookup({required this.id});

  @override
  Uri _toUri(String scheme, String host) {
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: ["ws", "2", "release", id],
      queryParameters: {
        "inc": "artists recordings media",
        "fmt": "json",
      },
    );
  }

  @override
  List<Object?> get props => [id];
}

@JsonSerializable()
class MusicbrainzReleaseLookupRecording {
  final String id;
  final String title;
  final String disambiguation;
  final int length;

  MusicbrainzReleaseLookupRecording({
    required this.id,
    required this.title,
    required this.disambiguation,
    required this.length,
  });

  factory MusicbrainzReleaseLookupRecording.fromJson(Map<String, dynamic> json) => _$MusicbrainzReleaseLookupRecordingFromJson(json);

  Map<String, dynamic> toJson() => _$MusicbrainzReleaseLookupRecordingToJson(this);
}

@JsonSerializable()
class MusicbrainzReleaseLookupTrack {
  final int position;
  final String title;
  final String id;
  final int? length;
  final String number;
  final MusicbrainzReleaseLookupRecording recording;

  MusicbrainzReleaseLookupTrack({
    required this.position,
    required this.title,
    required this.id,
    required this.length,
    required this.number,
    required this.recording,
  });

  factory MusicbrainzReleaseLookupTrack.fromJson(Map<String, dynamic> json) => _$MusicbrainzReleaseLookupTrackFromJson(json);

  Map<String, dynamic> toJson() => _$MusicbrainzReleaseLookupTrackToJson(this);
}

@JsonSerializable()
class MusicbrainzReleaseLookupMedia {
  final String title;
  final int position;
  final String format;
  @JsonKey(name: "track-count")
  final int trackCount;
  final List<MusicbrainzReleaseLookupTrack> tracks;

  MusicbrainzReleaseLookupMedia({
    required this.title,
    required this.position,
    required this.format,
    required this.trackCount,
    required this.tracks,
  });

  factory MusicbrainzReleaseLookupMedia.fromJson(Map<String, dynamic> json) => _$MusicbrainzReleaseLookupMediaFromJson(json);

  Map<String, dynamic> toJson() => _$MusicbrainzReleaseLookupMediaToJson(this);
}

@JsonSerializable()
class MusicbrainzReleaseLookupResult {
  // asin, status, status-id, disambiguation, packaging-id, quality, barcode, packaging, cover-art-archive, text-representation, artist-credit ignored
  final String id;
  final String status;
  final String title;
  final List<MusicbrainzReleaseLookupMedia> media;

  MusicbrainzReleaseLookupResult({
    required this.id,
    required this.status,
    required this.title,
    required this.media,
  });

  factory MusicbrainzReleaseLookupResult.fromJson(Map<String, dynamic> json) => _$MusicbrainzReleaseLookupResultFromJson(json);

  Map<String, dynamic> toJson() => _$MusicbrainzReleaseLookupResultToJson(this);
}
