import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'seleccionar_bola_field.dart';

class GameBallAssignments extends StatelessWidget {
  const GameBallAssignments({
    super.key,
    required this.ballId,
    required this.assignments,
    required this.onChanged,
    this.activeFrame,
  });
  final String? ballId;
  final Map<String, String?> assignments;
  final void Function(String?, Map<String, String?>) onChanged;
  final int Function()? activeFrame;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeleccionarBolaField(
          ballId: ballId,
          title: l.ballDefault,
          onChanged: (id) => onChanged(id, Map.of(assignments)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l.ballDefaultHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        OutlinedButton.icon(
          key: const Key('ball-throw-editor'),
          icon: const Icon(Icons.view_list_outlined),
          label: Text(l.ballPerThrow),
          onPressed: () async {
            final repo = context.read<DataRepository>();
            final uid = repo.arsenalUserId;
            final token = repo.seasonAccountToken;
            final balls = await repo.listarTodasLasBolas();
            if (!context.mounted ||
                uid != repo.arsenalUserId ||
                token != repo.seasonAccountToken)
              return;
            final names = {
              for (final b in balls) b.id: '${b.name} (${b.weightLbs} lb)',
            };
            final result = await showModalBottomSheet<Map<String, String?>>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _ThrowEditor(
                defaultId: ballId,
                initial: assignments,
                names: names,
                initialFrame: activeFrame?.call() ?? 0,
                owner: uid,
                token: token,
              ),
            );
            if (!context.mounted ||
                result == null ||
                uid != repo.arsenalUserId ||
                token != repo.seasonAccountToken)
              return;
            onChanged(ballId, result);
          },
        ),
        if (assignments.isNotEmpty)
          Text(
            l.ballOverrideCount(assignments.length),
            key: const Key('ball-assignment-count'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _ThrowEditor extends StatefulWidget {
  const _ThrowEditor({
    required this.defaultId,
    required this.initial,
    required this.names,
    required this.initialFrame,
    required this.owner,
    required this.token,
  });
  final String? defaultId, owner;
  final int token, initialFrame;
  final Map<String, String?> initial;
  final Map<String, String> names;
  @override
  State<_ThrowEditor> createState() => _ThrowEditorState();
}

class _ThrowEditorState extends State<_ThrowEditor> {
  late final Map<String, String?> draft = Map.of(widget.initial);
  late int from = widget.initialFrame.clamp(0, 9);
  int until = 9;
  int kind = -1;
  String? idAt(int f, int t) => draft.containsKey(Partida.throwKey(f, t))
      ? draft[Partida.throwKey(f, t)]
      : widget.defaultId;
  bool get ownerMatches {
    final repo = context.read<DataRepository>();
    return repo.arsenalUserId == widget.owner &&
        repo.seasonAccountToken == widget.token;
  }

  Future<void> choose({int? frame, int? shot}) async {
    final current = frame == null ? widget.defaultId : idAt(frame, shot!);
    final result = await seleccionarBolaConResultado(
      context,
      seleccionActualId: current,
      includeBallIds: {
        if (widget.defaultId != null) widget.defaultId!,
        ...draft.values.whereType<String>(),
      },
    );
    if (!mounted || result == null || !ownerMatches) return;
    setState(() {
      if (frame != null) {
        draft[Partida.throwKey(frame, shot!)] = result.id;
        return;
      }
      for (var f = from; f <= until; f++) {
        for (var t = 0; t < (f == 9 ? 3 : 2); t++) {
          if (kind == -1 || kind == t)
            draft[Partida.throwKey(f, t)] = result.id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String name(String? id) => id == null
        ? l.statisticsWithoutBall
        : widget.names[id] ?? l.statisticsBallReference(id);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.ballPerThrow,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text(l.ballThrowsHint),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: const Key('ball-range-start'),
                  value: from,
                  decoration: InputDecoration(labelText: l.ballRangeFrom),
                  items: [
                    for (var f = 0; f < 10; f++)
                      DropdownMenuItem(value: f, child: Text('${f + 1}')),
                  ],
                  onChanged: (v) {
                    if (v != null)
                      setState(() {
                        from = v;
                        if (until < from) until = from;
                      });
                  },
                ),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: const Key('ball-range-end'),
                  value: until,
                  decoration: InputDecoration(labelText: l.ballRangeUntil),
                  items: [
                    for (var f = from; f < 10; f++)
                      DropdownMenuItem(value: f, child: Text('${f + 1}')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => until = v);
                  },
                ),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: const Key('ball-range-kind'),
                  value: kind,
                  decoration: InputDecoration(labelText: l.ballRangeShots),
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text(
                        l.ballAllThrows,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (var t = 0; t < 3; t++)
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          l.ballThrowNumber(t + 1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => kind = v);
                  },
                ),
                TextButton(
                  onPressed: () => choose(),
                  child: Text(l.ballApplyRange),
                ),
                TextButton(
                  key: const Key('ball-clear-overrides'),
                  onPressed: () => setState(draft.clear),
                  child: Text(l.ballClearOverrides),
                ),
                const Divider(),
                for (var f = 0; f < 10; f++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frame ${f + 1}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        for (var t = 0; t < (f == 9 ? 3 : 2); t++)
                          ListTile(
                            key: Key('ball-throw-$f-$t'),
                            title: Text(l.ballThrowNumber(t + 1)),
                            subtitle: Text(name(idAt(f, t))),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => choose(frame: f, shot: t),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    key: const Key('ball-save-overrides'),
                    onPressed: () => ownerMatches
                        ? Navigator.pop(context, Map<String, String?>.of(draft))
                        : Navigator.pop(context),
                    child: Text(l.ballSaveAssignments),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
