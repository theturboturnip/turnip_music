// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MusicbrainzReleaseSearchResultMedia
    _$MusicbrainzReleaseSearchResultMediaFromJson(Map<String, dynamic> json) =>
        MusicbrainzReleaseSearchResultMedia(
          format: json['format'] as String,
          discCount: (json['disc-count'] as num).toInt(),
          trackCount: (json['track-count'] as num).toInt(),
        );

Map<String, dynamic> _$MusicbrainzReleaseSearchResultMediaToJson(
        MusicbrainzReleaseSearchResultMedia instance) =>
    <String, dynamic>{
      'format': instance.format,
      'disc-count': instance.discCount,
      'track-count': instance.trackCount,
    };

MusizbrainzReleaseSearchResult _$MusizbrainzReleaseSearchResultFromJson(
        Map<String, dynamic> json) =>
    MusizbrainzReleaseSearchResult(
      id: json['id'] as String,
      score: (json['score'] as num).toInt(),
      title: json['title'] as String,
      trackCount: (json['track-count'] as num).toInt(),
      mediaCount: (json['count'] as num).toInt(),
      media: (json['media'] as List<dynamic>)
          .map((e) => MusicbrainzReleaseSearchResultMedia.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MusizbrainzReleaseSearchResultToJson(
        MusizbrainzReleaseSearchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'score': instance.score,
      'title': instance.title,
      'track-count': instance.trackCount,
      'count': instance.mediaCount,
      'media': instance.media,
    };

MusizbrainzReleaseSearchResults _$MusizbrainzReleaseSearchResultsFromJson(
        Map<String, dynamic> json) =>
    MusizbrainzReleaseSearchResults(
      created: json['created'] as String,
      count: (json['count'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      releases: (json['releases'] as List<dynamic>)
          .map((e) => MusizbrainzReleaseSearchResult.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MusizbrainzReleaseSearchResultsToJson(
        MusizbrainzReleaseSearchResults instance) =>
    <String, dynamic>{
      'created': instance.created,
      'count': instance.count,
      'offset': instance.offset,
      'releases': instance.releases,
    };

MusicbrainzReleaseLookupRecording _$MusicbrainzReleaseLookupRecordingFromJson(
        Map<String, dynamic> json) =>
    MusicbrainzReleaseLookupRecording(
      id: json['id'] as String,
      title: json['title'] as String,
      disambiguation: json['disambiguation'] as String,
      length: (json['length'] as num).toInt(),
    );

Map<String, dynamic> _$MusicbrainzReleaseLookupRecordingToJson(
        MusicbrainzReleaseLookupRecording instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'disambiguation': instance.disambiguation,
      'length': instance.length,
    };

MusicbrainzReleaseLookupTrack _$MusicbrainzReleaseLookupTrackFromJson(
        Map<String, dynamic> json) =>
    MusicbrainzReleaseLookupTrack(
      position: (json['position'] as num).toInt(),
      title: json['title'] as String,
      id: json['id'] as String,
      length: (json['length'] as num?)?.toInt(),
      number: json['number'] as String,
      recording: MusicbrainzReleaseLookupRecording.fromJson(
          json['recording'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MusicbrainzReleaseLookupTrackToJson(
        MusicbrainzReleaseLookupTrack instance) =>
    <String, dynamic>{
      'position': instance.position,
      'title': instance.title,
      'id': instance.id,
      'length': instance.length,
      'number': instance.number,
      'recording': instance.recording,
    };

MusicbrainzReleaseLookupMedia _$MusicbrainzReleaseLookupMediaFromJson(
        Map<String, dynamic> json) =>
    MusicbrainzReleaseLookupMedia(
      title: json['title'] as String,
      position: (json['position'] as num).toInt(),
      format: json['format'] as String,
      trackCount: (json['track-count'] as num).toInt(),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) =>
              MusicbrainzReleaseLookupTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MusicbrainzReleaseLookupMediaToJson(
        MusicbrainzReleaseLookupMedia instance) =>
    <String, dynamic>{
      'title': instance.title,
      'position': instance.position,
      'format': instance.format,
      'track-count': instance.trackCount,
      'tracks': instance.tracks,
    };

MusicbrainzReleaseLookupResult _$MusicbrainzReleaseLookupResultFromJson(
        Map<String, dynamic> json) =>
    MusicbrainzReleaseLookupResult(
      id: json['id'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      media: (json['media'] as List<dynamic>)
          .map((e) =>
              MusicbrainzReleaseLookupMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MusicbrainzReleaseLookupResultToJson(
        MusicbrainzReleaseLookupResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'title': instance.title,
      'media': instance.media,
    };
