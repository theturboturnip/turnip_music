import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:fake_async/fake_async.dart';
import 'package:turnip_music/repos/musicbrainz/data.dart';
import 'package:turnip_music/repos/musicbrainz/musicbrainz_repo_http.dart';

import './helpers.dart';
import 'package:test/test.dart';

void main() {
  test(
    "Test API is correctly rate limited",
    () {
      fakeAsync((async) {
        final repo = MusicbrainzHttpRepo(client: MockHttpClient());

        const int nRequests = 150;

        final requests = List.generate(
          nRequests,
          (index) => MusicbrainzReleaseSearch(
            nameParts: ["small-$index"],
            atLeastNTracks: 5,
          ),
        );

        bool complete = false;
        final stopwatch = clock.stopwatch()..start();
        List<int>? outputResponseTimes;
        Future.wait(requests.mapIndexed((index, req) async {
          await repo.searchReleases(req);
          return stopwatch.elapsedMilliseconds;
        })).then((responseTimes) {
          complete = true;
          outputResponseTimes = responseTimes;
        }, onError: (err) {
          throw err;
        });

        async.elapse(Duration(seconds: 3 * nRequests));
        expect(complete, true);

        final responseIntervals = outputResponseTimes!.mapIndexed((index, time) => (index > 0) ? (time - outputResponseTimes![index - 1]) : null).whereType<int>().toList();
        print(responseIntervals);
        expect(responseIntervals.length, nRequests - 1);
        expect(responseIntervals, everyElement(greaterThan(1000)));
      });
    },
  );
  test("Test API correctly decodes searches", () {
    fakeAsync((async) {
      final repo = MusicbrainzHttpRepo(client: MockHttpClient());

      final search = MusicbrainzReleaseSearch(nameParts: ["Final Fantasy XV"], atLeastNTracks: null);
      expect(
        search.toUri(),
        Uri.tryParse("http://musicbrainz.org/ws/2/release?fmt=json&query=%28release%3A%22Final+Fantasy+XV%22%29"),
      );

      bool complete = false;

      repo.searchReleases(search).then(
        (searchResult) {
          expect(searchResult.releases.length, searchResult.count);
          print(searchResult);
          complete = true;
        },
        onError: (err) {
          throw err;
        },
      );

      async.elapse(Duration(seconds: 10));
      expect(complete, true);
    });
  });
  test("Test API correctly decodes lookups", () {
    fakeAsync((async) {
      final repo = MusicbrainzHttpRepo(client: MockHttpClient());

      final lookup = MusicbrainzReleaseLookup(id: "e8731f68-ea05-4b9c-9dcb-f2c2946ee9fb");
      expect(
        lookup.toUri(),
        Uri.tryParse("http://musicbrainz.org/ws/2/release/e8731f68-ea05-4b9c-9dcb-f2c2946ee9fb?inc=artists+recordings+media&fmt=json"),
      );

      bool complete = false;

      repo.lookupRelease(lookup).then(
        (lookupResult) {
          print(lookupResult);
          complete = true;
        },
        onError: (err) {
          throw err;
        },
      );

      async.elapse(Duration(seconds: 10));
      expect(complete, true);
    });
  });
}
