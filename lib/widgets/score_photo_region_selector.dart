import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../l10n/app_localizations.dart';
import '../services/score_photo_reader.dart';

class ScorePhotoRegionSelector extends StatefulWidget {
  final ScorePhotoDocument document;
  final Rect? initialRow;
  final List<double>? initialDividers;
  final void Function(Rect?, List<double>) onChanged;
  final Future<bool> Function()? onEditRequested;
  const ScorePhotoRegionSelector({
    super.key,
    required this.document,
    required this.onChanged,
    this.initialRow,
    this.initialDividers,
    this.onEditRequested,
  });
  @override
  State<ScorePhotoRegionSelector> createState() =>
      _ScorePhotoRegionSelectorState();
}

class _ScorePhotoRegionSelectorState extends State<ScorePhotoRegionSelector> {
  final _view = TransformationController();
  Offset? _start;
  Rect? _row;
  late List<double> _dividers;
  late bool _capture;
  int? _pointer;
  int? _moving;
  int _divider = 1;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRow;
    _row = initial == null
        ? null
        : Rect.fromLTRB(
            initial.left / widget.document.size.width,
            initial.top / widget.document.size.height,
            initial.right / widget.document.size.width,
            initial.bottom / widget.document.size.height,
          );
    _dividers = List.of(
      widget.initialDividers ?? List.generate(11, (i) => i / 10),
    );
    _capture = _row == null;
  }

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  Offset _point(Offset p, Size size) =>
      Offset((p.dx / size.width).clamp(0, 1), (p.dy / size.height).clamp(0, 1));

  void _notify() {
    final r = _row;
    widget.onChanged(
      r == null || r.width < .05 || r.height < .005
          ? null
          : Rect.fromLTRB(
              r.left * widget.document.size.width,
              r.top * widget.document.size.height,
              r.right * widget.document.size.width,
              r.bottom * widget.document.size.height,
            ),
      List.of(_dividers),
    );
  }

  void _zoom(double factor) {
    final scale = (_view.value.getMaxScaleOnAxis() * factor).clamp(1.0, 6.0);
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    final scene = _view.toScene(center);
    _view.value = Matrix4.identity()
      ..translate(center.dx - scene.dx * scale, center.dy - scene.dy * scale)
      ..scale(scale);
  }

  Future<void> _edit() async {
    if (widget.onEditRequested != null && !await widget.onEditRequested!())
      return;
    if (mounted) setState(() => _capture = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('photo-move-mode'),
              onPressed: () => setState(() {
                _capture = false;
                _pointer = null;
              }),
              icon: const Icon(Icons.pan_tool_outlined),
              label: Text(l.photoScoreMoveZoom),
            ),
            OutlinedButton.icon(
              key: const ValueKey('photo-edit-region'),
              onPressed: _edit,
              icon: const Icon(Icons.crop),
              label: Text(l.photoScoreResetRegion),
            ),
            IconButton(
              key: const ValueKey('photo-zoom-in'),
              tooltip: l.photoScoreZoomIn,
              onPressed: () => _zoom(1.5),
              icon: const Icon(Icons.zoom_in),
            ),
            IconButton(
              key: const ValueKey('photo-zoom-out'),
              tooltip: l.photoScoreZoomOut,
              onPressed: () => _zoom(1 / 1.5),
              icon: const Icon(Icons.zoom_out),
            ),
            IconButton(
              key: const ValueKey('photo-reset-view'),
              tooltip: l.photoScoreResetView,
              onPressed: () => _view.value = Matrix4.identity(),
              icon: const Icon(Icons.fit_screen),
            ),
          ],
        ),
        Text(_capture ? l.photoScoreSelectMode : l.photoScoreMoveMode),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            _viewport = Size(
              constraints.maxWidth,
              (constraints.maxWidth / widget.document.size.aspectRatio).clamp(
                160.0,
                360.0,
              ),
            );
            final fitted = applyBoxFit(
              BoxFit.contain,
              widget.document.size,
              _viewport,
            ).destination;
            return SizedBox(
              height: _viewport.height,
              child: InteractiveViewer(
                key: const ValueKey('photo-image-viewer'),
                transformationController: _view,
                minScale: 1,
                maxScale: 6,
                panEnabled: !_capture,
                scaleEnabled: !_capture,
                child: SizedBox(
                  width: _viewport.width,
                  height: _viewport.height,
                  child: Center(
                    child: SizedBox(
                      width: fitted.width,
                      height: fitted.height,
                      child: RawGestureDetector(
                        gestures: _capture
                            ? {
                                EagerGestureRecognizer:
                                    GestureRecognizerFactoryWithHandlers<
                                      EagerGestureRecognizer
                                    >(EagerGestureRecognizer.new, (_) {}),
                              }
                            : {},
                        child: Listener(
                          key: const ValueKey('photo-row-selector'),
                          onPointerDown: (d) {
                            if (!_capture || _pointer != null) return;
                            _pointer = d.pointer;
                            setState(() {
                              final p = _point(d.localPosition, fitted);
                              _moving = null;
                              final r = _row;
                              if (r != null &&
                                  p.dy >= r.top &&
                                  p.dy <= r.bottom) {
                                var nearest =
                                    12 / _view.value.getMaxScaleOnAxis();
                                for (var i = 1; i < 10; i++) {
                                  final distance =
                                      (p.dx - r.left - r.width * _dividers[i])
                                          .abs() *
                                      fitted.width;
                                  if (distance < nearest) {
                                    nearest = distance;
                                    _moving = i;
                                    _divider = i;
                                  }
                                }
                              }
                              if (_moving == null) {
                                _start = p;
                                _row = null;
                                _dividers = List.generate(11, (i) => i / 10);
                                _notify();
                              }
                            });
                          },
                          onPointerMove: (d) {
                            if (!_capture || _pointer != d.pointer) return;
                            setState(() {
                              final p = _point(d.localPosition, fitted);
                              final i = _moving;
                              if (i != null && _row != null) {
                                _dividers[i] =
                                    ((p.dx - _row!.left) / _row!.width).clamp(
                                      _dividers[i - 1] + .002,
                                      _dividers[i + 1] - .002,
                                    );
                              } else if (_start != null) {
                                _row = Rect.fromPoints(_start!, p);
                              }
                            });
                          },
                          onPointerUp: (d) {
                            if (_pointer != d.pointer) return;
                            _pointer = null;
                            _notify();
                            setState(() => _capture = false);
                          },
                          onPointerCancel: (d) {
                            if (_pointer != d.pointer) return;
                            _pointer = null;
                            setState(() => _capture = false);
                          },
                          child: CustomPaint(
                            foregroundPainter: _NumberedRowPainter(
                              _row,
                              _dividers,
                            ),
                            child: Image.memory(
                              widget.document.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_row != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: const ValueKey('photo-divider-picker'),
            value: _divider,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.photoScoreDivider),
            items: List.generate(
              9,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('${i + 1} / ${i + 2}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) setState(() => _divider = value);
            },
          ),
          Slider(
            key: const ValueKey('photo-divider-slider'),
            onChangeEnd: !_capture ? null : (_) => _notify(),
            min: _dividers[_divider - 1] + .002,
            max: _dividers[_divider + 1] - .002,
            value: _dividers[_divider].clamp(
              _dividers[_divider - 1] + .002,
              _dividers[_divider + 1] - .002,
            ),
            onChanged: !_capture
                ? null
                : (value) => setState(() {
                    _dividers[_divider] = value;
                  }),
          ),
          Text(l.photoScoreDividerHelp),
        ],
      ],
    );
  }
}

class _NumberedRowPainter extends CustomPainter {
  final Rect? row;
  final List<double> dividers;
  _NumberedRowPainter(this.row, List<double> values)
    : dividers = List.of(values);
  @override
  void paint(Canvas canvas, Size size) {
    final r = row;
    if (r == null) return;
    final rect = Rect.fromLTRB(
      r.left * size.width,
      r.top * size.height,
      r.right * size.width,
      r.bottom * size.height,
    );
    final pen = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, pen);
    for (var i = 0; i < 10; i++) {
      final left = rect.left + rect.width * dividers[i];
      final right = rect.left + rect.width * dividers[i + 1];
      if (i > 0)
        canvas.drawLine(Offset(left, rect.top), Offset(left, rect.bottom), pen);
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            backgroundColor: Colors.black87,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (left + right - label.width) / 2,
          (rect.top - label.height).clamp(0, size.height - label.height),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NumberedRowPainter old) => true;
}
