import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/friend.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../repositories/data_repository.dart';
import '../utils/estadisticas_utils.dart';
import '../models/sesion.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import 'comparison_screen.dart';

/// Pantalla de rankings entre amigos
class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  final FriendsService _friendsService = FriendsService();
  String _selectedPeriod = 'Todo';
  String _selectedCategory = 'average'; // average, strikesPercent, sparesPercent, bestGame, consistency
  bool _isLoading = true;
  List<Map<String, dynamic>> _rankings = [];

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    final userId = authService.userId;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Obtener amigos
      final friends = await _friendsService.obtenerAmigos(userId);

      // Obtener estadísticas propias
      final misSesiones = await dataRepository.obtenerSesiones();
      final misEstadisticas = _calcularEstadisticas(misSesiones, _selectedPeriod);

      final rankings = <Map<String, dynamic>>[];

      // Agregar mis estadísticas
      final currentUser = authService.user;
      rankings.add({
        'userId': userId,
        'nombre': currentUser?.displayName ?? 'Tú',
        'email': currentUser?.email,
        'photoUrl': currentUser?.photoURL,
        'esUsuarioActual': true,
        ...misEstadisticas,
      });

      // Obtener estadísticas de cada amigo
      for (final friend in friends) {
        final stats = await _friendsService.obtenerEstadisticasAmigo(friend.userId);
        if (stats != null) {
          rankings.add({
            'userId': friend.userId,
            'nombre': friend.nombre,
            'email': friend.email,
            'photoUrl': friend.photoUrl,
            'esUsuarioActual': false,
            ...stats,
          });
        }
      }

      // Ordenar según la categoría seleccionada
      rankings.sort((a, b) {
        double valueA = 0.0;
        double valueB = 0.0;
        
        switch (_selectedCategory) {
          case 'average':
            valueA = a['promedioGeneral'] as double? ?? 0.0;
            valueB = b['promedioGeneral'] as double? ?? 0.0;
            return valueB.compareTo(valueA); // Descendente
          case 'strikesPercent':
            valueA = a['strikesPercent'] as double? ?? 0.0;
            valueB = b['strikesPercent'] as double? ?? 0.0;
            return valueB.compareTo(valueA); // Descendente
          case 'sparesPercent':
            valueA = a['sparesPercent'] as double? ?? 0.0;
            valueB = b['sparesPercent'] as double? ?? 0.0;
            return valueB.compareTo(valueA); // Descendente
          case 'bestGame':
            valueA = (a['mejorPartida'] as int? ?? 0).toDouble();
            valueB = (b['mejorPartida'] as int? ?? 0).toDouble();
            return valueB.compareTo(valueA); // Descendente
          case 'consistency':
            valueA = a['consistencia'] as double? ?? 0.0;
            valueB = b['consistencia'] as double? ?? 0.0;
            return valueA.compareTo(valueB); // Ascendente (menor es mejor)
          default:
            valueA = a['promedioGeneral'] as double? ?? 0.0;
            valueB = b['promedioGeneral'] as double? ?? 0.0;
            return valueB.compareTo(valueA);
        }
      });

      // Asignar posiciones
      for (int i = 0; i < rankings.length; i++) {
        rankings[i]['posicion'] = i + 1;
      }

      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar rankings: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _calcularEstadisticas(List<Sesion> sesiones, String periodo) {
    // Filtrar sesiones por periodo
    final now = DateTime.now();
    final sesionesFiltradas = sesiones.where((sesion) {
      switch (periodo) {
        case 'Última semana':
          return sesion.fecha.isAfter(now.subtract(const Duration(days: 7)));
        case 'Último mes':
          return sesion.fecha.isAfter(now.subtract(const Duration(days: 30)));
        case 'Últimos 3 meses':
          return sesion.fecha.isAfter(now.subtract(const Duration(days: 90)));
        default:
          return true;
      }
    }).toList();

    if (sesionesFiltradas.isEmpty) {
      return {
        'totalPartidas': 0,
        'promedioGeneral': 0.0,
        'mejorPartida': 0,
        'strikesPercent': 0.0,
        'sparesPercent': 0.0,
        'consistencia': 0.0,
      };
    }

    final estadisticas = EstadisticasUtils.calcularEstadisticasExtendidas(sesionesFiltradas);

    return {
      'totalPartidas': estadisticas['totalPartidas'] ?? 0,
      'promedioGeneral': estadisticas['promedio'] ?? 0.0,
      'mejorPartida': estadisticas['mejorPartida'] ?? 0,
      'strikesPercent': estadisticas['strikesPercent'] ?? 0.0,
      'sparesPercent': estadisticas['sparesPercent'] ?? 0.0,
      'consistencia': estadisticas['consistencia'] ?? 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;
    final localizations = AppLocalizations.of(context)!;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations.rankings),
        ),
        body: Center(
          child: Text(localizations.loginRequiredMessage),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.rankings),
        actions: [
          // Category selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.category),
            tooltip: localizations.rankingCategory,
            initialValue: _selectedCategory,
            onSelected: (value) {
              setState(() => _selectedCategory = value);
              _loadRankings();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'average',
                child: Text(localizations.categoryAverage),
              ),
              PopupMenuItem(
                value: 'strikesPercent',
                child: Text(localizations.categoryStrikesPercent),
              ),
              PopupMenuItem(
                value: 'sparesPercent',
                child: Text(localizations.categorySparesPercent),
              ),
              PopupMenuItem(
                value: 'bestGame',
                child: Text(localizations.categoryBestGame),
              ),
              PopupMenuItem(
                value: 'consistency',
                child: Text(localizations.categoryConsistency),
              ),
            ],
          ),
          // Period filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadRankings();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Todo', child: Text(localizations.allTime)),
              PopupMenuItem(value: 'Última semana', child: Text(localizations.lastWeek)),
              PopupMenuItem(value: 'Último mes', child: Text(localizations.lastMonth)),
              PopupMenuItem(value: 'Últimos 3 meses', child: Text(localizations.last3Months)),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rankings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRankings,
                  child: _buildRankingsList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noRankingData,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.addFriendsToCompare,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final ranking = _rankings[index];
        return _buildRankingCard(ranking, index);
      },
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> ranking, int index) {
    final localizations = AppLocalizations.of(context)!;
    final posicion = ranking['posicion'] as int;
    final nombre = ranking['nombre'] as String;
    final photoUrl = ranking['photoUrl'] as String?;
    final esUsuarioActual = ranking['esUsuarioActual'] as bool;
    final totalPartidas = ranking['totalPartidas'] as int;
    final promedioGeneral = ranking['promedioGeneral'] as double;
    final mejorPartida = ranking['mejorPartida'] as int;
    final strikesPercent = ranking['strikesPercent'] as double? ?? 0.0;
    final sparesPercent = ranking['sparesPercent'] as double? ?? 0.0;
    final consistencia = ranking['consistencia'] as double? ?? 0.0;

    final colorScheme = Theme.of(context).colorScheme;

    Color? cardColor;
    Widget? medallIcon;

    if (posicion == 1) {
      cardColor = Colors.amber.withOpacity(0.2);
      medallIcon = const Icon(Icons.emoji_events, color: Colors.amber, size: 40);
    } else if (posicion == 2) {
      cardColor = Colors.grey.withOpacity(0.2);
      medallIcon = const Icon(Icons.emoji_events, color: Colors.grey, size: 35);
    } else if (posicion == 3) {
      cardColor = Colors.brown.withOpacity(0.2);
      medallIcon = const Icon(Icons.emoji_events, color: Colors.brown, size: 30);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: esUsuarioActual
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : cardColor,
      elevation: esUsuarioActual ? 4 : 2,
      child: InkWell(
        onTap: esUsuarioActual ? null : () => _showCompareDialog(ranking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Posición o medalla
              SizedBox(
                width: 50,
                child: medallIcon ??
                    Text(
                      '#$posicion',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
              ),
              const SizedBox(width: 16),
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        nombre[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: esUsuarioActual
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (esUsuarioActual)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              localizations.you,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Estadísticas - mostrar basado en categoría seleccionada
                    Wrap(
                      spacing: 0,
                      runSpacing: 4,
                      children: _buildCategoryStats(
                        totalPartidas,
                        promedioGeneral,
                        mejorPartida,
                        strikesPercent,
                        sparesPercent,
                        consistencia,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de comparar (solo para otros usuarios)
              if (!esUsuarioActual)
                IconButton(
                  icon: const Icon(Icons.compare_arrows),
                  tooltip: localizations.compareWithFriend,
                  onPressed: () => _showCompareDialog(ranking),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryStats(
    int totalPartidas,
    double promedioGeneral,
    int mejorPartida,
    double strikesPercent,
    double sparesPercent,
    double consistencia,
  ) {
    final localizations = AppLocalizations.of(context)!;
    
    List<Widget> stats = [];
    
    // Always show games count
    stats.add(_buildStatChip(
      icon: FontAwesomeIcons.bowlingBall,
      label: '$totalPartidas',
      color: Colors.blue,
    ));
    stats.add(const SizedBox(width: 8));
    
    // Show primary stat based on category
    switch (_selectedCategory) {
      case 'average':
        stats.add(_buildStatChip(
          icon: Icons.bar_chart,
          label: promedioGeneral.toStringAsFixed(1),
          color: Colors.green,
          highlighted: true,
        ));
        stats.add(const SizedBox(width: 8));
        stats.add(_buildStatChip(
          icon: Icons.star,
          label: '$mejorPartida',
          color: Colors.orange,
        ));
        break;
      case 'strikesPercent':
        stats.add(_buildStatChip(
          icon: FontAwesomeIcons.x,
          label: '${strikesPercent.toStringAsFixed(1)}%',
          color: Colors.red,
          highlighted: true,
        ));
        stats.add(const SizedBox(width: 8));
        stats.add(_buildStatChip(
          icon: Icons.bar_chart,
          label: promedioGeneral.toStringAsFixed(1),
          color: Colors.green,
        ));
        break;
      case 'sparesPercent':
        stats.add(_buildStatChip(
          icon: Icons.forward_outlined,
          label: '${sparesPercent.toStringAsFixed(1)}%',
          color: Colors.purple,
          highlighted: true,
        ));
        stats.add(const SizedBox(width: 8));
        stats.add(_buildStatChip(
          icon: Icons.bar_chart,
          label: promedioGeneral.toStringAsFixed(1),
          color: Colors.green,
        ));
        break;
      case 'bestGame':
        stats.add(_buildStatChip(
          icon: Icons.star,
          label: '$mejorPartida',
          color: Colors.orange,
          highlighted: true,
        ));
        stats.add(const SizedBox(width: 8));
        stats.add(_buildStatChip(
          icon: Icons.bar_chart,
          label: promedioGeneral.toStringAsFixed(1),
          color: Colors.green,
        ));
        break;
      case 'consistency':
        stats.add(_buildStatChip(
          icon: Icons.trending_flat,
          label: consistencia.toStringAsFixed(1),
          color: Colors.teal,
          highlighted: true,
        ));
        stats.add(const SizedBox(width: 8));
        stats.add(_buildStatChip(
          icon: Icons.bar_chart,
          label: promedioGeneral.toStringAsFixed(1),
          color: Colors.green,
        ));
        break;
    }
    
    return stats;
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(highlighted ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(highlighted ? 0.5 : 0.3),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlighted ? FontWeight.w900 : FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompareDialog(Map<String, dynamic> ranking) {
    final localizations = AppLocalizations.of(context)!;
    final userId = ranking['userId'] as String;
    final nombre = ranking['nombre'] as String;
    final email = ranking['email'] as String?;
    final photoUrl = ranking['photoUrl'] as String?;

    // Create a Friend object from the ranking data
    final friend = Friend(
      userId: userId,
      nombre: nombre,
      email: email ?? '',
      photoUrl: photoUrl,
      fechaAmistad: DateTime.now(), // Not used in comparison screen
    );

    // Navigate to comparison screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparisonScreen(friend: friend),
      ),
    );
  }
}
