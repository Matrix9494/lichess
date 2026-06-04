import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lichess_mobile/l10n/l10n.dart';
import 'package:lichess_mobile/src/widgets/chess960_position_picker.dart';

import '../test_provider_scope.dart';

void main() {
  testWidgets('Chess960 position picker fits on a medium phone', (tester) async {
    ({int index, String fen})? result;

    final app = await makeTestProviderScope(
      tester,
      surfaceSize: const Size(393, 852),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showChess960PositionPicker(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Chess960 start position: 518'), findsOneWidget);
    expect(find.text('Starting position'), findsOneWidget);
    expect(find.text('Load position'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    final sheetBox = tester.renderObject<RenderBox>(find.byType(BottomSheet));
    expect(sheetBox.size.height, lessThanOrEqualTo(852));

    await tester.enterText(find.byType(TextField), '959');
    await tester.pumpAndSettle();
    expect(find.text('Chess960 start position: 959'), findsOneWidget);

    await tester.tap(find.text('Load position'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.index, 959);
    expect(result!.fen, chess960PositionResult(959).fen);
  });
}
