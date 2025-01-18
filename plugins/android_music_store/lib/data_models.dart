import 'package:json_annotation/json_annotation.dart';

part 'data_models.g.dart';

@JsonSerializable()
class AlbumSummary {
  final int id;
  final String title;
  final int numberOfSongs;
  final String mainArtist;
  final int mainArtistId;

  AlbumSummary({
    required this.id,
    required this.title,
    required this.numberOfSongs,
    required this.mainArtist,
    required this.mainArtistId,
  });

  factory AlbumSummary.fromJson(Map<String, dynamic> json) => _$AlbumSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumSummaryToJson(this);
}

@JsonSerializable()
class Song {
  final int id;
  final String title;
  final int discNumber;
  final int trackNumber;
  final int durationMs;
  final String mainArtist;
  final int mainArtistId;

  Song({
    required this.id,
    required this.title,
    required this.discNumber,
    required this.trackNumber,
    required this.durationMs,
    required this.mainArtist,
    required this.mainArtistId,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
