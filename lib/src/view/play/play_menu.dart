import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/offline_computer/offline_computer_game_storage.dart';
import 'package:lichess_mobile/src/model/over_the_board/over_the_board_game_storage.dart';
import 'package:lichess_mobile/src/network/connectivity.dart';
import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/view/offline_computer/offline_computer_game_screen.dart';
import 'package:lichess_mobile/src/view/over_the_board/over_the_board_screen.dart';
import 'package:lichess_mobile/src/view/play/correspondence_challenges_screen.dart';
import 'package:lichess_mobile/src/view/play/create_challenge_bottom_sheet.dart';
import 'package:lichess_mobile/src/view/play/create_game_widget.dart';
import 'package:lichess_mobile/src/view/tournament/tournament_list_screen.dart';
import 'package:lichess_mobile/src/widgets/list.dart';

final _hasResumableOfflineComputerGameProvider = FutureProvider.autoDispose<bool>((ref) async {
  final savedGame = await ref.watch(offlineComputerGameStorageProvider).fetchGame();
  return savedGame != null && savedGame.game.steps.length > 1 && !savedGame.game.finished;
});

final _hasResumableOtbGameProvider = FutureProvider.autoDispose<bool>((ref) async {
  final savedGame = await ref.watch(overTheBoardGameStorageProvider).fetchOngoingGame();
  return savedGame != null && savedGame.game.steps.length > 1 && !savedGame.game.finished;
});

class PlayMenu extends ConsumerWidget {
  const PlayMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).value ?? false;
    final hasResumableOfflineComputerGame = ref
        .watch(_hasResumableOfflineComputerGameProvider)
        .maybeWhen(data: (hasGame) => hasGame, orElse: () => false);
    final hasResumableOtbGame = ref
        .watch(_hasResumableOtbGameProvider)
        .maybeWhen(data: (hasGame) => hasGame, orElse: () => false);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CreateGameWidget(),
        ),
        _Section(
          children: [
            ListTile(
              enabled: isOnline,
              onTap: () {
                // Pops the play bottom sheet
                Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  builder: (context) {
                    return const CreateChallengeBottomSheet(user: null);
                  },
                );
              },
              leading: const Icon(Icons.person),
              title: Text(context.l10n.challengeAFriend),
            ),
            ListTile(
              enabled: isOnline,
              onTap: () {
                // Pops the play bottom sheet
                Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(CorrespondenceChallengesScreen.buildRoute());
              },
              leading: Icon(Perf.correspondence.icon),
              title: Text(context.l10n.correspondence),
            ),
            ListTile(
              enabled: isOnline,
              onTap: () {
                // Pops the play bottom sheet
                Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);

                Navigator.of(context).push(TournamentListScreen.buildRoute());
              },
              leading: const Icon(LichessIcons.tournament_cup),
              title: Text(context.l10n.arenaArenaTournaments),
            ),
            ListTile(
              onTap: () {
                _openOfflineComputerGame(context);
              },
              leading: const Icon(Icons.memory),
              title: Text(context.l10n.playAgainstComputer),
              trailing: hasResumableOfflineComputerGame
                  ? _ResumeButton(
                      key: const ValueKey('resumeOfflineComputerGameButton'),
                      onPressed: () => _openOfflineComputerGame(context, resumeGame: true),
                    )
                  : null,
            ),
            ListTile(
              onTap: () {
                _openOverTheBoardGame(context);
              },
              leading: const Icon(Icons.table_restaurant_outlined),
              title: Text(context.l10n.mobileOverTheBoard),
              trailing: hasResumableOtbGame
                  ? _ResumeButton(
                      key: const ValueKey('resumeOtbGameButton'),
                      onPressed: () => _openOverTheBoardGame(context, resumeGame: true),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _openOfflineComputerGame(BuildContext context, {bool resumeGame = false}) {
    // Pops the play bottom sheet
    Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(OfflineComputerGameScreen.buildRoute(resumeGame: resumeGame));
  }

  void _openOverTheBoardGame(BuildContext context, {bool resumeGame = false}) {
    // Pops the play bottom sheet
    Navigator.of(context).popUntil((route) => route is! ModalBottomSheetRoute);
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(OverTheBoardScreen.buildRoute(resumeGame: resumeGame));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListSection(hasLeading: true, materialFilledCard: true, children: children);
  }
}

class _ResumeButton extends StatelessWidget {
  const _ResumeButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.resume,
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow),
    );
  }
}
