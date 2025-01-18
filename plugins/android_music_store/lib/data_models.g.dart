// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlbumSummary _$AlbumSummaryFromJson(Map<String, dynamic> json) => AlbumSummary(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      numberOfSongs: (json['numberOfSongs'] as num).toInt(),
      mainArtist: json['mainArtist'] as String,
      mainArtistId: (json['mainArtistId'] as num).toInt(),
    );

Map<String, dynamic> _$AlbumSummaryToJson(AlbumSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'numberOfSongs': instance.numberOfSongs,
      'mainArtist': instance.mainArtist,
      'mainArtistId': instance.mainArtistId,
    };

Song _$SongFromJson(Map<String, dynamic> json) => Song(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      discNumber: (json['discNumber'] as num).toInt(),
      trackNumber: (json['trackNumber'] as num).toInt(),
      durationMs: (json['durationMs'] as num).toInt(),
      mainArtist: json['mainArtist'] as String,
      mainArtistId: (json['mainArtistId'] as num).toInt(),
    );

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'discNumber': instance.discNumber,
      'trackNumber': instance.trackNumber,
      'durationMs': instance.durationMs,
      'mainArtist': instance.mainArtist,
      'mainArtistId': instance.mainArtistId,
    };
