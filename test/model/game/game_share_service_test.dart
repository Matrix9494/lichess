import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/game/game_share_service.dart';

import '../../test_container.dart';

const _gameResponse = '''
{"id":"qVChCOTc","rated":false,"source":"lobby","variant":"standard","speed":"blitz","perf":"blitz","createdAt":1673443822389,"lastMoveAt":1673444036416,"status":"mate","players":{"white":{"aiLevel":1},"black":{"user":{"name":"veloce","patron":true,"id":"veloce"},"rating":1435,"provisional":true}},"winner":"black","opening":{"eco":"C20","name":"King's Pawn Game: Wayward Queen Attack, Kiddie Countergambit","ply":4},"moves":"e4 e5 Qh5 Nf6 Qxe5+ Be7 b3 d6 Qb5+ Bd7 Qxb7 Nc6 Ba3 Rb8 Qa6 Nxe4 Bb2 O-O Nc3 Nb4 Nf3 Nxa6 Nd5 Nb4 Nxe7+ Qxe7 Nd4 Qf6 f4 Qe7 Ke2 Ng3+ Kd1 Nxh1 Bc4 Nf2+ Kc1 Qe1#","clocks":[18003,18003,17915,17627,17771,16691,17667,16243,17475,15459,17355,14779,17155,13795,16915,13267,14771,11955,14451,10995,14339,10203,13899,9099,12427,8379,12003,7547,11787,6691,11355,6091,11147,5763,10851,5099,10635,4657],"clock":{"initial":180,"increment":0,"totalTime":180},"division":{"middle":18,"end":42}}
''';

void main() {
  group('GameShareService.gameGif', () {
    test('waits long enough for generated GIF responses', () async {
      const gameId = GameId('qVChCOTc');
      final requests = <Uri>[];
      final mockClient = MockClient((request) async {
        requests.add(request.url);
        if (request.url.path == '/game/export/gif/white/${gameId.value}.gif') {
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          return http.Response.bytes(
            [71, 73, 70, 56, 57, 97],
            200,
            headers: {'content-type': 'image/gif'},
            request: request,
          );
        }
        if (request.url.path == '/game/export/${gameId.value}') {
          return http.Response(_gameResponse, 200, request: request);
        }
        return http.Response('', 404, request: request);
      });

      final container = await lichessClientContainer(mockClient);
      final service = container.read(gameShareServiceProvider);

      final (gif, game) = await service.gameGif(gameId, Side.white);

      expect(game.id, gameId);
      expect(gif.mimeType, 'image/gif');
      expect(await gif.length(), 6);

      final gifRequest = requests.singleWhere(
        (uri) => uri.path == '/game/export/gif/white/${gameId.value}.gif',
      );
      expect(gifRequest.queryParameters['players'], 'true');
      expect(gifRequest.queryParameters['ratings'], 'true');
      expect(gifRequest.queryParameters['glyphs'], 'false');
      expect(gifRequest.queryParameters['clocks'], 'false');
    });

    test('includes HTTP status in GIF response failures', () async {
      const gameId = GameId('qVChCOTc');
      final mockClient = MockClient((request) async {
        if (request.url.path == '/game/export/gif/white/${gameId.value}.gif') {
          return http.Response('', 429, request: request);
        }
        if (request.url.path == '/game/export/${gameId.value}') {
          return http.Response(_gameResponse, 200, request: request);
        }
        return http.Response('', 404, request: request);
      });

      final container = await lichessClientContainer(mockClient);
      final service = container.read(gameShareServiceProvider);

      expect(
        service.gameGif(gameId, Side.white),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('HTTP 429'))),
      );
    });
  });
}
