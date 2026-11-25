import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../repositories/data_repository.dart';
import '../services/score_photo_reader.dart';
import '../services/score_photo_perspective.dart';

/// Optional image preparation before OCR. Never writes a draft or a game.
class ScorePhotoPrepareScreen extends StatefulWidget {
  final ScorePhotoDocument source;
  const ScorePhotoPrepareScreen({super.key, required this.source});
  @override
  State<ScorePhotoPrepareScreen> createState() =>
      _ScorePhotoPrepareScreenState();
}

class _ScorePhotoPrepareScreenState extends State<ScorePhotoPrepareScreen> {
  late List<Offset> _points;
  String? _uid;
  int? _token;
  int _selected = 0;
  bool _edit = true, _dirty = false, _busy = false, _error = false;
  ScorePhotoDocument? _preview;
  @override
  void initState() {
    super.initState();
    final owner = context.read<DataRepository?>();
    _uid = owner?.arsenalUserId;
    _token = owner?.seasonAccountToken;
    _resetPoints();
  }

  void _resetPoints() {
    final s = widget.source.size;
    _points = [
      Offset.zero,
      Offset(s.width, 0),
      Offset(s.width, s.height),
      Offset(0, s.height),
    ];
  }

  bool get _owner =>
      mounted &&
      context.read<DataRepository?>()?.arsenalUserId == _uid &&
      context.read<DataRepository?>()?.seasonAccountToken == _token;
  ScorePhotoPerspective? get _geometry {
    try {
      return ScorePhotoPerspective(widget.source.size, _points);
    } on FormatException {
      return null;
    }
  }

  void _point(Offset position, Size display, {bool advance = false}) {
    final source = widget.source.size;
    setState(() {
      _points[_selected] = Offset(
        (position.dx / display.width).clamp(0, 1) * source.width,
        (position.dy / display.height).clamp(0, 1) * source.height,
      );
      _dirty = true;
      _error = false;
      _preview = null;
      if (advance) _selected = (_selected + 1) % 4;
    });
  }

  Future<void> _rectify() async {
    final geometry = _geometry;
    if (geometry == null || _busy || !_owner) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final image = await geometry.rectify(widget.source);
      if (_owner) setState(() => _preview = image);
    } catch (_) {
      if (_owner) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final owner = context.watch<DataRepository?>();
    if (owner?.arsenalUserId != _uid || owner?.seasonAccountToken != _token) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.ballAccountChanged)),
      );
    }
    final labels = [
      l.photoScoreCornerTL,
      l.photoScoreCornerTR,
      l.photoScoreCornerBR,
      l.photoScoreCornerBL,
    ];
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.photoScorePrepare)),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _busy,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.photoScorePrepareHint),
                  if (_busy) const LinearProgressIndicator(),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        key: const ValueKey('photo-corners-edit'),
                        label: Text(l.photoScoreCornersEdit),
                        selected: _edit,
                        onSelected: (_) => setState(() => _edit = true),
                      ),
                      ChoiceChip(
                        key: const ValueKey('photo-corners-move'),
                        label: Text(l.photoScoreMoveZoom),
                        selected: !_edit,
                        onSelected: (_) => setState(() => _edit = false),
                      ),
                    ],
                  ),
                  DropdownButton<int>(
                    key: const ValueKey('photo-corner-choice'),
                    value: _selected,
                    isExpanded: true,
                    items: [
                      for (var i = 0; i < 4; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('${i + 1}. ${labels[i]}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selected = v);
                    },
                  ),
                  LayoutBuilder(
                    builder: (c, box) {
                      final viewport = Size(
                        box.maxWidth,
                        (box.maxWidth / widget.source.size.aspectRatio).clamp(
                          180.0,
                          400.0,
                        ),
                      );
                      final fitted = applyBoxFit(
                        BoxFit.contain,
                        widget.source.size,
                        viewport,
                      ).destination;
                      return SizedBox(
                        height: viewport.height,
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 6,
                          panEnabled: !_edit,
                          scaleEnabled: !_edit,
                          child: Center(
                            child: GestureDetector(
                              key: const ValueKey('photo-corner-image'),
                              behavior: HitTestBehavior.opaque,
                              onTapUp: !_edit
                                  ? null
                                  : (d) => _point(
                                      d.localPosition,
                                      fitted,
                                      advance: true,
                                    ),
                              onPanStart: !_edit
                                  ? null
                                  : (d) => _point(d.localPosition, fitted),
                              onPanUpdate: !_edit
                                  ? null
                                  : (d) => _point(d.localPosition, fitted),
                              child: SizedBox(
                                width: fitted.width,
                                height: fitted.height,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      widget.source.image,
                                      fit: BoxFit.fill,
                                    ),
                                    CustomPaint(
                                      painter: _CornerPainter(
                                        _points
                                            .map(
                                              (p) => Offset(
                                                p.dx / widget.source.size.width,
                                                p.dy /
                                                    widget.source.size.height,
                                              ),
                                            )
                                            .toList(),
                                        _selected,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_dirty && _geometry == null)
                    Text(l.photoScoreCornersInvalid),
                  if (_error) Text(l.photoScorePrepareFailed),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        key: const ValueKey('photo-corners-reset'),
                        onPressed: () => setState(() {
                          _resetPoints();
                          _selected = 0;
                          _dirty = false;
                          _error = false;
                          _preview = null;
                        }),
                        child: Text(l.photoScoreCornersReset),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('photo-corners-preview'),
                        onPressed: _dirty && _geometry != null
                            ? _rectify
                            : null,
                        icon: const Icon(Icons.crop_rotate),
                        label: Text(l.photoScoreCornersPreview),
                      ),
                    ],
                  ),
                  if (_preview != null) ...[
                    Text(l.photoScorePreparedPreview),
                    SizedBox(
                      height: 220,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        child: Image.memory(
                          _preview!.image,
                          key: const ValueKey('photo-prepared-preview'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('photo-read-prepared'),
                    onPressed: _dirty && _preview == null
                        ? null
                        : () {
                            if (_owner)
                              Navigator.pop(context, _preview ?? widget.source);
                          },
                    child: Text(
                      _preview == null
                          ? l.photoScoreReadOriginal
                          : l.photoScoreReadPrepared,
                    ),
                  ),
                  if (_dirty)
                    TextButton(
                      key: const ValueKey('photo-use-original'),
                      onPressed: () {
                        if (_owner) Navigator.pop(context, widget.source);
                      },
                      child: Text(l.photoScoreReadOriginal),
                    ),
                  Text(l.photoScorePreparePrivacy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final List<Offset> points;
  final int selected;
  const _CornerPainter(this.points, this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    final p = points
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
    final path = Path()..addPolygon(p, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.cyan
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < 4; i++) {
      final point = Offset(
        p[i].dx.clamp(12, math.max(12, size.width - 12)),
        p[i].dy.clamp(12, math.max(12, size.height - 12)),
      );
      canvas.drawCircle(
        point,
        12,
        Paint()..color = i == selected ? Colors.orange : Colors.cyan,
      );
      final text = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => true;
}
