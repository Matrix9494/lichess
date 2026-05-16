import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/practice/practice_repository.dart';
import 'package:lichess_mobile/src/model/study/study_controller.dart';
import 'package:lichess_mobile/src/model/study/study_repository.dart';
import 'package:lichess_mobile/src/network/http.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/view/study/study_screen.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';

final _practiceStartOptionsProvider = FutureProvider.autoDispose.family<StudyOptions, StudyId>((
  Ref ref,
  StudyId studyId,
) async {
  final index = await ref.read(practiceRepositoryProvider).getPracticeIndex();
  final (study, _, _) = await StudyRepository(
    ref,
    ref.read(defaultClientProvider),
  ).getStudy(id: studyId);
  final chapter = study.chapters.firstWhere(
    (chapter) => !index.progress.containsKey(chapter.id),
    orElse: () => study.chapters.first,
  );
  return StudyOptions(id: studyId, initialChapter: chapter.id, practice: true);
});

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({required this.studyId, super.key});

  final StudyId studyId;

  static Route<dynamic> buildRoute({required StudyId studyId}) {
    return buildScreenRoute(screen: PracticeScreen(studyId: studyId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(_practiceStartOptionsProvider(studyId))) {
      AsyncData(:final value) => StudyScreen(options: value),
      AsyncError() => Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: FullScreenRetryRequest(
          onRetry: () => ref.invalidate(_practiceStartOptionsProvider(studyId)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
    };
  }
}
