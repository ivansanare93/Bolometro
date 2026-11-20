import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_ball.dart';
import '../models/catalog_selection.dart';
import '../widgets/catalog_ball_image.dart';
import 'editar_bola_screen.dart';

class CatalogBallDetailScreen extends StatefulWidget {
  final CatalogBall ball;
  const CatalogBallDetailScreen({super.key, required this.ball});
  @override
  State<CatalogBallDetailScreen> createState() =>
      _CatalogBallDetailScreenState();
}

class _CatalogBallDetailScreenState extends State<CatalogBallDetailScreen> {
  int? _weight;
  final _manualWeight = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _manualWeight.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final ball = widget.ball;
    final weight = ball.weights.isEmpty
        ? double.tryParse(_manualWeight.text.trim().replaceAll(',', '.'))
        : _weight?.toDouble();
    if (weight == null || !weight.isFinite || weight <= 0 || weight > 20) {
      setState(() => _error = 'Elige o introduce un peso válido (lb).');
      return;
    }
    if (ball.isTestData) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Añadir una bola ficticia'),
          content: const Text(
            'Este modelo y sus especificaciones son datos de prueba. Si guardas la bola, aparecerá marcada como [PRUEBA] en tu arsenal y podrá respaldarse con tu cuenta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar con la prueba'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    if (!mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditarBolaScreen(catalogSelection: CatalogSelection(ball, weight)),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  Widget _field(String label, Object? value) => ListTile(
    dense: true,
    title: Text(label),
    subtitle: Text(value?.toString() ?? 'No disponible'),
  );

  @override
  Widget build(BuildContext context) {
    final ball = widget.ball;
    final spec = _weight == null ? null : ball.specFor(_weight!);
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del modelo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ball.isTestData)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'DEMOSTRACIÓN · Modelo ficticio. No es una ficha comercial verificada.',
                ),
              ),
            ),
          Center(
            child: CatalogBallImage(
              photo: ball.photo,
              catalogId: ball.id,
              size: 160,
            ),
          ),
          Text(ball.model, style: Theme.of(context).textTheme.headlineSmall),
          Text(ball.manufacturer),
          _field('Estado comercial', ball.status.label),
          _field('Año de lanzamiento', ball.releaseYear),
          _field('Tipo de cubierta', ball.coverType),
          _field('Material de cubierta', ball.coverMaterial),
          _field('Acabado de fábrica', ball.factoryFinish),
          if (ball.weights.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _weight,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Elige el peso (lb)',
              ),
              items: ball.weights
                  .map(
                    (spec) => DropdownMenuItem(
                      value: spec.weightLbs,
                      child: Text('${spec.weightLbs} lb'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _weight = value;
                _error = null;
              }),
            )
          else ...[
            const Text(
              'No hay pesos comerciales verificados. Introduce el peso de tu unidad; no se inferirán especificaciones.',
            ),
            TextField(
              controller: _manualWeight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso de mi bola (lb)',
              ),
            ),
          ],
          _field('Nombre del núcleo', spec?.coreName ?? ball.coreName),
          _field('Tipo de núcleo', spec?.coreType ?? ball.coreType),
          if (ball.weights.isNotEmpty && _weight == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Selecciona un peso para consultar RG y diferenciales.',
              ),
            ),
          _field('RG (pulgadas)', spec?.rgInches),
          _field('Diferencial (pulgadas)', spec?.differentialInches),
          _field(
            'Diferencial intermedio (pulgadas)',
            spec?.intermediateDifferentialInches,
          ),
          _field(
            'Última actualización de la ficha',
            ball.updatedAt.toIso8601String(),
          ),
          if (ball.officialUrl != null)
            TextButton(
              onPressed: () => launchUrl(
                ball.officialUrl!,
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Consultar ficha oficial'),
            ),
          if (ball.photo?.canDisplay == true)
            _field(
              'Fotografía · atribución y permiso',
              '${ball.photo!.rightsHolder} · ${ball.photo!.license}',
            ),
          const Text('Procedencia de los datos'),
          for (final source in ball.sources)
            ListTile(
              dense: true,
              title: Text(
                source.kind == 'fixture'
                    ? 'Fixture ficticio de demostración'
                    : source.url.toString(),
              ),
              subtitle: Text('Revisado: ${source.checkedAt.toIso8601String()}'),
              onTap: source.url == null
                  ? null
                  : () => launchUrl(
                      source.url!,
                      mode: LaunchMode.externalApplication,
                    ),
            ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _add,
            child: const Text('Añadir a mi arsenal'),
          ),
        ],
      ),
    );
  }
}
