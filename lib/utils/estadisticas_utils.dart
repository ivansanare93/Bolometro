import 'dart:math' show sqrt;
import '../models/sesion.dart';
import '../models/partida.dart';
import 'app_constants.dart';

class EstadisticasUtils {
  /// Racha máxima de strikes o spares (según símbolo)
  static int rachaMaximaDe(String simbolo, List<List<List<String>>> partidasFrames) {
    int maxRacha = 0;
    for (final frames in partidasFrames) {
      int racha = 0;
      for (final frame in frames) {
        if (frame[0] == simbolo || (frame.length > 1 && frame[1] == simbolo)) {
          racha++;
          if (racha > maxRacha) maxRacha = racha;
        } else {
          racha = 0;
        }
      }
    }
    return maxRacha;
  }

  /// Porcentaje de strikes, spares y fallos
  static Map<String, double> calcularPorcentajes(List<List<List<String>>> partidasFrames) {
    int totalFrames = 0;
    int strikes = 0;
    int spares = 0;
    int fallos = 0;

    for (final frames in partidasFrames) {
      for (final frame in frames) {
        if (frame.isEmpty) continue;
        
        totalFrames++;
        
        // Check if it's a strike (first throw is X)
        if (frame[0] == AppConstants.simboloStrike) {
          strikes++;
        }
        // Check if it's a spare (contains / symbol)
        else if (frame.contains(AppConstants.simboloSpare)) {
          spares++;
        }
        // Otherwise it's a fallo/open frame
        else {
          fallos++;
        }
      }
    }
    
    if (totalFrames == 0) return {"strikes": 0, "spares": 0, "fallos": 0};
    return {
      "strikes": (strikes / totalFrames) * 100,
      "spares": (spares / totalFrames) * 100,
      "fallos": (fallos / totalFrames) * 100,
    };
  }

  /// Promedio de las últimas X partidas
  static double promedioUltimasPartidas(List<Partida> partidas, int cantidad) {
    if (partidas.isEmpty) return 0;
    final ultimas = partidas.length > cantidad
        ? partidas.sublist(partidas.length - cantidad)
        : partidas;
    return ultimas.map((p) => p.total).reduce((a, b) => a + b) / ultimas.length;
  }

  /// Mejor puntuación en entrenamiento / competición
  static int mejorPuntuacionPorTipo(List<Sesion> sesiones, String tipo) {
    final partidasTipo = <Partida>[];
    for (final sesion in sesiones) {
      if (sesion.tipo == tipo) {
        partidasTipo.addAll(sesion.partidas);
      }
    }
    if (partidasTipo.isEmpty) return 0;
    return partidasTipo.map((p) => p.total).reduce((a, b) => a > b ? a : b);
  }

  /// Histograma de puntuaciones (por bin de tamaño binSize)
  static Map<String, int> calcularHistograma(List<Partida> partidas, {int binSize = AppConstants.histogramaBinSize}) {
    final histograma = <String, int>{};
    for (final p in partidas) {
      int binInicio = (p.total ~/ binSize) * binSize;
      int binFin = binInicio + binSize - 1;
      String binLabel = "$binInicio-$binFin";
      histograma[binLabel] = (histograma[binLabel] ?? 0) + 1;
    }
    return histograma;
  }

  /// Promedio móvil de tamaño windowSize
  static List<double> promedioMovil(List<Partida> partidas, int windowSize) {
    List<double> promedios = [];
    if (partidas.length < windowSize) return promedios;
    
    // Calculate moving averages for all valid windows
    for (int i = 0; i <= partidas.length - windowSize; i++) {
      final window = partidas.sublist(i, i + windowSize);
      final promedio = window.map((p) => p.total).reduce((a, b) => a + b) / window.length;
      promedios.add(promedio);
    }
    
    // If we only have 1 data point (exactly windowSize games), duplicate it
    // to ensure the chart has at least 2 points to render a line
    if (promedios.length == 1) {
      promedios.add(promedios[0]);
    }
    
    return promedios;
  }

  /// Top N mejores o peores partidas (con fecha)
  static List<Partida> topNPartidas(List<Partida> partidas, int n, {bool mejores = true}) {
    final copia = List<Partida>.from(partidas);
    copia.sort((a, b) => mejores ? b.total.compareTo(a.total) : a.total.compareTo(b.total));
    return copia.take(n).toList();
  }

  /// Filtrar sesiones por fecha (inclusive)
  static List<Sesion> filtrarSesionesPorFecha(List<Sesion> sesiones, DateTime desde, DateTime hasta) {
    return sesiones.where((s) =>
      s.fecha.isAfter(desde.subtract(const Duration(days: 1))) &&
      s.fecha.isBefore(hasta.add(const Duration(days: 1)))
    ).toList();
  }

  /// Sesión con mejor promedio (récord personal)
  static Sesion? sesionRecord(List<Sesion> sesiones) {
    if (sesiones.isEmpty) return null;
    return sesiones.reduce((a, b) =>
      promedioSesion(a) > promedioSesion(b) ? a : b
    );
  }

  /// Sesión con peor promedio
  static Sesion? sesionPeor(List<Sesion> sesiones) {
    if (sesiones.isEmpty) return null;
    return sesiones.reduce((a, b) =>
      promedioSesion(a) < promedioSesion(b) ? a : b
    );
  }

  /// Promedio de una sesión
  static double promedioSesion(Sesion sesion) {
    if (sesion.partidas.isEmpty) return 0;
    return sesion.partidas.map((p) => p.total).reduce((a, b) => a + b) / sesion.partidas.length;
  }

  /// Calcula estadísticas generales de las sesiones
  /// 
  /// Retorna un Map con las siguientes claves:
  /// - 'totalSesiones': int - Número total de sesiones
  /// - 'totalPartidas': int - Número total de partidas
  /// - 'promedio': double - Promedio de puntuación de todas las partidas
  /// - 'mejorPartida': int - Puntuación de la mejor partida
  static Map<String, dynamic> calcularEstadisticas(List<Sesion> sesiones) {
    if (sesiones.isEmpty) {
      return {
        'totalSesiones': 0,
        'totalPartidas': 0,
        'promedio': 0.0,
        'mejorPartida': 0,
      };
    }

    final todasPartidas = <Partida>[];
    for (final sesion in sesiones) {
      todasPartidas.addAll(sesion.partidas);
    }

    if (todasPartidas.isEmpty) {
      return {
        'totalSesiones': sesiones.length,
        'totalPartidas': 0,
        'promedio': 0.0,
        'mejorPartida': 0,
      };
    }

    final totalPuntos = todasPartidas.fold<int>(0, (sum, p) => sum + p.total);
    final promedio = totalPuntos / todasPartidas.length;
    final mejorPartida = todasPartidas.map((p) => p.total).reduce((a, b) => a > b ? a : b);

    return {
      'totalSesiones': sesiones.length,
      'totalPartidas': todasPartidas.length,
      'promedio': promedio,
      'mejorPartida': mejorPartida,
    };
  }

  /// Calcula la distribución de puntajes por rangos
  /// 
  /// Utiliza histograma con bins del tamaño definido en AppConstants.histogramaBinSize
  /// Retorna un Map donde las claves son rangos (ej: "100-119") y los valores
  /// son la cantidad de partidas que caen en ese rango
  static Map<String, int> calcularDistribucionPuntajes(List<Sesion> sesiones) {
    final todasPartidas = <Partida>[];
    for (final sesion in sesiones) {
      todasPartidas.addAll(sesion.partidas);
    }
    return calcularHistograma(todasPartidas);
  }

  /// Calcula estadísticas extendidas incluyendo porcentajes y consistencia
  /// 
  /// Retorna un Map con todas las estadísticas básicas más:
  /// - 'strikesPercent': double - Porcentaje de frames con strike
  /// - 'sparesPercent': double - Porcentaje de frames con spare
  /// - 'consistencia': double - Desviación estándar de las puntuaciones (menor = más consistente)
  static Map<String, dynamic> calcularEstadisticasExtendidas(List<Sesion> sesiones) {
    final estadisticasBasicas = calcularEstadisticas(sesiones);
    
    if (sesiones.isEmpty) {
      return {
        ...estadisticasBasicas,
        'strikesPercent': 0.0,
        'sparesPercent': 0.0,
        'consistencia': 0.0,
      };
    }

    final todasPartidas = <Partida>[];
    final todosFrames = <List<String>>[];
    
    for (final sesion in sesiones) {
      todasPartidas.addAll(sesion.partidas);
      for (final partida in sesion.partidas) {
        todosFrames.addAll(partida.frames);
      }
    }

    if (todasPartidas.isEmpty) {
      return {
        ...estadisticasBasicas,
        'strikesPercent': 0.0,
        'sparesPercent': 0.0,
        'consistencia': 0.0,
      };
    }

    // Calcular porcentajes de strikes y spares
    final porcentajes = calcularPorcentajes([todosFrames]);
    
    // Calcular consistencia (desviación estándar)
    final promedio = estadisticasBasicas['promedio'] as double;
    double sumaDiferenciasCuadrado = 0;
    for (final partida in todasPartidas) {
      final diferencia = partida.total - promedio;
      sumaDiferenciasCuadrado += diferencia * diferencia;
    }
    final consistencia = todasPartidas.length > 1
        ? sqrt(sumaDiferenciasCuadrado / todasPartidas.length)
        : 0.0;

    return {
      ...estadisticasBasicas,
      'strikesPercent': porcentajes['strikes'] ?? 0.0,
      'sparesPercent': porcentajes['spares'] ?? 0.0,
      'consistencia': consistencia,
    };
  }

  /// Promedio de pinos derribados en el primer tiro usando datos visuales de pines.
  /// Devuelve null si no hay partidas con datos de pines registrados.
  /// Solo se puede calcular cuando el usuario ha usado el teclado de pines.
  static double? calcularPromedioPrimerTiro(List<Partida> partidas) {
    int totalPines = 0;
    int totalTiros = 0;

    for (final partida in partidas) {
      for (int f = 0; f < AppConstants.totalFrames; f++) {
        if (f >= partida.pinesPorTiro.length) break;
        final tiro0Pines = partida.pinesPorTiro[f][0];
        if (tiro0Pines != null) {
          totalPines += tiro0Pines.length;
          totalTiros++;
        }
      }
    }

    if (totalTiros == 0) return null;
    return totalPines / totalTiros;
  }

  /// Tasa de conversión de spare (porcentaje) usando datos visuales de pines.
  /// Calcula cuántas veces el jugador derribó todos los pines restantes en el
  /// segundo tiro de los frames 1–9 cuando el primero no fue pleno (strike),
  /// más las oportunidades del frame 10 cuando aplica:
  ///  - Primer tiro del frame 10 no es pleno: el segundo tiro es la oportunidad.
  ///  - Primer tiro del frame 10 es pleno: si el segundo no lo es, el tercero es
  ///    la oportunidad de remate.
  /// Devuelve null si no hay oportunidades registradas con datos de pines.
  /// Solo se puede calcular cuando el usuario ha usado el teclado de pines.
  static double? calcularTasaConversionSpare(List<Partida> partidas) {
    int oportunidades = 0;
    int conversiones = 0;

    for (final partida in partidas) {
      // Frames 1-9 (índices 0-8)
      for (int f = 0; f < AppConstants.totalFrames - 1; f++) {
        if (f >= partida.pinesPorTiro.length) break;
        final tiro0Pines = partida.pinesPorTiro[f][0];
        final tiro1Pines = partida.pinesPorTiro[f][1];

        // Necesitamos datos de pines en ambos tiros y que el primero no sea strike
        if (tiro0Pines != null && tiro1Pines != null && tiro0Pines.length < AppConstants.maxPinesBowling) {
          oportunidades++;
          final union = <int>{...tiro0Pines, ...tiro1Pines};
          if (union.length == AppConstants.maxPinesBowling) {
            conversiones++;
          }
        }
      }

      // Frame 10 (índice 9) — incluido cuando aplica
      if (partida.pinesPorTiro.length > 9) {
        final frame10 = partida.pinesPorTiro[9];
        final tiro0 = frame10[0];
        final tiro1 = frame10[1];
        final tiro2 = frame10.length > 2 ? frame10[2] : null;

        // Caso 1: primer tiro no es pleno → tiro1 es la oportunidad de remate
        if (tiro0 != null && tiro1 != null && tiro0.length < AppConstants.maxPinesBowling) {
          oportunidades++;
          final union = <int>{...tiro0, ...tiro1};
          if (union.length == AppConstants.maxPinesBowling) conversiones++;
        }

        // Caso 2: primer tiro es pleno y segundo no lo es → tiro2 es la oportunidad
        if (tiro0 != null && tiro0.length == AppConstants.maxPinesBowling &&
            tiro1 != null && tiro2 != null && tiro1.length < AppConstants.maxPinesBowling) {
          oportunidades++;
          final union = <int>{...tiro1, ...tiro2};
          if (union.length == AppConstants.maxPinesBowling) conversiones++;
        }
      }
    }

    if (oportunidades == 0) return null;
    return (conversiones / oportunidades) * 100;
  }

  /// Estadísticas de conversión de spare desglosadas por los pines que quedaron en pie
  /// ("dejes") después del primer tiro.
  ///
  /// Incluye el frame 10 cuando aplica (igual que [calcularTasaConversionSpare]).
  ///
  /// Devuelve un mapa donde:
  /// - Clave: lista de pines restantes en orden ascendente, unidos por coma
  ///   (p. ej. "7" para el pin 7 solo, "7,10" para el split 7-10).
  /// - Valor: lista de dos enteros [oportunidades, conversiones].
  ///
  /// Devuelve un mapa vacío si no hay datos de pines disponibles.
  static Map<String, List<int>> calcularConversionSparePorPin(List<Partida> partidas) {
    final resultado = <String, List<int>>{};

    void addOportunidad(List<int> pinesRestantes, bool convertido) {
      final key = (List<int>.from(pinesRestantes)..sort()).join(',');
      resultado.putIfAbsent(key, () => [0, 0]);
      resultado[key]![0]++;
      if (convertido) resultado[key]![1]++;
    }

    final allPinsSet = Set<int>.from(List.generate(AppConstants.maxPinesBowling, (i) => i + 1));

    for (final partida in partidas) {
      // Frames 1-9 (índices 0-8)
      for (int f = 0; f < AppConstants.totalFrames - 1; f++) {
        if (f >= partida.pinesPorTiro.length) break;
        final tiro0Pines = partida.pinesPorTiro[f][0];
        final tiro1Pines = partida.pinesPorTiro[f][1];

        if (tiro0Pines != null && tiro1Pines != null && tiro0Pines.length < AppConstants.maxPinesBowling) {
          final pinesRestantes = (allPinsSet.difference(tiro0Pines.toSet()).toList()..sort());
          if (pinesRestantes.isNotEmpty) {
            final union = <int>{...tiro0Pines, ...tiro1Pines};
            addOportunidad(pinesRestantes, union.length == AppConstants.maxPinesBowling);
          }
        }
      }

      // Frame 10 (índice 9) — incluido cuando aplica
      if (partida.pinesPorTiro.length > 9) {
        final frame10 = partida.pinesPorTiro[9];
        final tiro0 = frame10[0];
        final tiro1 = frame10[1];
        final tiro2 = frame10.length > 2 ? frame10[2] : null;

        // Caso 1: primer tiro no es pleno
        if (tiro0 != null && tiro1 != null && tiro0.length < AppConstants.maxPinesBowling) {
          final pinesRestantes = (allPinsSet.difference(tiro0.toSet()).toList()..sort());
          if (pinesRestantes.isNotEmpty) {
            final union = <int>{...tiro0, ...tiro1};
            addOportunidad(pinesRestantes, union.length == AppConstants.maxPinesBowling);
          }
        }

        // Caso 2: primer tiro es pleno y segundo no lo es
        if (tiro0 != null && tiro0.length == AppConstants.maxPinesBowling &&
            tiro1 != null && tiro2 != null && tiro1.length < AppConstants.maxPinesBowling) {
          final pinesRestantes = (allPinsSet.difference(tiro1.toSet()).toList()..sort());
          if (pinesRestantes.isNotEmpty) {
            final union = <int>{...tiro1, ...tiro2};
            addOportunidad(pinesRestantes, union.length == AppConstants.maxPinesBowling);
          }
        }
      }
    }

    return resultado;
  }
}
