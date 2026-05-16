import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/practice/practice.dart';
import 'package:lichess_mobile/src/model/practice/practice_repository.dart';
import 'package:lichess_mobile/src/network/http.dart';

import '../../test_container.dart';
import '../../test_helpers.dart';

void main() {
  Future<ProviderContainer> makeTestContainer(MockClient mockClient) {
    return makeContainer(
      overrides: {
        lichessClientProvider: lichessClientProvider.overrideWith((ref) {
          return LichessClient(mockClient, ref);
        }),
      },
    );
  }

  group('PracticeRepository', () {
    test('parses practice index and finds The Pin', () async {
      final mockClient = MockClient((request) {
        expect(request.url.path, '/practice');
        expect(request.headers['Accept'], 'application/json');
        return mockResponse(kPracticeIndexResponse, 200);
      });

      final container = await makeTestContainer(mockClient);
      final repo = container.read(practiceRepositoryProvider);

      final index = await repo.getPracticeIndex();

      expect(index.thePinStudy?.id, kThePinPracticeStudyId);
      expect(index.thePinStudy?.name, 'The Pin');
      expect(index.progress[const StudyChapterId('abc12345')], 3);
    });

    test('posts completion to the practice endpoint', () async {
      final requestedPaths = <String>[];
      final mockClient = MockClient((request) {
        requestedPaths.add(request.url.path);
        return mockResponse('', 204);
      });

      final container = await makeTestContainer(mockClient);
      final repo = container.read(practiceRepositoryProvider);

      await repo.completeChapter(chapterId: const StudyChapterId('abc12345'), nbMoves: 4);

      expect(requestedPaths, ['/practice/complete/abc12345/4']);
    });
  });
}

const kPracticeIndexResponse = '''
{
  "sections": [
    {
      "id": "fundamental-tactics",
      "name": "Fundamental Tactics",
      "studies": [
        {
          "id": "9ogFv8Ac",
          "slug": "the-pin",
          "name": "The Pin"
        }
      ]
    }
  ],
  "progress": {
    "abc12345": 3
  }
}
''';
