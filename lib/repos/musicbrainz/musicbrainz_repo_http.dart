import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:turnip_music/repos/musicbrainz/data.dart';
import 'package:turnip_music/repos/musicbrainz/musicbrainz_repo.dart';
import 'package:http/http.dart' as http;

class MusicbrainzHttpRepo extends MusicbrainzRepo {
  MusicbrainzHttpRepo({http.Client? client})
      : client = client ?? http.Client(),
        inMemoryLookupCache = LinkedHashMap(),
        inMemorySearchCache = LinkedHashMap(),
        timeSinceLastRequest = clock.stopwatch();

  final http.Client client;
  // Use LinkedHashMap so keys are returned in insertion order
  final LinkedHashMap<MusicbrainzReleaseLookup, MusicbrainzReleaseLookupResult> inMemoryLookupCache;
  final LinkedHashMap<MusicbrainzReleaseSearch, MusizbrainzReleaseSearchResults> inMemorySearchCache;

  // Musicbrainz API requires strict rate limiting.
  // See https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting
  // They require rate be capped at 1s between requests.
  // We aim for 1.5s for safety
  Stopwatch timeSinceLastRequest;
  int nextRequestTicketToService = 0;
  int nextRequestTicket = 0;
  final int msBetweenRequests = 1500;
  final int msMinSleep = 500;

  // Make the HTTP request, waiting in order for all preceding requests to be made
  // with at least 1.5s between each one.
  Future<String> _makeRequest(MusicbrainzRequest request) async {
    // Get the current value of nextRequestTicket and increment it at the "same time".
    // Dart doesn't have or need atomics, we assume this is only ever used in one thread,
    // but this looks atomic enough.
    final ticket = nextRequestTicket++;

    // Wait for all tickets before us to be consumed AND timeSinceLastRequest > msBetweenRequests.
    while (true) {
      final msSinceLastRequest = timeSinceLastRequest.elapsedMilliseconds;
      // If there are tickets before us not consumed
      if (nextRequestTicketToService < ticket) {
        final toSleepFor = max((ticket - nextRequestTicketToService) * 1000, msMinSleep);
        // print("ticket $ticket greater than $nextRequestTicketToService, waiting $toSleepFor");
        await Future.delayed(Duration(milliseconds: toSleepFor));
      } else if (timeSinceLastRequest.isRunning && msSinceLastRequest < msBetweenRequests) {
        // Wait for an extra millisecond - we don't want to end up hitting an edge case, so
        // go a little beyond the time we need to.
        await Future.delayed(Duration(milliseconds: msBetweenRequests - msSinceLastRequest + 1));
      } else {
        break;
      }
    }

    assert(ticket == nextRequestTicketToService);

    // TODO put an email in the useragent
    // as requested by Musicbrainz
    final response = await client.get(request.toUri(), headers: {
      "User-Agent": "turnip_music/dev (theturboturnip.com)",
    });

    // Set up the timer and ticket for the next request
    timeSinceLastRequest.reset();
    timeSinceLastRequest.start();
    // print("completed $ticket");
    nextRequestTicketToService++;

    if (response.statusCode != 200) {
      return Future.error("MusicBrainz denied the request (${response.statusCode})");
    }
    return response.body;
  }

  void _capCacheAtNEntries(LinkedHashMap<dynamic, dynamic> cache, {int maxLength = 5}) {
    if (cache.length > maxLength) {
      cache.keys.take(cache.length - maxLength).toList().forEach((key) => cache.remove(key));
    }
  }

  @override
  Future<MusicbrainzReleaseLookupResult> lookupRelease(MusicbrainzReleaseLookup lookup) async {
    late final result;
    final cached = inMemoryLookupCache[lookup];
    if (cached == null) {
      final response = await _makeRequest(lookup);
      try {
        result = MusicbrainzReleaseLookupResult.fromJson(json.decode(response));
      } catch (err) {
        print("Error decoding $response");
        rethrow;
      }
      inMemoryLookupCache[lookup] = result;
      _capCacheAtNEntries(inMemoryLookupCache);
    } else {
      result = cached;
    }

    return result;
  }

  @override
  Future<MusizbrainzReleaseSearchResults> searchReleases(MusicbrainzReleaseSearch search) async {
    late final result;
    final cached = inMemorySearchCache[search];
    if (cached == null) {
      final response = await _makeRequest(search);
      try {
        result = MusizbrainzReleaseSearchResults.fromJson(json.decode(response));
      } catch (err) {
        print("Error decoding $response");
        rethrow;
      }
      inMemorySearchCache[search] = result;
      _capCacheAtNEntries(inMemorySearchCache);
    } else {
      result = cached;
    }

    return result;
  }
}
