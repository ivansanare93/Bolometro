import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import '../services/score_photo_reader.dart';
import '../services/score_photo_review.dart';
import '../services/score_photo_proposer.dart';

class ScorePhotoSummary extends StatefulWidget {
  final ScorePhotoDocument document;
  final Rect row;
  final List<List<String>> frames;
  final String total;
  final List<int?> observedCumulative;
  final bool ambiguousColumns;
  final ValueChanged<String> onTotalChanged;
  final ValueChanged<ReviewedPhotoScore> onConfirm;
  final VoidCallback onCorrect, onAdjust;
  const ScorePhotoSummary({
    super.key,
    required this.document,
    required this.row,
    required this.frames,
    required this.total,
    required this.observedCumulative,
    required this.ambiguousColumns,
    required this.onTotalChanged,
    required this.onConfirm,
    required this.onCorrect,
    required this.onAdjust,
  });
  @override
  State<ScorePhotoSummary> createState() => _ScorePhotoSummaryState();
}

class _ScorePhotoSummaryState extends State<ScorePhotoSummary> {
  late final TextEditingController _total;
  @override
  void initState() {
    super.initState();
    _total = TextEditingController(text: widget.total);
  }

  @override
  void didUpdateWidget(covariant ScorePhotoSummary old) {
    super.didUpdateWidget(old);
    if (_total.text != widget.total) _total.text = widget.total;
  }

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  void _openPhoto() {
    final l = AppLocalizations.of(context)!;
    final uid = context.read<DataRepository?>()?.arsenalUserId;
    final token = context.read<DataRepository?>()?.seasonAccountToken;
    final document = widget.document;
    final row = widget.row;
    showDialog<void>(
      context: context,
      builder: (c) {
        final owner = c.watch<DataRepository?>();
        final allowed =
            owner?.arsenalUserId == uid && owner?.seasonAccountToken == token;
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(l.photoScoreFullPhoto),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(c),
              ),
            ),
            body: !allowed
                ? Center(child: Text(l.ballAccountChanged))
                : Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 8,
                      child: ScorePhotoProposalImage(
                        document: document,
                        row: row,
                        maxHeight: 900,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final candidate = ScorePhotoCandidate(
      frames: widget.frames,
      printedTotal: widget.total,
    );
    final review = candidate.validate();
    final coherent = review.issues.every(
      (i) => i.code == ScorePhotoIssueCode.humanReviewRequired,
    );
    final cumulativeMismatch = ScorePhotoProposer.cumulativeMismatch(
      List.generate(10, (i) => i == 9 ? null : widget.observedCumulative[i]),
      review,
    );
    final ready = coherent && !cumulativeMismatch && !widget.ambiguousColumns;
    final codes = review.issues.map((i) => i.code).toSet();
    final numbers = widget.document.numberCandidates.toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.photoScoreProposalTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(l.photoScoreReviewOriginal),
        const SizedBox(height: 12),
        ScorePhotoProposalImage(document: widget.document, row: widget.row),
        TextButton.icon(
          key: const ValueKey('photo-full-image'),
          onPressed: _openPhoto,
          icon: const Icon(Icons.zoom_in),
          label: Text(l.photoScoreFullPhoto),
        ),
        LayoutBuilder(
          builder: (c, constraints) {
            final minimum = math.max(
              82.0,
              MediaQuery.textScalerOf(context).scale(70),
            );
            final columns = math.max(
              1,
              (constraints.maxWidth / (minimum + 6)).floor(),
            );
            final width = (constraints.maxWidth - (columns - 1) * 6) / columns;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var f = 0; f < 10; f++)
                  SizedBox(
                    width: width,
                    child: Card(
                      key: ValueKey('photo-summary-frame-$f'),
                      color:
                          ScorePhotoCandidate.frameProblem(
                                widget.frames[f],
                                index: f,
                              ) !=
                              null
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text('${l.photoScoreFrame} ${f + 1}'),
                            Text(
                              widget.frames[f]
                                      .where((v) => v.isNotEmpty)
                                      .join(' ')
                                      .isEmpty
                                  ? '\u2014'
                                  : widget.frames[f]
                                        .where((v) => v.isNotEmpty)
                                        .join(' '),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${review.calculatedFrameTotals[f] ?? "\u2014"}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          '${l.photoScoreCalculated}: ${review.calculatedTotal ?? "\u2014"}',
          key: const ValueKey('photo-summary-calculated'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (numbers.isNotEmpty)
          DropdownButtonFormField<String>(
            key: const ValueKey('photo-summary-numbers'),
            value: numbers.contains(widget.total) ? widget.total : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.photoScoreNumbers),
            items: numbers
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              if (v != null) widget.onTotalChanged(v);
            },
          ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('photo-summary-total'),
          controller: _total,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.photoScorePrintedTotal,
            border: const OutlineInputBorder(),
          ),
          onChanged: widget.onTotalChanged,
        ),
        const SizedBox(height: 8),
        Text(l.photoScoreHandicapHint),
        if (codes.contains(ScorePhotoIssueCode.invalidFrame))
          Text(l.photoScoreProposalUnknown),
        if (codes.contains(ScorePhotoIssueCode.missingPrintedTotal) ||
            codes.contains(ScorePhotoIssueCode.invalidPrintedTotal))
          Text(l.photoScoreTotalMissing),
        if (codes.contains(ScorePhotoIssueCode.totalMismatch))
          Text(l.photoScoreMismatch),
        if (widget.ambiguousColumns) Text(l.photoScoreProposalAmbiguous),
        if (cumulativeMismatch) Text(l.photoScoreProposalCumulativeMismatch),
        if (ready) Text(l.photoScoreProposalCoherent),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const ValueKey('photo-summary-apply'),
          onPressed: !ready
              ? null
              : () => widget.onConfirm(
                  candidate
                      .validate(
                        reviewedFrames: Set.of(List.generate(10, (i) => i)),
                        totalReviewed: true,
                      )
                      .requireReviewedScore(),
                ),
          icon: const Icon(Icons.check),
          label: Text(l.photoScoreSingleConfirm),
        ),
        OutlinedButton.icon(
          key: const ValueKey('photo-correct-reading'),
          onPressed: widget.onCorrect,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l.photoScoreCorrectReading),
        ),
        TextButton(
          key: const ValueKey('photo-adjust-selection'),
          onPressed: widget.onAdjust,
          child: Text(l.photoScoreAdjustSelection),
        ),
      ],
    );
  }
}

/// Shows the original image with the proposed row; never redraws or modifies it.
class ScorePhotoProposalImage extends StatelessWidget {
  final ScorePhotoDocument document;
  final Rect row;
  final double maxHeight;
  const ScorePhotoProposalImage({
    super.key,
    required this.document,
    required this.row,
    this.maxHeight = 260,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, constraints) {
      final fitted = applyBoxFit(
        BoxFit.contain,
        document.size,
        Size(constraints.maxWidth, maxHeight),
      ).destination;
      return Center(
        child: SizedBox(
          width: fitted.width,
          height: fitted.height,
          child: CustomPaint(
            foregroundPainter: _ProposedRowPainter(row, document.size),
            child: Image.memory(
              document.image,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    },
  );
}

class _ProposedRowPainter extends CustomPainter {
  final Rect row;
  final Size original;
  _ProposedRowPainter(this.row, this.original);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      row.left / original.width * size.width,
      row.top / original.height * size.height,
      row.right / original.width * size.width,
      row.bottom / original.height * size.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ProposedRowPainter old) =>
      old.row != row || old.original != original;
}
