import 'package:turnip_music/repos/musicbrainz/data.dart';

abstract class MusicbrainzRepo {
  Future<MusizbrainzReleaseSearchResults> searchReleases(MusicbrainzReleaseSearch search);
  Future<MusicbrainzReleaseLookupResult> lookupRelease(MusicbrainzReleaseLookup lookup);
}
