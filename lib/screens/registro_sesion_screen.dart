import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
import 'home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'editar_partida_screen.dart';
import 'package:test_bolos/widgets/marcador_bolos.dart';

class RegistroSesionScreen extends StatefulWidget {
  const RegistroSesionScreen({super.key});

  @override
  State<RegistroSesionScreen> createState() => _RegistroSesionScreenState();
}

class _RegistroSesionScreenState extends State<RegistroSesionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fecha = DateTime.now();
  String _lugar = '';
  String _tipo = 'Entrenamiento';
  String? _notas;

  final List<Partida> _partidas = [];

  void _guardarSesion() async {
    if (_formKey.currentState!.validate() && _partidas.isNotEmpty) {
      final nuevaSesion = Sesion(
        fecha: _fecha,
        lugar: _lugar,
        tipo: _tipo,
        notas: _notas,
        partidas: _partidas,
      );

      final box = Hive.box<Sesion>('sesiones');
      await box.add(nuevaSesion);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Sesión guardada con éxito 🎉'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los datos y añade al menos una partida.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoNuevaPartida() async {
    List<List<String>> framesText = List.generate(10, (_) => ['', '', '']);
    String? notas;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            final frames = interpretarFrames(framesText);
            final puntuacionActual = calcularPuntuacionPartida(frames);
            final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
            final buenaRacha = esBuenaRacha(frames);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          FaIcon(FontAwesomeIcons.bowlingBall, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Nueva partida',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarcadorBolos(
                        frames: framesText,
                        puntuaciones: calcularPuntuacionPorFrame(framesText, permitirNulos: true),
                        frameActivo: framesText.indexWhere(
                          (f) => tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) == TipoFrame.incompleto,
                        ),
                        onChanged: (frame, tiro, valor) {
                          setStateDialog(() {
                            framesText[frame][tiro] = valor;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Puntuación actual: $puntuacionActual'),
                      Text('Máximo posible: $puntuacionMaxima', style: const TextStyle(color: Colors.grey)),
                      if (buenaRacha)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.whatshot, color: Colors.orange),
                              SizedBox(width: 6),
                              Text('¡Vas en racha!', style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (value) => notas = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Añadir'),
                            onPressed: () {
                              final frames = interpretarFrames(framesText);
                              final tieneTiros = frames.any((f) => f.any((t) => t.isNotEmpty));
                              if (!tieneTiros) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Debes ingresar al menos un tiro válido.'),
                                  ),
                                );
                                return;
                              }
                              final total = calcularPuntuacionPartida(frames);
                              final nuevaPartida = Partida(
                                fecha: DateTime.now(),
                                lugar: _lugar,
                                tipo: _tipo,
                                frames: frames,
                                notas: notas,
                                total: total,
                              );
                              setState(() => _partidas.add(nuevaPartida));
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${_fecha.toLocal().toString().split(" ")[0]}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _fecha = picked);
                },
                child: const Text('Seleccionar fecha'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Lugar'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                onChanged: (value) => _lugar = value,
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                items: ['Entrenamiento', 'Competición']
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) => setState(() => _tipo = value ?? 'Entrenamiento'),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                onChanged: (value) => _notas = value,
              ),
              const SizedBox(height: 16),
              const Text('Partidas añadidas:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._partidas.map(
                (p) => ListTile(
                  title: Text('Puntaje: ${p.total}'),
                  subtitle: Text('Frames: ${p.frames.length} | ${p.fecha.toLocal().toString().split(" ")[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final index = _partidas.indexOf(p);
                          final partidaEditada = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarPartidaScreen(
                                partida: p,
                                onGuardar: (actualizada) {
                                  setState(() {
                                    _partidas[index] = actualizada;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _partidas.remove(p)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoNuevaPartida,
                icon: const Icon(Icons.add),
                label: const Text('Añadir partida'),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarSesion,
                  child: const Text('Guardar sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        tooltip: 'Inicio',
        child: const Icon(Icons.home),
      ),
    );
  }
}
