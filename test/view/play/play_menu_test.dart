import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/common/speed.dart';
import 'package:lichess_mobile/src/model/common/time_increment.dart';
import 'package:lichess_mobile/src/model/game/game.dart';
import 'package:lichess_mobile/src/model/game/game_status.dart';
import 'package:lichess_mobile/src/model/game/offline_computer_game.dart';
import 'package:lichess_mobile/src/model/game/over_the_board_game.dart';
import 'package:lichess_mobile/src/model/offline_computer/offline_computer_game_storage.dart';
import 'package:lichess_mobile/src/model/over_the_board/over_the_board_game_storage.dart';
import 'package:lichess_mobile/src/view/play/play_menu.dart';
import 'package:mocktail/mocktail.dart';

import '../../test_helpers.dart';
import '../../test_provider_scope.dart';

class MockOfflineComputerGameStorage extends Mock implements OfflineComputerGameStorage {}

class MockOverTheBoardGameStorage extends Mock implements OverTheBoardGameStorage {}

void main() {
  group('Play menu', () {
    testWidgets('shows resume buttons for resumable offline games', (tester) async {
      final offlineGameStorage = MockOfflineComputerGameStorage();
      final otbGameStorage = MockOverTheBoardGameStorage();
      when(() => offlineGameStorage.fetchGame()).thenAnswer((_) async => _savedOfflineGame());
      when(() => otbGameStorage.fetchOngoingGame()).thenAnswer((_) async => _savedOtbGame());

      final app = await makeTestProviderScopeApp(
        tester,
        home: const Scaffold(body: PlayMenu()),
        overrides: {
          offlineComputerGameStorageProvider: offlineComputerGameStorageProvider.overrideWith(
            (_) => offlineGameStorage,
          ),
          overTheBoardGameStorageProvider: overTheBoardGameStorageProvider.overrideWith(
            (_) => otbGameStorage,
          ),
        },
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('resumeOfflineComputerGameButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('resumeOtbGameButton')), findsOneWidget);
    });

    testWidgets('OTB row starts a new game when a resume is available', (tester) async {
      final offlineGameStorage = MockOfflineComputerGameStorage();
      final otbGameStorage = MockOverTheBoardGameStorage();
      when(() => offlineGameStorage.fetchGame()).thenAnswer((_) async => null);
      when(() => otbGameStorage.fetchOngoingGame()).thenAnswer((_) async => _savedOtbGame());

      final app = await makeTestProviderScopeApp(
        tester,
        home: const Scaffold(body: PlayMenu()),
        overrides: {
          offlineComputerGameStorageProvider: offlineComputerGameStorageProvider.overrideWith(
            (_) => offlineGameStorage,
          ),
          overTheBoardGameStorageProvider: overTheBoardGameStorageProvider.overrideWith(
            (_) => otbGameStorage,
          ),
        },
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Over the board'));
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);
      verify(() => otbGameStorage.fetchOngoingGame()).called(1);
    });

    testWidgets('OTB resume button opens the saved game', (tester) async {
      final offlineGameStorage = MockOfflineComputerGameStorage();
      final otbGameStorage = MockOverTheBoardGameStorage();
      when(() => offlineGameStorage.fetchGame()).thenAnswer((_) async => null);
      when(() => otbGameStorage.fetchOngoingGame()).thenAnswer((_) async => _savedOtbGame());

      final app = await makeTestProviderScopeApp(
        tester,
        home: const Scaffold(body: PlayMenu()),
        overrides: {
          offlineComputerGameStorageProvider: offlineComputerGameStorageProvider.overrideWith(
            (_) => offlineGameStorage,
          ),
          overTheBoardGameStorageProvider: overTheBoardGameStorageProvider.overrideWith(
            (_) => otbGameStorage,
          ),
        },
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('resumeOtbGameButton')));
      await tester.pumpAndSettle();

      expect(find.byType(Chessboard), findsOneWidget);
      expect(boardHasPiece(tester, Square.e2, Piece.whitePawn), isFalse);
      expect(boardHasPiece(tester, Square.e4, Piece.whitePawn), isTrue);
      verify(() => otbGameStorage.fetchOngoingGame()).called(2);
    });
  });
}

SavedOfflineComputerGame _savedOfflineGame() {
  return SavedOfflineComputerGame(
    game: OfflineComputerGame(
      id: const StringId('offline_test01'),
      steps: [
        const GameStep(position: Chess.initial),
        GameStep(
          position: Position.setupPosition(
            Rule.chess,
            Setup.parseFen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'),
          ),
          sanMove: SanMove('e4', Move.parse('e2e4')!),
        ),
      ].lock,
      meta: GameMeta(
        createdAt: DateTime.now(),
        rated: false,
        variant: Variant.standard,
        speed: Speed.classical,
        perf: Perf.classical,
      ),
      initialFen: null,
      status: GameStatus.started,
      playerSide: Side.white,
      stockfishLevel: StockfishLevel.level1,
    ),
  );
}

SavedOtbGame _savedOtbGame() {
  return SavedOtbGame(
    game: OverTheBoardGame(
      id: const StringId('otb_test01'),
      steps: [
        const GameStep(position: Chess.initial),
        GameStep(
          position: Position.setupPosition(
            Rule.chess,
            Setup.parseFen('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'),
          ),
          sanMove: SanMove('e4', Move.parse('e2e4')!),
        ),
      ].lock,
      meta: GameMeta(
        createdAt: DateTime.now(),
        rated: false,
        variant: Variant.standard,
        speed: Speed.rapid,
        perf: Perf.rapid,
      ),
      initialFen: null,
      status: GameStatus.started,
    ),
    whiteTimeLeft: const Duration(minutes: 2),
    blackTimeLeft: const Duration(minutes: 1),
    timeIncrement: const TimeIncrement(5, 3),
  );
}
