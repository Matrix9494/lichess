import 'dart:convert';

import 'package:deep_pick/deep_pick.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:lichess_mobile/src/model/analysis/analysis_summary.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/study/study.dart';
import 'package:lichess_mobile/src/model/study/study_filter.dart';
import 'package:lichess_mobile/src/model/study/study_list_paginator.dart';
import 'package:lichess_mobile/src/network/http.dart';

/// A provider for [StudyRepository].
final studyRepositoryProvider = Provider<StudyRepository>((Ref ref) {
  return StudyRepository(ref, ref.watch(lichessClientProvider), ref.watch(defaultClientProvider));
}, name: 'StudyRepositoryProvider');

class StudyRepository {
  StudyRepository(this.ref, this.client, [this.anonymousClient]);

  final Client client;
  final Client? anonymousClient;
  final Ref ref;

  Future<StudyList> getStudies({
    required StudyCategory category,
    required StudyListOrder order,
    int page = 1,
  }) {
    return _requestStudies(
      path: '${category.name}/${order.name}',
      queryParameters: {'page': page.toString()},
    );
  }

  Future<StudyList> searchStudies({
    required String query,
    required StudyListOrder order,
    int page = 1,
  }) {
    return _requestStudies(
      path: 'search',
      queryParameters: {'page': page.toString(), 'q': query, 'order': order.name},
    );
  }

  Future<StudyList> _requestStudies({
    required String path,
    required Map<String, String> queryParameters,
  }) {
    return client.readJson(
      lichessUri('/study/$path', queryParameters),
      headers: {'Accept': 'application/json'},
      mapper: (Map<String, dynamic> json) {
        final paginator = pick(json, 'paginator').asMapOrThrow<String, dynamic>();

        return (
          studies: pick(
            paginator,
            'currentPageResults',
          ).asListOrThrow((pick) => StudyPageItem.fromJson(pick.asMapOrThrow())).toIList(),
          nextPage: pick(paginator, 'nextPage').asIntOrNull(),
        );
      },
    );
  }

  Future<(Study study, AnalysisSummary? analysisSummary, String pgn)> getStudy({
    required StudyId id,
    StudyChapterId? chapterId,
  }) async {
    final study = await _readOpenJson(
      lichessUri((chapterId != null) ? '/study/$id/$chapterId' : '/study/$id', {'chapters': '1'}),
      headers: {'Accept': 'application/json'},
      mapper: Study.fromServerJson,
    );

    final response = await _readOpenResponse(
      lichessUri('/api/study/$id/${chapterId ?? study.chapter.id}.pgn', {'analysisHeader': '1'}),
      headers: {'Accept': 'application/x-chess-pgn'},
    );

    return (study, readAnalysisSummaryFromHeader(response), utf8.decode(response.bodyBytes));
  }

  Future<String> getStudyPgn(StudyId id) async {
    final pgnBytes = await client.readBytes(
      lichessUri('/api/study/$id.pgn'),
      headers: {'Accept': 'application/x-chess-pgn'},
    );

    return utf8.decode(pgnBytes);
  }

  Future<T> _readOpenJson<T>(
    Uri uri, {
    Map<String, String>? headers,
    required T Function(Map<String, dynamic>) mapper,
  }) async {
    try {
      return await client.readJson(uri, headers: headers, mapper: mapper);
    } on ServerException catch (e) {
      if (e.statusCode != 403 || anonymousClient == null) rethrow;
      return anonymousClient!.readJson(uri, headers: headers, mapper: mapper);
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
