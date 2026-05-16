import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/auth/auth_controller.dart';
import 'package:lichess_mobile/src/model/practice/practice.dart';
import 'package:lichess_mobile/src/model/practice/practice_repository.dart';
import 'package:lichess_mobile/src/model/study/study.dart';
import 'package:lichess_mobile/src/model/study/study_filter.dart';
import 'package:lichess_mobile/src/model/study/study_repository.dart';
import 'package:lichess_mobile/src/network/connectivity.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/tab_scaffold.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/view/account/account_menu.dart';
import 'package:lichess_mobile/src/view/coordinate_training/coordinate_training_screen.dart';
import 'package:lichess_mobile/src/view/practice/practice_screen.dart';
import 'package:lichess_mobile/src/view/study/study_list_screen.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:material_symbols_icons/symbols.dart';

final _hotStudiesProvider = FutureProvider.autoDispose<IList<StudyPageItem>>((Ref ref) {
  return StudyRepository(ref, ref.watch(defaultClientProvider))
      .getStudies(category: StudyCategory.all, order: StudyListOrder.hot)
      .then((value) => value.studies);
});

final _myStudiesLengthProvider = FutureProvider.autoDispose<int>((Ref ref) {
  final authUser = ref.watch(authControllerProvider);
  if (authUser == null) return Future.value(0);

  return ref.withClientCacheFor(
    (client) => StudyRepository(ref, client)
        .getStudies(category: StudyCategory.mine, order: StudyListOrder.updated)
        .then((value) => value.studies.length),
    const Duration(hours: 6),
  );
});

final _myFavoriteStudiesLengthProvider = FutureProvider.autoDispose<int>((Ref ref) {
  final authUser = ref.watch(authControllerProvider);
  if (authUser == null) return Future.value(0);

  return ref.withClientCacheFor(
    (client) => StudyRepository(ref, client)
        .getStudies(category: StudyCategory.likes, order: StudyListOrder.updated)
        .then((value) => value.studies.length),
    const Duration(hours: 6),
  );
});

final _practiceIndexProvider = FutureProvider.autoDispose<PracticeIndex>((Ref ref) {
  return ref.watch(practiceRepositoryProvider).getPracticeIndex();
});

class LearnTabScreen extends ConsumerWidget {
  const LearnTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) {
          ref.read(currentBottomTabProvider.notifier).state = BottomTab.home;
        }
      },
      child: DefaultTabController(
        length: 2,
        child: PlatformScaffold(
          appBar: PlatformAppBar(
            title: Text(context.l10n.learnMenu),
            centerTitle: false,
            titleTextStyle: Theme.of(context).platform == TargetPlatform.iOS
                ? Theme.of(context).textTheme.headlineSmall
                : null,
            actions: const [AccountMenuButton()],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Study'),
                Tab(text: 'Practice'),
              ],
            ),
          ),
          body: const _Body(),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).value ?? false;
    if (!isOnline) {
      return const _StudyLearnTab(isOnline: false);
    }

    return const TabBarView(children: [_StudyLearnTab(isOnline: true), _PracticeLearnTab()]);
  }
}

class _StudyLearnTab extends ConsumerWidget {
  const _StudyLearnTab({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authControllerProvider);
    final haveIStudies = authUser != null && (ref.watch(_myStudiesLengthProvider).value ?? 0) > 0;
    final haveIFavoriteStudies =
        authUser != null && (ref.watch(_myFavoriteStudiesLengthProvider).value ?? 0) > 0;

    return ListTileTheme.merge(
      iconColor: Theme.of(context).colorScheme.primary,
      child: ListView(
        controller: learnScrollController,
        children: [
          ListSection(
            hasLeading: true,
            children: [
              ListTile(
                leading: const Icon(Symbols.where_to_vote),
                trailing: Theme.of(context).platform == TargetPlatform.iOS
                    ? const CupertinoListTileChevron()
                    : null,
                title: Text(context.l10n.coordinatesCoordinateTraining, style: Styles.callout),
                onTap: () => Navigator.of(
                  context,
                  rootNavigator: true,
                ).push(CoordinateTrainingScreen.buildRoute()),
              ),
            ],
          ),
          if (isOnline) ...[
            ListSection(
              header: Text(context.l10n.studyMenu),
              onHeaderTap: () =>
                  Navigator.of(context, rootNavigator: true).push(StudyListScreen.buildRoute()),
              hasLeading: true,
              children: [
                ...(switch (ref.watch(_hotStudiesProvider)) {
                  AsyncData(:final value) =>
                    value
                        .take(5)
                        .map((study) => StudyListItem(study: study, titleMaxLines: 1))
                        .toList(growable: false),
                  _ => [],
                }),
              ],
            ),
            if (haveIStudies || haveIFavoriteStudies)
              ListSection(
                hasLeading: true,
                margin: Styles.horizontalBodyPadding.add(Styles.sectionBottomPadding),
                children: [
                  if (haveIStudies)
                    ListTile(
                      leading: const Icon(Symbols.local_library),
                      trailing: Theme.of(context).platform == TargetPlatform.iOS
                          ? const CupertinoListTileChevron()
                          : null,
                      title: Text(context.l10n.studyMyStudies),
                      onTap: isOnline
                          ? () => Navigator.of(
                              context,
                            ).push(StudyListScreen.buildRoute(initialCategory: StudyCategory.mine))
                          : null,
                    ),
                  if (haveIFavoriteStudies)
                    ListTile(
                      leading: const Icon(Symbols.favorite),
                      trailing: Theme.of(context).platform == TargetPlatform.iOS
                          ? const CupertinoListTileChevron()
                          : null,
                      title: Text(context.l10n.studyMyFavoriteStudies),
                      onTap: isOnline
                          ? () => Navigator.of(
                              context,
                            ).push(StudyListScreen.buildRoute(initialCategory: StudyCategory.likes))
                          : null,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _PracticeLearnTab extends ConsumerWidget {
  const _PracticeLearnTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTileTheme.merge(
      iconColor: Theme.of(context).colorScheme.primary,
      child: switch (ref.watch(_practiceIndexProvider)) {
        AsyncData(:final value) => ListView(
          primary: false,
          children: [
            ListSection(
              header: const Text('Practice'),
              hasLeading: true,
              children: [
                if (value.thePinStudy case final study?)
                  _PracticeStudyTile(study: study, completedChapters: value.progress.length),
              ],
            ),
          ],
        ),
        AsyncError() => FullScreenRetryRequest(
          onRetry: () => ref.invalidate(_practiceIndexProvider),
        ),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

class _PracticeStudyTile extends StatelessWidget {
  const _PracticeStudyTile({required this.study, required this.completedChapters});

  final PracticeStudyMeta study;
  final int completedChapters;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.push_pin_outlined),
      trailing: Theme.of(context).platform == TargetPlatform.iOS
          ? const CupertinoListTileChevron()
          : null,
      title: Text(study.name, style: Styles.callout),
      subtitle: Text(
        completedChapters > 0
            ? '$completedChapters completed positions'
            : study.description ?? 'Pin it to win it',
      ),
      onTap: () => Navigator.of(
        context,
        rootNavigator: true,
      ).push(PracticeScreen.buildRoute(studyId: study.id)),
    );
  }
}
