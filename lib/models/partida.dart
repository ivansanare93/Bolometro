class Partida {
  final DateTime fecha;
  final String lugar;
  final String tipo; // 'Entrenamiento' o 'Competición'
  final List<List<int>> frames; // Cada frame: [tiro1, tiro2, (opcional: tiroExtra)]
  final String? notas;
  final int total;

  Partida({
    required this.fecha,
    required this.lugar,
    required this.tipo,
    required this.frames,
    this.notas,
    required this.total,
  });

  // Calcular el promedio de pins por tirada (opcional)
  double get promedioPorTirada {
    final totalTiradas = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.length,
    );
    return totalTiradas == 0 ? 0 : total / totalTiradas;
  }

  // Para guardar/cargar en JSON (opcional para persistencia)
  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'lugar': lugar,
        'tipo': tipo,
        'frames': frames,
        'notas': notas,
        'total': total,
      };

  factory Partida.fromJson(Map<String, dynamic> json) => Partida(
        fecha: DateTime.parse(json['fecha']),
        lugar: json['lugar'],
        tipo: json['tipo'],
        frames: List<List<int>>.from(json['frames'].map<List<int>>(
            (f) => List<int>.from(f.map((x) => x)))),
        notas: json['notas'],
        total: json['total'],
      );
}
