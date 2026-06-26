import 'package:flutter/material.dart';
import '../services/temporada_service.dart';
import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';

/// Screen for basic season management: view, create, rename, delete and
/// mark one season as the active/default.
class TemporadasScreen extends StatefulWidget {
  const TemporadasScreen({super.key});

  @override
  State<TemporadasScreen> createState() => _TemporadasScreenState();
}

class _TemporadasScreenState extends State<TemporadasScreen> {
  List<String> _temporadas = [];
  String? _temporadaActiva; // null = "Sin temporada"
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final temporadas = await TemporadaService.getTemporadas();
    final activa = await TemporadaService.getTemporadaActiva();
    if (mounted) {
      setState(() {
        _temporadas = temporadas;
        _temporadaActiva = activa;
        _loading = false;
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _setActiva(String? name) async {
    await TemporadaService.setTemporadaActiva(name);
    if (mounted) setState(() => _temporadaActiva = name);
  }

  Future<void> _showAddDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.newSeasonTitle),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.newSeasonHint,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) async {
                  await _submitAdd(
                      l10n, controller, setDialogState, () => Navigator.pop(ctx));
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    await _submitAdd(
                        l10n, controller, setDialogState, () => Navigator.pop(ctx));
                  },
                  child: Text(l10n.accept),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAdd(
    AppLocalizations l10n,
    TextEditingController controller,
    StateSetter setDialogState,
    VoidCallback closeDialog,
  ) async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      setDialogState(() {});
      return;
    }
    if (_temporadas.contains(name) ||
        name == AppConstants.temporadaSinTemporada) {
      setDialogState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonAlreadyExists)),
        );
      }
      return;
    }
    final added = await TemporadaService.addTemporada(name);
    if (added) {
      await _load();
      closeDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonAdded)),
        );
      }
    }
  }

  Future<void> _showRenameDialog(String oldName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: oldName);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(l10n.renameSeason),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.newSeasonHint,
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) async {
                await _submitRename(oldName, l10n, controller, setDialogState,
                    () => Navigator.pop(ctx));
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  await _submitRename(oldName, l10n, controller, setDialogState,
                      () => Navigator.pop(ctx));
                },
                child: Text(l10n.accept),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _submitRename(
    String oldName,
    AppLocalizations l10n,
    TextEditingController controller,
    StateSetter setDialogState,
    VoidCallback closeDialog,
  ) async {
    final newName = controller.text.trim();
    if (newName.isEmpty) {
      setDialogState(() {});
      return;
    }
    if (newName == oldName) {
      closeDialog();
      return;
    }
    if (_temporadas.contains(newName) ||
        newName == AppConstants.temporadaSinTemporada) {
      setDialogState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonAlreadyExists)),
        );
      }
      return;
    }
    final ok = await TemporadaService.renameTemporada(oldName, newName);
    if (ok) {
      await _load();
      closeDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonRenamed)),
        );
      }
    }
  }

  Future<void> _confirmDelete(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSeason),
        content: Text(l10n.deleteSeasonConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.deleteSeason,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TemporadaService.deleteTemporada(name);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.seasonDeleted)),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seasonsManagement),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: l10n.newSeasonTitle,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active season info banner
                _ActiveSeasonBanner(
                  temporadaActiva: _temporadaActiva,
                  l10n: l10n,
                  cs: cs,
                  isDark: isDark,
                ),
                // "Sin temporada" row
                _SinTemporadaRow(
                  isActive: _temporadaActiva == null,
                  onSetActive: () => _setActiva(null),
                  l10n: l10n,
                  cs: cs,
                  isDark: isDark,
                ),
                const Divider(height: 1),
                // Season list
                Expanded(
                  child: _temporadas.isEmpty
                      ? _EmptyState(l10n: l10n)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: _temporadas.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final name = _temporadas[i];
                            final isActive = _temporadaActiva == name;
                            return _SeasonTile(
                              name: name,
                              isActive: isActive,
                              onSetActive: () => _setActiva(name),
                              onRename: () => _showRenameDialog(name),
                              onDelete: () => _confirmDelete(name),
                              l10n: l10n,
                              cs: cs,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ActiveSeasonBanner extends StatelessWidget {
  final String? temporadaActiva;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final bool isDark;

  const _ActiveSeasonBanner({
    required this.temporadaActiva,
    required this.l10n,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = temporadaActiva ?? l10n.sinTemporada;
    return Container(
      width: double.infinity,
      color: isDark
          ? cs.primaryContainer.withOpacity(0.18)
          : cs.primaryContainer.withOpacity(0.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_view_month_rounded,
              color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeSeason,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinTemporadaRow extends StatelessWidget {
  final bool isActive;
  final VoidCallback onSetActive;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final bool isDark;

  const _SinTemporadaRow({
    required this.isActive,
    required this.onSetActive,
    required this.l10n,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.remove_circle_outline,
        color: cs.onSurface.withOpacity(0.45),
      ),
      title: Text(
        l10n.sinTemporada,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: isActive
          ? _ActiveBadge(label: l10n.defaultSeasonLabel, cs: cs)
          : TextButton(
              onPressed: onSetActive,
              child: Text(l10n.setAsActive,
                  style: TextStyle(fontSize: 12, color: cs.primary)),
            ),
    );
  }
}

class _SeasonTile extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final AppLocalizations l10n;
  final ColorScheme cs;

  const _SeasonTile({
    required this.name,
    required this.isActive,
    required this.onSetActive,
    required this.onRename,
    required this.onDelete,
    required this.l10n,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.event_note_rounded,
        color: isActive ? cs.primary : cs.onSurface.withOpacity(0.45),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          color: isActive ? cs.primary : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            _ActiveBadge(label: l10n.defaultSeasonLabel, cs: cs)
          else
            TextButton(
              onPressed: onSetActive,
              child: Text(l10n.setAsActive,
                  style: TextStyle(fontSize: 12, color: cs.primary)),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') onRename();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.renameSeason),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18,
                        color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.deleteSeason,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _ActiveBadge({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_month_rounded,
              size: 56, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.noSeasonsYet,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noSeasonsYetHint,
            style: TextStyle(
                fontSize: 14, color: cs.onSurface.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }
}
