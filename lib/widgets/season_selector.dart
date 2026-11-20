import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/season_assignment_store.dart';
import '../services/temporada_service.dart';

/// Shared season choice for registering, editing and bulk assignment.
/// Archived current values remain visible, but cannot be assigned again.
class SeasonSelector extends StatefulWidget {
  final String? value;
  final List<String> seasons;
  final Set<String> archived;
  final Set<String> excluded;
  final ValueChanged<String?> onChanged;
  final bool allowCreate;

  const SeasonSelector({
    super.key,
    required this.value,
    required this.seasons,
    required this.archived,
    required this.onChanged,
    this.excluded = const {},
    this.allowCreate = true,
  });

  @override
  State<SeasonSelector> createState() => _SeasonSelectorState();
}

class _SeasonSelectorState extends State<SeasonSelector> {
  final _created = <String>{};

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    var entered = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newSeasonTitle),
        content: TextField(
          autofocus: true,
          onChanged: (value) => entered = value,
          decoration: InputDecoration(hintText: l10n.newSeasonHint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, entered),
            child: Text(l10n.accept),
          ),
        ],
      ),
    );
    if (!mounted || name == null) return;
    final normalized = normalizeSeason(name);
    if (normalized == null) {
      widget.onChanged(null);
      return;
    }
    final all = {...widget.seasons, ...widget.archived, ..._created};
    final matches = all.where(
      (s) => s.toLowerCase() == normalized.toLowerCase(),
    );
    final canonical = matches.isEmpty ? normalized : matches.first;
    if (widget.archived.contains(canonical) ||
        widget.excluded.contains(canonical)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.restoreSeasonBeforeAssigning)),
      );
      return;
    }
    if (matches.isEmpty && !await TemporadaService.addTemporada(canonical)) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.saveError)));
      return;
    }
    if (!mounted) return;
    setState(() => _created.add(canonical));
    widget.onChanged(canonical);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = normalizeSeason(widget.value);
    final options =
        {...widget.seasons, ..._created, if (current != null) current}
            .where((s) => !widget.excluded.contains(s))
            .where((s) => !widget.archived.contains(s) || s == current)
            .toList();
    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      hint: Text(l10n.sinTemporada),
      decoration: InputDecoration(
        labelText: l10n.selectSeason,
        border: const OutlineInputBorder(),
        suffixIcon: widget.allowCreate
            ? IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.newSeasonTitle,
                onPressed: _create,
              )
            : null,
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(l10n.sinTemporada)),
        ...options.map(
          (name) => DropdownMenuItem(
            value: name,
            enabled: !widget.archived.contains(name),
            child: Text(
              widget.archived.contains(name)
                  ? '$name (${l10n.archivedSeasonLabel})'
                  : name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: widget.onChanged,
    );
  }
}
