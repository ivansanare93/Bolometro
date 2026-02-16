import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../repositories/data_repository.dart';
import '../utils/estadisticas_utils.dart';
import '../widgets/comparison_chart.dart';
import '../l10n/app_localizations.dart';

/// Pantalla de comparación detallada entre el usuario actual y un amigo
class ComparisonScreen extends StatefulWidget {
  final Friend friend;

  const ComparisonScreen({
    super.key,
    required this.friend,
  });

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final FriendsService _friendsService = FriendsService();
  bool _isLoading = true;
  Map<String, dynamic>? _myStats;
  Map<String, dynamic>? _friendStats;
  List<double> _myScores = [];
  List<double> _friendScores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    try {
      // Obtener mis sesiones y calcular estadísticas
      final misSesiones = await dataRepository.obtenerSesiones();
      _myStats = EstadisticasUtils.calcularEstadisticasExtendidas(misSesiones);
      
      // Obtener mis últimas 20 puntuaciones para el gráfico de tendencia
      final misPartidas = <Partida>[];
      for (final sesion in misSesiones) {
        misPartidas.addAll(sesion.partidas);
      }
      misPartidas.sort((a, b) => a.fecha.compareTo(b.fecha));
      _myScores = misPartidas
          .take(20)
          .map((p) => p.total.toDouble())
          .toList();

      // Obtener estadísticas del amigo
      _friendStats = await _friendsService.obtenerEstadisticasAmigo(widget.friend.userId);
      
      // Obtener puntuaciones del amigo (si están disponibles)
      // Por ahora, usamos datos simulados ya que no tenemos acceso a las partidas del amigo
      // En una implementación real, necesitaríamos una API para obtener estas partidas
      _friendScores = List.generate(20, (index) => 150.0 + (index * 2)); // Datos simulados

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error al cargar datos de comparación: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context);
    final myName = authService.user?.displayName ?? localizations.you;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.comparison),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myStats == null || _friendStats == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(myName),
                        const SizedBox(height: 24),
                        _buildStatisticsComparison(localizations, myName),
                        const SizedBox(height: 24),
                        _buildScoresTrendChart(localizations, myName),
                        const SizedBox(height: 24),
                        _buildPieChartComparison(localizations, myName),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            localizations.noData,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String myName) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildUserColumn(
              myName,
              null,
              localizations.you,
            ),
            Text(
              localizations.vsComparison,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            _buildUserColumn(
              widget.friend.nombre,
              widget.friend.photoUrl,
              '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserColumn(String name, String? photoUrl, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildStatisticsComparison(AppLocalizations localizations, String myName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.statisticsComparison,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ComparisonBarChart(
              user1Name: myName,
              user2Name: widget.friend.nombre,
              user1Stats: {
                'average': _myStats!['promedio'] as double? ?? 0.0,
                'best': (_myStats!['mejorPartida'] as int? ?? 0).toDouble(),
                'strikes': _myStats!['strikesPercent'] as double? ?? 0.0,
                'spares': _myStats!['sparesPercent'] as double? ?? 0.0,
              },
              user2Stats: {
                'average': _friendStats!['promedioGeneral'] as double? ?? 0.0,
                'best': (_friendStats!['mejorPartida'] as int? ?? 0).toDouble(),
                'strikes': _friendStats!['strikesPercent'] as double? ?? 0.0,
                'spares': _friendStats!['sparesPercent'] as double? ?? 0.0,
              },
              statKeys: const ['average', 'best', 'strikes', 'spares'],
              statLabels: [
                localizations.average,
                localizations.bestGame,
                '% ${localizations.strikes}',
                '% ${localizations.spares}',
              ],
              user1Color: Colors.blue,
              user2Color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoresTrendChart(AppLocalizations localizations, String myName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.scoresTrend,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ComparisonLineChart(
              user1Name: myName,
              user2Name: widget.friend.nombre,
              user1Scores: _myScores,
              user2Scores: _friendScores,
              user1Color: Colors.blue,
              user2Color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartComparison(AppLocalizations localizations, String myName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.strikes} / ${localizations.spares}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ComparisonPieCharts(
              user1Name: myName,
              user2Name: widget.friend.nombre,
              user1Percentages: {
                'strikes': _myStats!['strikesPercent'] as double? ?? 0.0,
                'spares': _myStats!['sparesPercent'] as double? ?? 0.0,
                'fallos': 100.0 - 
                    (_myStats!['strikesPercent'] as double? ?? 0.0) - 
                    (_myStats!['sparesPercent'] as double? ?? 0.0),
              },
              user2Percentages: {
                'strikes': _friendStats!['strikesPercent'] as double? ?? 0.0,
                'spares': _friendStats!['sparesPercent'] as double? ?? 0.0,
                'fallos': 100.0 - 
                    (_friendStats!['strikesPercent'] as double? ?? 0.0) - 
                    (_friendStats!['sparesPercent'] as double? ?? 0.0),
              },
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(localizations.strikes, Colors.red),
                const SizedBox(width: 16),
                _buildLegendItem(localizations.spares, Colors.purple),
                const SizedBox(width: 16),
                _buildLegendItem('Fallos', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
