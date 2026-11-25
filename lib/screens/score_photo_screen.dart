import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../repositories/data_repository.dart';
import '../services/score_photo_draft_store.dart';
import '../widgets/score_photo_region_selector.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../services/score_photo_reader.dart';
import '../services/score_photo_frame_reader.dart';
import 'score_photo_prepare_screen.dart';
import '../services/score_photo_review.dart';
import '../services/score_photo_proposer.dart';
import '../widgets/score_photo_summary.dart';

class ScorePhotoScreen extends StatefulWidget {
  /// Injection seam for tests; production uses the gallery and on-device OCR.
  final Future<ScorePhotoDocument?> Function()? loadPhoto;
  final ScorePhotoDraftStore? draftStore;
  final Future<ScorePhotoDocument?> Function()? loadSource;
  final Future<ScorePhotoDocument> Function(ScorePhotoDocument)?
  recognizePrepared;
  final ScorePhotoFrameReader? frameReader;
  const ScorePhotoScreen({
    super.key,
    this.loadPhoto,
    this.draftStore,
    this.frameReader,
    this.loadSource,
    this.recognizePrepared,
  });

  @override
  State<ScorePhotoScreen> createState() => _ScorePhotoScreenState();
}

class _ScorePhotoScreenState extends State<ScorePhotoScreen>
    with WidgetsBindingObserver {
  ScorePhotoDocument? _document;
  ScorePhotoRow? _extracted;
  Rect? _row;
  List<double> _dividers = List.generate(11, (i) => i / 10);
  bool _busy = false;
  bool _applying = false;
  String? _error;
  int _generation = 0;
  String? _ownerUid;
  int? _ownerToken;
  ScorePhotoDraft? _pending;
  Map<String, dynamic>? _progress;
  List<List<String>>? _candidate;
  List<String> _rawCells = [];
  bool _draftError = false;
  bool _saving = false;
  bool _saved = false;
  bool _discarding = false;
  int _saveVersion = 0;
  List<ScorePhotoProposal> _proposals = [];
  bool _simple = false;
  bool _showSelection = true;
  bool _ambiguousColumns = false;
  List<int?> _observedCumulative = List.filled(10, null);

  List<List<String>> get _currentFrames => _progress == null
      ? _candidate!
      : (_progress!['frames'] as List)
            .map((f) => List<String>.from(f as List))
            .toList();
  Map<String, dynamic> _newProgress(List<List<String>> frames, String total) =>
      {
        'frames': frames
            .map((f) => List.generate(3, (t) => t < f.length ? f[t] : ''))
            .toList(),
        'total': total,
        'reviewed': <int>[],
        'totalReviewed': false,
        'activeFrame': 0,
      };
  void _installProposal(ScorePhotoProposal proposal) {
    _row = proposal.row;
    _dividers = List.of(proposal.dividers);
    _candidate = proposal.frames;
    _rawCells = proposal.rawCells;
    _extracted = null;
    _observedCumulative = List.of(proposal.observedCumulative);
    _ambiguousColumns = proposal.ambiguousColumns;
    _progress = _newProgress(_candidate!, proposal.printedTotal ?? '');
    _simple = true;
    _showSelection = false;
  }

  void _analyse(ScorePhotoDocument document) {
    _proposals = ScorePhotoProposer().propose(document);
    _simple = true;
    _showSelection = _proposals.isEmpty;
    _ambiguousColumns = false;
    _observedCumulative = List.filled(10, null);
    if (_proposals.length == 1) _installProposal(_proposals.single);
  }

  Future<void> _chooseProposal(ScorePhotoProposal proposal) async {
    if (!await _confirmChange() || !_sameOwner) return;
    setState(() {
      _installProposal(proposal);
      _generation++;
    });
    await _saveDraft();
  }

  Future<void> _applyScore(ReviewedPhotoScore score) async {
    if (!_sameOwner || _applying) return;
    setState(() => _applying = true);
    _progress = _newProgress(score.frames, score.total.toString())
      ..['reviewed'] = List.generate(10, (i) => i)
      ..['totalReviewed'] = true;
    await _saveDraft();
    if (_sameOwner) Navigator.pop(context, score);
  }

  void _changeSummaryTotal(String value) {
    _progress ??= _newProgress(_candidate!, value);
    setState(() {
      _progress!['total'] = value;
      _progress!['totalReviewed'] = false;
    });
    _saveDraft();
  }

  ScorePhotoDraftStore get _store =>
      widget.draftStore ??
      context.read<ScorePhotoDraftStore?>() ??
      ScorePhotoDraftStore.shared;
  bool get _sameOwner =>
      mounted &&
      context.read<DataRepository?>()?.arsenalUserId == _ownerUid &&
      context.read<DataRepository?>()?.seasonAccountToken == _ownerToken;

  @override
  void initState() {
    super.initState();
    _ownerUid = context.read<DataRepository?>()?.arsenalUserId;
    _ownerToken = context.read<DataRepository?>()?.seasonAccountToken;
    WidgetsBinding.instance.addObserver(this);
    _loadDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _sameOwner) _saveDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final draft = await _store.load(ownerUid: _ownerUid);
      if (_sameOwner && _document == null) setState(() => _pending = draft);
    } catch (_) {
      if (_sameOwner) setState(() => _draftError = true);
    }
  }

  void _resume() {
    final draft = _pending;
    if (draft == null || !_sameOwner) return;
    final state = draft.state;
    setState(() {
      _document = draft.document;
      final raw = state['row'] as List?;
      _row = raw == null
          ? null
          : Rect.fromLTRB(
              (raw[0] as num).toDouble(),
              (raw[1] as num).toDouble(),
              (raw[2] as num).toDouble(),
              (raw[3] as num).toDouble(),
            );
      _dividers = (state['dividers'] as List)
          .map((v) => (v as num).toDouble())
          .toList();
      _candidate = (state['candidate'] as List?)
          ?.map((f) => List<String>.from(f as List))
          .toList();
      _rawCells = List<String>.from(state['rawCells'] as List);
      _progress = state['progress'] == null
          ? null
          : Map<String, dynamic>.from(state['progress'] as Map);
      _simple = (state['simpleSummary'] as bool?) ?? false;
      _showSelection = (state['showSelection'] as bool?) ?? true;
      _ambiguousColumns = (state['ambiguousColumns'] as bool?) ?? false;
      _observedCumulative =
          (state['observedCumulative'] as List?)?.cast<int?>() ??
          List.filled(10, null);
      _proposals = _simple || _candidate == null
          ? ScorePhotoProposer().propose(draft.document)
          : [];
      _pending = null;
      _draftError = false;
      _saved = true;
      _generation++;
    });
  }

  Future<void> _saveDraft() {
    final document = _document;
    if (document == null || !_sameOwner || _discarding) return Future.value();
    final row = _row;
    final version = ++_saveVersion;
    setState(() {
      _saving = true;
    });
    final write = _store
        .save(
          ownerUid: _ownerUid,
          document: document,
          state: {
            'row': row == null
                ? null
                : [row.left, row.top, row.right, row.bottom],
            'dividers': List.of(_dividers),
            'candidate': _candidate,
            'rawCells': List.of(_rawCells),
            'progress': _progress,
            'simpleSummary': _simple,
            'showSelection': _showSelection,
            'ambiguousColumns': _ambiguousColumns,
            'observedCumulative': _observedCumulative,
          },
        )
        .then((_) {
          if (_sameOwner && version == _saveVersion)
            setState(() {
              _saving = false;
              _saved = true;
              _draftError = false;
            });
        })
        .catchError((Object _) {
          if (_sameOwner && version == _saveVersion)
            setState(() {
              _saving = false;
              _saved = false;
              _draftError = true;
            });
        });
    return write;
  }

  Future<bool> _confirmChange({bool newPhoto = false}) async {
    if (_candidate == null &&
        _pending == null &&
        !_draftError &&
        !(newPhoto && _document != null))
      return true;
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.photoScoreChangeTitle),
        content: Text(l.photoScoreChangeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.photoScoreCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.photoScoreContinue),
          ),
        ],
      ),
    );
    return result == true && _sameOwner;
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.photoScoreDiscardTitle),
        content: Text(l.photoScoreDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.photoScoreCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.photoScoreDiscard),
          ),
        ],
      ),
    );
    if (result != true || !_sameOwner) return;
    _saveVersion++;
    setState(() {
      _busy = true;
      _discarding = true;
    });
    try {
      await _store.clear(ownerUid: _ownerUid);
      if (!_sameOwner) return;
      setState(() {
        _document = null;
        _pending = null;
        _candidate = null;
        _extracted = null;
        _progress = null;
        _row = null;
        _rawCells = [];
        _proposals = [];
        _simple = false;
        _showSelection = true;
        _observedCumulative = List.filled(10, null);
        _ambiguousColumns = false;
        _saved = false;
        _saving = false;
        _draftError = false;
        _saveVersion++;
      });
    } catch (_) {
      if (_sameOwner) setState(() => _draftError = true);
    } finally {
      _discarding = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    if (!await _confirmChange(newPhoto: true) || !_sameOwner) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ScorePhotoDocument? document;
      if (widget.loadPhoto != null) {
        document = await widget.loadPhoto!();
      } else {
        final reader = ScorePhotoReader();
        final ScorePhotoDocument? source;
        if (widget.loadSource != null) {
          source = await widget.loadSource!();
        } else {
          final file = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );
          if (file == null || !_sameOwner) return;
          source = await reader.loadImage(file.path);
        }
        if (source == null) return;
        if (!_sameOwner) return;
        final prepared = await Navigator.push<ScorePhotoDocument>(
          context,
          MaterialPageRoute(
            builder: (_) => ScorePhotoPrepareScreen(source: source!),
          ),
        );
        if (!_sameOwner || prepared == null) return;
        document = await (widget.recognizePrepared ?? reader.readPrepared)(
          prepared,
        );
      }
      if (!_sameOwner || document == null) return;
      setState(() {
        _document = document;
        _row = null;
        _extracted = null;
        _candidate = null;
        _progress = null;
        _rawCells = [];
        _pending = null;
        _analyse(document!);
        _generation++;
      });
      await _saveDraft();
    } on ScorePhotoException catch (e) {
      if (mounted) setState(() => _error = e.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'read');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final document = _document;
    if (context.watch<DataRepository?>()?.arsenalUserId != _ownerUid ||
        context.watch<DataRepository?>()?.seasonAccountToken != _ownerToken) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.ballAccountChanged)),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.photoScoreTitle)),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy || _applying,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.photoScorePrivacy),
                if (_pending != null) ...[
                  Text(l.photoScoreResumeTitle),
                  TextButton(
                    key: const ValueKey('photo-resume'),
                    onPressed: _resume,
                    child: Text(l.photoScoreResume),
                  ),
                ],
                if (_saving) Text(l.photoScoreDraftSaving),
                if (_saved && !_saving) Text(l.photoScoreDraftSaved),
                if (_draftError) ...[
                  Text(l.photoScoreDraftError),
                  if (_document != null)
                    TextButton(
                      key: const ValueKey('photo-draft-retry'),
                      onPressed: _saveDraft,
                      child: Text(l.photoScoreDraftRetry),
                    ),
                ],
                if (_pending != null || _document != null || _draftError)
                  TextButton(
                    key: const ValueKey('photo-discard'),
                    onPressed: _discard,
                    child: Text(l.photoScoreDiscard),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('photo-pick'),
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l.photoScorePick),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error == 'size'
                          ? l.photoScoreSize
                          : _error == 'platform'
                          ? l.photoScorePlatform
                          : l.photoScoreError,
                    ),
                  ),
                if (document != null) ...[
                  const SizedBox(height: 12),
                  if (_proposals.length > 1) ...[
                    Text(l.photoScoreChooseRow),
                    for (var i = 0; i < _proposals.length; i++)
                      Card(
                        child: Column(
                          children: [
                            ScorePhotoProposalImage(
                              document: document,
                              row: _proposals[i].row,
                              maxHeight: 140,
                            ),
                            TextButton(
                              key: ValueKey('photo-row-$i'),
                              onPressed: () => _chooseProposal(_proposals[i]),
                              child: Text('${l.photoScoreRowLabel} ${i + 1}'),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (_candidate == null && _proposals.isEmpty)
                    Text(l.photoScoreNoProposals),
                  if (_showSelection) ...[
                    Text(l.photoScoreRegion),
                    const SizedBox(height: 12),
                    ScorePhotoRegionSelector(
                      key: ValueKey(_generation),
                      document: document,
                      initialRow: _row,
                      initialDividers: _dividers,
                      onEditRequested: _confirmChange,
                      onChanged: (row, dividers) {
                        if (!_sameOwner ||
                            (_row == row && listEquals(_dividers, dividers)))
                          return;
                        setState(() {
                          _row = row;
                          _dividers = dividers;
                          _extracted = null;
                          _candidate = null;
                          _progress = null;
                          _rawCells = [];
                          _observedCumulative = List.filled(10, null);
                          _ambiguousColumns = false;
                        });
                        _saveDraft();
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      key: const ValueKey('photo-extract'),
                      onPressed: _row == null
                          ? null
                          : () async {
                              if (!await _confirmChange() || !_sameOwner)
                                return;
                              setState(() {
                                _extracted = ScorePhotoRow.extract(
                                  tokens: document.symbols,
                                  row: _row!,
                                  dividers: _dividers,
                                );
                                _candidate = _extracted!.frames;
                                _rawCells = _extracted!.rawCells;
                                _observedCumulative =
                                    ScorePhotoProposer.readCumulative(
                                      document,
                                      _row!,
                                      _dividers,
                                    );
                                _progress = _newProgress(
                                  _candidate!,
                                  _observedCumulative[9]?.toString() ?? '',
                                );
                                _ambiguousColumns = false;
                                _simple = true;
                                _showSelection = false;
                              });
                              _saveDraft();
                            },
                      child: Text(
                        _row == null
                            ? l.photoScoreNoRegion
                            : l.photoScoreExtract,
                      ),
                    ),
                  ],
                  if (_candidate == null && !_showSelection)
                    TextButton(
                      key: const ValueKey('photo-manual-selection'),
                      onPressed: () => setState(() => _showSelection = true),
                      child: Text(l.photoScoreAdjustSelection),
                    ),
                  if (_candidate != null && _simple)
                    ScorePhotoSummary(
                      key: ValueKey(_candidate),
                      document: document,
                      row: _row!,
                      frames: _currentFrames,
                      total: (_progress?['total'] as String?) ?? '',
                      observedCumulative: _observedCumulative,
                      ambiguousColumns: _ambiguousColumns,
                      onTotalChanged: _changeSummaryTotal,
                      onConfirm: _applyScore,
                      onCorrect: () {
                        setState(() => _simple = false);
                        _saveDraft();
                      },
                      onAdjust: () {
                        setState(() => _showSelection = true);
                        _saveDraft();
                      },
                    ),
                  if (_candidate != null && !_simple) ...[
                    TextButton(
                      key: const ValueKey('photo-return-summary'),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _simple = true);
                        _saveDraft();
                      },
                      child: Text(l.photoScoreReturnSummary),
                    ),
                    TextButton(
                      key: const ValueKey('photo-adjust-selection'),
                      onPressed: () => setState(() => _showSelection = true),
                      child: Text(l.photoScoreAdjustSelection),
                    ),
                    ScorePhotoReviewForm(
                      key: ValueKey(_candidate),
                      candidate: ScorePhotoCandidate(
                        frames: _candidate!,
                        printedTotal: null,
                      ),
                      rawCells: _rawCells,
                      document: document,
                      selectedRow: _row,
                      dividers: _dividers,
                      numberCandidates: document.numberCandidates,
                      initialProgress: _progress,
                      frameReader: widget.frameReader,
                      canReadFrame: () => _sameOwner && !_applying,
                      onProgress: (value) {
                        _progress = value;
                        _saveDraft();
                      },
                      onApply: _applyScore,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explicit review of every frame and total. No persistence occurs here.
class ScorePhotoReviewForm extends StatefulWidget {
  final ScorePhotoCandidate candidate;
  final List<String> rawCells;
  final List<String> numberCandidates;
  final ScorePhotoDocument? document;
  final Rect? selectedRow;
  final List<double>? dividers;
  final ValueChanged<ReviewedPhotoScore> onApply;
  final Map<String, dynamic>? initialProgress;
  final ScorePhotoFrameReader? frameReader;
  final bool Function()? canReadFrame;
  final ValueChanged<Map<String, dynamic>>? onProgress;
  const ScorePhotoReviewForm({
    super.key,
    required this.candidate,
    required this.onApply,
    this.initialProgress,
    this.frameReader,
    this.canReadFrame,
    this.onProgress,
    this.document,
    this.selectedRow,
    this.dividers,
    this.rawCells = const [],
    this.numberCandidates = const [],
  });

  @override
  State<ScorePhotoReviewForm> createState() => _ScorePhotoReviewFormState();
}

class _ScorePhotoReviewFormState extends State<ScorePhotoReviewForm> {
  late final List<List<TextEditingController>> _throws;
  late final TextEditingController _total;
  final Set<int> _reviewed = {};
  bool _readingFrame = false;
  bool _recognizingFrame = false;
  bool _totalReviewed = false;
  int _activeFrame = 0;
  final _frameKeys = List.generate(10, (_) => GlobalKey());

  void _emit() => widget.onProgress?.call({
    'frames': _throws.map((f) => f.map((c) => c.text).toList()).toList(),
    'total': _total.text,
    'reviewed': _reviewed.toList(),
    'totalReviewed': _totalReviewed,
    'activeFrame': _activeFrame,
  });
  void _go(int frame) {
    FocusScope.of(context).unfocus();
    setState(() => _activeFrame = frame.clamp(0, 9));
    _emit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _frameKeys[_activeFrame].currentContext;
      if (mounted && c != null)
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 220),
          alignment: .03,
        );
    });
  }

  Future<void> _readFrame(int frame) async {
    if (_readingFrame || widget.canReadFrame?.call() == false) return;
    final source = widget.document;
    final row = widget.selectedRow;
    final dividers = widget.dividers;
    if (source == null || row == null || dividers == null) return;
    final l = AppLocalizations.of(context)!;
    final owner = context.read<DataRepository?>();
    final uid = owner?.arsenalUserId;
    final token = owner?.seasonAccountToken;
    bool allowed() =>
        mounted &&
        widget.canReadFrame?.call() != false &&
        owner?.arsenalUserId == uid &&
        owner?.seasonAccountToken == token;
    FocusScope.of(context).unfocus();
    setState(() {
      _readingFrame = true;
      _recognizingFrame = true;
    });
    try {
      final result = await (widget.frameReader ?? const ScorePhotoFrameReader())
          .read(
            source,
            Rect.fromLTRB(
              row.left + row.width * dividers[frame],
              row.top,
              row.left + row.width * dividers[frame + 1],
              row.bottom,
            ),
            frame,
          );
      if (!allowed()) return;
      setState(() => _recognizingFrame = false);
      final valid =
          ScorePhotoCandidate.frameProblem(result.throws, index: frame) == null;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (c) {
          final current = c.watch<DataRepository?>();
          final same =
              current?.arsenalUserId == uid &&
              current?.seasonAccountToken == token;
          return AlertDialog(
            title: Text(l.photoScoreReread),
            content: !same
                ? Text(l.photoScoreRereadFailed)
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.memory(
                          result.crop,
                          key: const ValueKey('photo-reread-crop'),
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                        Text(l.photoScoreRereadHint),
                        Text(
                          '${l.photoScoreFrame} ${frame + 1}: ${result.throws.where((v) => v.isNotEmpty).join(" ")}',
                        ),
                        Text('${l.photoScoreRaw}: ${result.raw}'),
                        if (!valid) Text(l.photoScoreInvalidFrame),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                key: const ValueKey('photo-reread-cancel'),
                onPressed: () => Navigator.pop(c, false),
                child: Text(l.photoScoreRereadKeep),
              ),
              FilledButton(
                key: const ValueKey('photo-reread-accept'),
                onPressed: same && valid ? () => Navigator.pop(c, true) : null,
                child: Text(l.photoScoreRereadUse),
              ),
            ],
          );
        },
      );
      if (accepted != true || !allowed()) return;
      setState(() {
        for (var t = 0; t < 3; t++) {
          _throws[frame][t].text = result.throws[t];
        }
        _reviewed.remove(frame);
        _totalReviewed = false;
        _activeFrame = frame;
      });
      _emit();
    } catch (_) {
      if (allowed())
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.photoScoreRereadFailed)));
    } finally {
      if (mounted)
        setState(() {
          _readingFrame = false;
          _recognizingFrame = false;
        });
    }
  }

  String _problemText(AppLocalizations l, ScorePhotoFrameProblemCode code) =>
      switch (code) {
        ScorePhotoFrameProblemCode.missingThrow => l.photoScoreMissingThrow,
        ScorePhotoFrameProblemCode.unknownSymbol => l.photoScoreUnknownSymbol,
        ScorePhotoFrameProblemCode.unexpectedThrow =>
          l.photoScoreUnexpectedThrow,
        ScorePhotoFrameProblemCode.invalidSpare => l.photoScoreInvalidSpare,
        ScorePhotoFrameProblemCode.pinSum => l.photoScorePinSum,
        ScorePhotoFrameProblemCode.spareExpected => l.photoScoreSpareExpected,
      };

  @override
  void initState() {
    super.initState();
    _throws = List.generate(
      10,
      (f) => List.generate(
        3,
        (t) => TextEditingController(
          text:
              f < widget.candidate.frames.length &&
                  t < widget.candidate.frames[f].length
              ? widget.candidate.frames[f][t]
              : '',
        ),
      ),
    );
    _total = TextEditingController(text: widget.candidate.printedTotal ?? '');
    final saved = widget.initialProgress;
    if (saved != null) {
      final values = saved['frames'] as List;
      for (var f = 0; f < 10; f++) {
        for (var t = 0; t < 3; t++) {
          _throws[f][t].text = (values[f] as List)[t] as String;
        }
      }
      _total.text = saved['total'] as String;
      _totalReviewed = saved['totalReviewed'] as bool;
      _reviewed.addAll((saved['reviewed'] as List).cast<int>());
      _activeFrame = saved['activeFrame'] as int;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _go(_activeFrame);
      });
    }
  }

  @override
  void dispose() {
    for (final frame in _throws) {
      for (final controller in frame) {
        controller.dispose();
      }
    }
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final review = ScorePhotoCandidate(
      frames: _throws.map((f) => f.map((c) => c.text).toList()).toList(),
      printedTotal: _total.text,
    ).validate(reviewedFrames: _reviewed, totalReviewed: _totalReviewed);
    final invalidFrames = review.issues
        .where((e) => e.code == ScorePhotoIssueCode.invalidFrame)
        .map((e) => e.frameIndex)
        .toSet();
    final codes = review.issues.map((e) => e.code).toSet();
    final problems = List.generate(
      10,
      (f) => ScorePhotoCandidate.frameProblem(
        _throws[f].map((c) => c.text).toList(),
        index: f,
      ),
    );

    final numbers = widget.numberCandidates.toSet().toList();
    bool matches(String value) =>
        review.calculatedTotal != null &&
        int.tryParse(value) == review.calculatedTotal;
    final orderedNumbers = [
      ...numbers.where(matches),
      ...numbers.where((v) => !matches(v)),
    ];
    return AbsorbPointer(
      absorbing: _readingFrame,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_recognizingFrame) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(l.photoScoreReviewHint),
          Text('${l.photoScoreProgress}: ${_reviewed.length}/10'),
          Wrap(
            spacing: 6,
            children: [
              for (var f = 0; f < 10; f++)
                ChoiceChip(
                  key: ValueKey('photo-frame-tab-$f'),
                  label: Text('${f + 1}'),
                  avatar: Icon(
                    _reviewed.contains(f)
                        ? Icons.check_circle_outline
                        : problems[f] != null
                        ? Icons.error_outline
                        : Icons.circle_outlined,
                    size: 16,
                  ),
                  selected: _activeFrame == f,
                  onSelected: (_) => _go(f),
                ),
            ],
          ),
          for (var f = 0; f < 10; f++)
            Card(
              key: _frameKeys[f],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l.photoScoreFrame} ${f + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.document != null &&
                        widget.selectedRow != null &&
                        widget.dividers != null)
                      _ScoreCellPreview(
                        document: widget.document!,
                        cell: Rect.fromLTRB(
                          widget.selectedRow!.left +
                              widget.selectedRow!.width * widget.dividers![f],
                          widget.selectedRow!.top,
                          widget.selectedRow!.left +
                              widget.selectedRow!.width *
                                  widget.dividers![f + 1],
                          widget.selectedRow!.bottom,
                        ),
                      ),
                    if (widget.document != null &&
                        widget.selectedRow != null &&
                        widget.dividers != null)
                      OutlinedButton.icon(
                        key: ValueKey('photo-reread-$f'),
                        onPressed: () => _readFrame(f),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: Text(l.photoScoreReread),
                      ),
                    Text(
                      '${l.photoScoreCumulative}: ${review.calculatedFrameTotals[f] ?? "\u2014"}',
                      key: ValueKey('photo-cumulative-$f'),
                    ),
                    if (f < widget.rawCells.length)
                      Text('${l.photoScoreRaw}: ${widget.rawCells[f]}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (
                          var t = 0;
                          t < (f == 9 || _throws[f][2].text.isNotEmpty ? 3 : 2);
                          t++
                        )
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TextField(
                                key: ValueKey('photo-throw-$f-$t'),
                                controller: _throws[f][t],
                                textCapitalization:
                                    TextCapitalization.characters,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: InputDecoration(
                                  labelText: '${l.photoScoreThrow} ${t + 1}',
                                  errorText: problems[f]?.throwIndex == t
                                      ? l.photoScoreCellInvalid
                                      : null,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  setState(() {
                                    _reviewed.remove(f);
                                    _activeFrame = f;
                                    _totalReviewed = false;
                                  });
                                  _emit();
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (problems[f] != null)
                      Text(
                        '${l.photoScoreThrow} ${problems[f]!.throwIndex + 1}: ${_problemText(l, problems[f]!.code)}',
                        key: ValueKey('photo-frame-error-$f'),
                      ),
                    CheckboxListTile(
                      key: ValueKey('photo-reviewed-$f'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.photoScoreReviewed),
                      value: _reviewed.contains(f),
                      onChanged: problems[f] != null
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _reviewed.add(f);
                                } else {
                                  _reviewed.remove(f);
                                }
                              });
                              _emit();
                            },
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        OutlinedButton(
                          key: ValueKey('photo-previous-$f'),
                          onPressed: f == 0 ? null : () => _go(f - 1),
                          child: Text(l.photoScorePrevious),
                        ),
                        OutlinedButton(
                          key: ValueKey('photo-next-$f'),
                          onPressed: f == 9 ? null : () => _go(f + 1),
                          child: Text(l.photoScoreNext),
                        ),
                        FilledButton.tonal(
                          key: ValueKey('photo-confirm-next-$f'),
                          onPressed: problems[f] != null
                              ? null
                              : () {
                                  setState(() => _reviewed.add(f));
                                  _go(f == 9 ? 9 : f + 1);
                                },
                          child: Text(
                            f == 9
                                ? l.photoScoreConfirmFrame
                                : l.photoScoreConfirmNext,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (widget.numberCandidates.isNotEmpty)
            DropdownButtonFormField<String>(
              key: const ValueKey('photo-total-candidates'),
              value: orderedNumbers.contains(_total.text) ? _total.text : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.photoScoreNumbers),
              items: orderedNumbers
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        matches(v) ? '$v - ${l.photoScoreMatchesThrows}' : v,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _total.text = value ?? '';
                  _totalReviewed = false;
                });
                _emit();
              },
            ),
          const SizedBox(height: 12),
          Text(l.photoScoreHandicapHint),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('photo-total'),
            controller: _total,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.photoScorePrintedTotal,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() => _totalReviewed = false);
              _emit();
            },
          ),
          CheckboxListTile(
            key: const ValueKey('photo-total-reviewed'),
            title: Text(l.photoScoreReviewed),
            value: _totalReviewed,
            onChanged: (v) {
              setState(() => _totalReviewed = v ?? false);
              _emit();
            },
          ),
          Text(
            '${l.photoScoreCalculated}: ${review.calculatedTotal ?? "\u2014"}',
          ),
          if (invalidFrames.isNotEmpty) Text(l.photoScoreInvalidFrame),
          if (codes.contains(ScorePhotoIssueCode.missingPrintedTotal) ||
              codes.contains(ScorePhotoIssueCode.invalidPrintedTotal))
            Text(l.photoScoreTotalMissing),
          if (codes.contains(ScorePhotoIssueCode.totalMismatch))
            Text(l.photoScoreMismatch),
          if (codes.contains(ScorePhotoIssueCode.humanReviewRequired))
            Text(l.photoScoreReviewMissing),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('photo-apply'),
            onPressed: review.canApply
                ? () => widget.onApply(review.requireReviewedScore())
                : null,
            icon: const Icon(Icons.check),
            label: Text(l.photoScoreApply),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Enlarges the original source cell without changing the OCR coordinates.
class _ScoreCellPreview extends StatelessWidget {
  final ScorePhotoDocument document;
  final Rect cell;
  const _ScoreCellPreview({required this.document, required this.cell});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 140,
    child: LayoutBuilder(
      builder: (_, constraints) {
        final sx = constraints.maxWidth / cell.width;
        final sy = 140 / cell.height;
        final scale = sx < sy ? sx : sy;
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left:
                      -cell.left * scale +
                      (constraints.maxWidth - cell.width * scale) / 2,
                  top: -cell.top * scale + (140 - cell.height * scale) / 2,
                  width: document.size.width * scale,
                  height: document.size.height * scale,
                  child: Image.memory(
                    document.image,
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
