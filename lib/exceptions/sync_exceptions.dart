/// Excepciones personalizadas para sincronización de datos
/// 
/// Estas excepciones permiten un manejo más preciso de errores
/// en lugar de depender de detección basada en strings.

/// Excepción lanzada cuando hay problemas de conectividad de red
class NetworkException implements Exception {
  final String message;
  
  NetworkException([this.message = 'Error de red']);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Excepción lanzada cuando hay problemas de permisos en Firestore
class PermissionException implements Exception {
  final String message;
  
  PermissionException([this.message = 'Error de permisos']);
  
  @override
  String toString() => 'PermissionException: $message';
}

/// Excepción lanzada cuando el usuario no está autenticado
class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException([this.message = 'Usuario no autenticado']);
  
  @override
  String toString() => 'AuthenticationException: $message';
}

/// Excepción lanzada cuando se intenta sincronizar sin conexión
class OfflineModeException implements Exception {
  final String message;
  
  OfflineModeException([this.message = 'Operación no disponible en modo offline']);
  
  @override
  String toString() => 'OfflineModeException: $message';
}

/// Excepción lanzada cuando falla la sincronización de datos
class SyncException implements Exception {
  final String message;
  final Exception? cause;
  
  SyncException(this.message, [this.cause]);
  
  @override
  String toString() => 'SyncException: $message${cause != null ? ' (Causa: $cause)' : ''}';
}
