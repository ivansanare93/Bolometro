# Hive TypeAdapter Registry

Este documento mantiene un registro centralizado de todos los `typeId` asignados a los TypeAdapters de Hive en la aplicación Bolómetro. Es crucial mantener este documento actualizado para evitar conflictos de `typeId`.

## ⚠️ Reglas Importantes

1. **Cada typeId debe ser único** - No se pueden duplicar valores de typeId
2. **Los typeId no deben cambiar** - Una vez asignado, no cambiar el typeId de un modelo que ya está en producción, ya que esto causará problemas con los datos existentes
3. **Verificar antes de registrar** - Siempre usar `Hive.isAdapterRegistered(typeId)` antes de llamar a `Hive.registerAdapter()`
4. **Actualizar este documento** - Al agregar nuevos modelos Hive, actualizar esta tabla inmediatamente

## Registro de TypeIDs Asignados

| TypeID | Modelo / Enum | Archivo | Descripción |
|--------|---------------|---------|-------------|
| 0 | `Partida` | `lib/models/partida.dart` | Representa una partida de bolos individual |
| 1 | `Sesion` | `lib/models/sesion.dart` | Representa una sesión de entrenamiento con múltiples partidas |
| 2 | `Nota` | `lib/models/nota.dart` | Nota del cuaderno de apuntes |
| 10 | `PerfilUsuario` | `lib/models/perfil_usuario.dart` | Perfil del usuario de la aplicación |
| 11 | `Achievement` | `lib/models/achievement.dart` | Logro del sistema de gamificación |
| 13 | `AchievementType` | `lib/models/achievement.dart` | Enum de tipos de logros |
| 14 | `AchievementRarity` | `lib/models/achievement.dart` | Enum de rareza de logros |
| 15 | `Friend` | `lib/models/friend.dart` | Amigo en el sistema social |
| 16 | `FriendRequest` | `lib/models/friend_request.dart` | Solicitud de amistad |
| 17 | `UserProgress` | `lib/models/user_progress.dart` | Progreso del usuario (XP, nivel) |

## TypeIDs Disponibles

Los siguientes typeId están disponibles para nuevos modelos:
- 3-9 (rango bajo)
- 12 (individual)
- 18+ (rango alto)

## Historial de Cambios

### 2026-01-29 - Resolución de Conflictos PR #43

**Problema:** Se encontraron conflictos de typeId que causaban el error `HiveError: There is already a TypeAdapter for typeId 11`

**Conflictos Identificados:**
- typeId 11: `Achievement` y `Friend` (CONFLICTO)
- typeId 12: `FriendRequest` y `UserProgress` (CONFLICTO)

**Solución Aplicada:**
- `Friend`: typeId cambiado de 11 → 15
- `FriendRequest`: typeId cambiado de 12 → 16
- `UserProgress`: typeId cambiado de 12 → 17

**Archivos Modificados:**
- `lib/models/friend.dart`
- `lib/models/friend.g.dart`
- `lib/models/friend_request.dart`
- `lib/models/friend_request.g.dart`
- `lib/models/user_progress.dart`
- `lib/models/user_progress.g.dart`
- `lib/main.dart` (agregado chequeo de `Hive.isAdapterRegistered()`)

## Cómo Agregar un Nuevo Modelo Hive

1. **Seleccionar typeId:** Consultar la tabla anterior y seleccionar un typeId no utilizado
2. **Anotar en la clase:** Agregar `@HiveType(typeId: X)` a tu modelo
3. **Generar adapter:** Ejecutar `flutter pub run build_runner build --delete-conflicting-outputs`
4. **Registrar en main.dart:** Agregar el registro con verificación:
   ```dart
   if (!Hive.isAdapterRegistered(X)) {
     Hive.registerAdapter(TuModeloAdapter());
   }
   ```
5. **Actualizar este documento:** Agregar el nuevo typeId a la tabla de registro

## Referencias

- [Documentación oficial de Hive](https://docs.hivedb.dev/)
- [Hive TypeAdapter](https://docs.hivedb.dev/#/custom-objects/type_adapters)
