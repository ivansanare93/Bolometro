import 'package:flutter/material.dart';
import '../models/catalog_ball.dart';
import '../repositories/ball_catalog_repository.dart';
import '../widgets/catalog_ball_image.dart';
import 'catalog_ball_detail_screen.dart';
import 'editar_bola_screen.dart';

class BallCatalogScreen extends StatefulWidget {
  final BallCatalogRepository repository;
  final bool selectForPhoto;
  const BallCatalogScreen({
    super.key,
    required this.repository,
    this.selectForPhoto = false,
  });
  @override
  State<BallCatalogScreen> createState() => _BallCatalogScreenState();
}

class _BallCatalogScreenState extends State<BallCatalogScreen> {
  CatalogSnapshot? _catalog;
  String _query = '';
  String? _manufacturer;
  CommercialStatus? _status;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool demo = false}) async {
    setState(() {
      _error = null;
      _catalog = null;
    });
    try {
      final catalog = await (demo
          ? widget.repository.demonstration()
          : widget.repository.load());
      if (mounted)
        setState(() {
          _catalog = catalog;
          _manufacturer = null;
          _status = null;
          _query = '';
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'No se pudo abrir el catálogo. Puedes añadir tu bola manualmente.',
        );
    }
  }

  Future<void> _manual() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditarBolaScreen()),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _detail(CatalogBall ball) async {
    if (widget.selectForPhoto) {
      Navigator.pop(context, ball.id);
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CatalogBallDetailScreen(ball: ball)),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final manufacturers =
        catalog?.balls.map((b) => b.manufacturer).toSet().toList() ??
        <String>[];
    manufacturers.sort();
    final results = catalog == null
        ? <CatalogBall>[]
        : BallCatalogRepository.search(
            catalog,
            query: _query,
            manufacturer: _manufacturer,
            status: _status,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de bolas')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (!widget.selectForPhoto)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton.icon(
                      onPressed: _manual,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Añadir manualmente'),
                    ),
                  ),
                if (catalog?.isTestData == true)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text(
                            'DEMOSTRACIÓN · Todos estos modelos y datos son ficticios.',
                          ),
                          TextButton(
                            onPressed: () => _load(),
                            child: const Text('Salir de demostración'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.repository.warning != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(widget.repository.warning!),
                  ),
                if (catalog != null && catalog.balls.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      key: ValueKey(catalog.isTestData),
                      decoration: const InputDecoration(
                        labelText: 'Buscar por fabricante o modelo',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _manufacturer,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Fabricante',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos los fabricantes'),
                            ),
                            ...manufacturers.map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _manufacturer = value),
                        ),
                        DropdownButtonFormField<CommercialStatus>(
                          value: _status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Estado comercial',
                          ),
                          items: [
                            const DropdownMenuItem<CommercialStatus>(
                              value: null,
                              child: Text('Todos los estados'),
                            ),
                            ...CommercialStatus.values.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _status = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: () => _load(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (catalog == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (catalog.balls.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Catálogo en preparación. Todavía no hay modelos comerciales verificados.',
                      ),
                      TextButton(
                        onPressed: () => _load(demo: true),
                        child: const Text(
                          'Ver demostración con datos ficticios',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay modelos con esos filtros. Puedes añadir tu bola manualmente.',
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((_, index) {
                final ball = results[index];
                return ListTile(
                  leading: CatalogBallImage(
                    photo: ball.photo,
                    catalogId: ball.id,
                  ),
                  title: Text(ball.model),
                  subtitle: Text('${ball.manufacturer} · ${ball.status.label}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _detail(ball),
                );
              }, childCount: results.length),
            ),
        ],
      ),
    );
  }
}
