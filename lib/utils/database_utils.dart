import 'package:hive/hive.dart';
import '../models/sesion.dart';
import 'app_constants.dart';

Future<List<Sesion>> cargarSesionesDesdeHive() async {
  final box = Hive.box<Sesion>(AppConstants.boxSesiones);
  return box.values.toList();
}
