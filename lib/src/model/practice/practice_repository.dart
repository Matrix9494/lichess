import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:lichess_mobile/src/model/analysis/analysis_summary.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/practice/practice.dart';
import 'package:lichess_mobile/src/model/study/study.dart';
import 'package:lichess_mobile/src/network/http.dart';

final practiceRepositoryProvider = Provider<PracticeRepository>((Ref ref) {
  return PracticeRepository(ref.watch(lichessClientProvider), ref.watch(defaultClientProvider));
}, name: 'PracticeRepositoryProvider');

class PracticeRepository {
  const PracticeRepository(this.client, [this.anonymousClient]);

  final Client client;
  final Client? anonymousClient;

  Future<PracticeIndex> getPracticeIndex() {
    return _readOpenJson(lichessUri('/practice'), mapper: PracticeIndex.fromJson);
  }

  Future<(Study study, AnalysisSummary? analysisSummary, String pgn, PracticeGoal goal)>
  getPracticeChapter({required StudyId studyId, required StudyChapterId chapterId}) async {
    final data = await _readOpenJson(
      lichessUri('/practice/load/$studyId/$chapterId'),
      mapper: (json) {
        return (
          study: Study.fromServerJson(json),
          goal: PracticeGoal.fromJson(pick(json, 'analysis', 'practiceGoal').asMapOrThrow()),
        );
      },
    );

    final response = await _readOpenResponse(
      lichessUri('/api/study/$studyId/$chapterId.pgn', {'analysisHeader': '1'}),
      headers: {'Accept': 'application/x-chess-pgn'},
    );

    return (
      data.study,
      readAnalysisSummaryFromHeader(response),
      utf8.decode(response.bodyBytes),
      data.goal,
    );
  }

  Future<void> completeChapter({required StudyChapterId chapterId, required int nbMoves}) async {
    final response = await client.post(Uri(path: '/practice/complete/$chapterId/$nbMoves'));
    if (response.statusCode >= 400) {
      throw ServerException(
        response.statusCode,
        'Request to /practice/complete/$chapterId/$nbMoves failed with status ${response.statusCode}',
        response.request?.url ?? Uri(path: '/practice/complete/$chapterId/$nbMoves'),
        null,
      );
    }
  }

  Future<T> _readOpenJson<T>(Uri uri, {required T Function(Map<String, dynamic>) mapper}) async {
    try {
      return await client.readJson(uri, headers: {'Accept': 'application/json'}, mapper: mapper);
    } on ServerException catch (e) {
      if (e.statusCode != 403 || anonymousClient == null) rethrow;
      return anonymousClient!.readJson(
        uri,
        headers: {'Accept': 'application/json'},
        mapper: mapper,
      );
    }
  }

  Future<Response> _readOpenResponse(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await client.readResponse(uri, headers: headers);
    } on ServerException catch (e) {
      if (e.statusCode != 403 || anonymousClient == null) rethrow;
      return anonymousClient!.readResponse(uri, headers: headers);
    }
  }
}
