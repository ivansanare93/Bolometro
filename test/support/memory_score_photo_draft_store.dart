import 'dart:convert';
import 'package:bolometro/services/score_photo_draft_store.dart';
import 'package:bolometro/services/score_photo_reader.dart';

class MemoryScorePhotoDraftStore extends ScorePhotoDraftStore {
  final Map<String?, ScorePhotoDraft> drafts = {};
  bool failSave = false;
  bool failLoad = false;
  int saves = 0;
  @override
  Future<void> save({
    required String? ownerUid,
    required ScorePhotoDocument document,
    required Map<String, dynamic> state,
  }) async {
    if (failSave) throw StateError('Simulated storage failure');
    ScorePhotoDraftStore.validateState(state);
    saves++;
    drafts[ownerUid] = ScorePhotoDraft(
      document,
      jsonDecode(jsonEncode(state)) as Map<String, dynamic>,
    );
  }

  @override
  Future<ScorePhotoDraft?> load({required String? ownerUid}) async {
    if (failLoad) throw StateError('Simulated recovery failure');
    return drafts[ownerUid];
  }

  @override
  Future<void> clear({required String? ownerUid}) async {
    drafts.remove(ownerUid);
  }
}
