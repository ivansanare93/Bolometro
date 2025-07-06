import 'package:hive/hive.dart';
import '../models/sesion.dart';

Future<List<Sesion>> cargarSesionesDesdeHive() async {
  final box = Hive.box<Sesion>('sesiones');
  return box.values.toList();
}
