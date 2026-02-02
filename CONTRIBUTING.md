# Guía de Contribución

¡Gracias por tu interés en contribuir a Bolómetro! Esta guía te ayudará a empezar.

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [¿Cómo Puedo Contribuir?](#cómo-puedo-contribuir)
- [Configuración del Entorno](#configuración-del-entorno)
- [Proceso de Desarrollo](#proceso-de-desarrollo)
- [Guías de Estilo](#guías-de-estilo)
- [Proceso de Pull Request](#proceso-de-pull-request)

## Código de Conducta

Este proyecto y todos los participantes están gobernados por un código de conducta. Al participar, se espera que mantengas este código. Por favor, reporta comportamientos inaceptables al mantenedor del proyecto.

## ¿Cómo Puedo Contribuir?

### Reportar Bugs

Antes de crear un reporte de bug, por favor:
1. Verifica que el bug no haya sido reportado previamente en [Issues](https://github.com/ivansanare93/Bolometro/issues)
2. Si encuentras un issue abierto similar, añade un comentario en lugar de abrir uno nuevo

**Para crear un buen reporte de bug:**
- Usa un título claro y descriptivo
- Describe los pasos exactos para reproducir el problema
- Proporciona ejemplos específicos
- Describe el comportamiento observado y el esperado
- Incluye capturas de pantalla si es posible
- Especifica la versión de Flutter, sistema operativo y dispositivo

### Sugerir Mejoras

Para sugerir mejoras:
1. Abre un issue con la etiqueta `enhancement`
2. Describe la mejora en detalle
3. Explica por qué esta mejora sería útil
4. Si es posible, proporciona ejemplos de implementación

### Contribuir con Código

1. **Fork** el repositorio
2. **Clona** tu fork
3. **Crea una rama** para tu feature: `git checkout -b feature/nombre-descriptivo`
4. **Realiza tus cambios** siguiendo las guías de estilo
5. **Añade tests** para tu código
6. **Verifica** que todos los tests pasen
7. **Commit** tus cambios con mensajes descriptivos
8. **Push** a tu fork
9. **Abre un Pull Request**

## Configuración del Entorno

### Requisitos Previos

- Flutter SDK (última versión estable)
- Dart SDK (incluido con Flutter)
- Android Studio / Xcode (para desarrollo móvil)
- Git

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/ivansanare93/Bolometro.git
cd Bolometro

# Instalar dependencias
flutter pub get

# Generar archivos necesarios
flutter pub run build_runner build --delete-conflicting-outputs

# Ejecutar en modo debug
flutter run
```

## Proceso de Desarrollo

### 1. Antes de Empezar

```bash
# Asegúrate de estar en la última versión
git checkout main
git pull origin main

# Crea una nueva rama
git checkout -b feature/mi-feature
```

### 2. Durante el Desarrollo

```bash
# Ejecutar tests regularmente
flutter test

# Verificar análisis de código
flutter analyze

# Formatear código
dart format .
```

### 3. Antes de Hacer Commit

```bash
# Ejecutar todos los tests
flutter test

# Verificar que no hay errores de análisis
flutter analyze

# Asegurarse de que el formato es correcto
dart format . --set-exit-if-changed

# Si todo está bien, hacer commit
git add .
git commit -m "feat: descripción clara del cambio"
```

## Guías de Estilo

### Estilo de Código Dart/Flutter

- Sigue la [Guía de Estilo de Dart](https://dart.dev/guides/language/effective-dart/style)
- Usa `dart format` para formatear automáticamente
- Limita las líneas a 80 caracteres cuando sea posible
- Usa nombres descriptivos para variables y funciones

**Ejemplos:**

```dart
// ✅ Bueno
final String nombreUsuario = 'Juan';
void guardarSesion(Sesion sesion) { ... }

// ❌ Malo
final String nu = 'Juan';
void gS(Sesion s) { ... }
```

### Mensajes de Commit

Sigue el formato [Conventional Commits](https://www.conventionalcommits.org/):

```
tipo(alcance): descripción corta

[cuerpo opcional]

[pie opcional]
```

**Tipos:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Formato de código (no afecta funcionalidad)
- `refactor`: Refactorización de código
- `test`: Añadir o modificar tests
- `chore`: Tareas de mantenimiento

**Ejemplos:**
```bash
git commit -m "feat(auth): añadir autenticación con Google"
git commit -m "fix(stats): corregir cálculo de promedio"
git commit -m "docs(readme): actualizar instrucciones de instalación"
```

### Documentación

- Documenta funciones públicas con comentarios dartdoc (`///`)
- Incluye ejemplos de uso cuando sea útil
- Mantén la documentación actualizada con los cambios

```dart
/// Calcula el promedio de puntuación de una lista de partidas.
///
/// Retorna 0.0 si la lista está vacía.
///
/// Ejemplo:
/// ```dart
/// final partidas = [Partida(total: 150), Partida(total: 180)];
/// final promedio = calcularPromedio(partidas); // 165.0
/// ```
double calcularPromedio(List<Partida> partidas) {
  if (partidas.isEmpty) return 0.0;
  final suma = partidas.fold<int>(0, (sum, p) => sum + p.total);
  return suma / partidas.length;
}
```

### Testing

- Escribe tests para toda nueva funcionalidad
- Mantén una cobertura de tests > 80%
- Usa nombres descriptivos para tests

```dart
// ✅ Bueno
test('calcularPromedio retorna 0.0 cuando la lista está vacía', () {
  expect(calcularPromedio([]), 0.0);
});

// ❌ Malo
test('test1', () {
  expect(calcularPromedio([]), 0.0);
});
```

## Proceso de Pull Request

### Antes de Crear el PR

- [ ] Todos los tests pasan (`flutter test`)
- [ ] El código está formateado (`dart format .`)
- [ ] No hay errores de análisis (`flutter analyze`)
- [ ] La documentación está actualizada
- [ ] Los commits siguen el formato Conventional Commits

### Crear el Pull Request

1. **Título:** Usa un título claro y descriptivo
2. **Descripción:** Incluye:
   - Qué cambios se hicieron
   - Por qué se hicieron
   - Cómo probar los cambios
   - Referencias a issues relacionados
3. **Capturas de pantalla:** Si hay cambios visuales
4. **Checklist:** Completa todos los items del checklist

**Template de PR:**

```markdown
## Descripción
[Describe los cambios realizados]

## Motivación
[Explica por qué se hicieron estos cambios]

## Tipo de Cambio
- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Documentación

## ¿Cómo se ha probado?
[Describe las pruebas realizadas]

## Checklist
- [ ] Mi código sigue el estilo del proyecto
- [ ] He realizado auto-revisión de mi código
- [ ] He comentado mi código en áreas difíciles
- [ ] He actualizado la documentación
- [ ] Mis cambios no generan nuevos warnings
- [ ] He añadido tests que prueban mi corrección/funcionalidad
- [ ] Todos los tests unitarios pasan localmente
- [ ] He verificado que no hay conflictos con main

## Capturas de pantalla
[Si aplica, añade capturas de pantalla]

## Issues relacionados
Closes #[número del issue]
```

### Durante la Revisión

- Responde a todos los comentarios
- Realiza los cambios solicitados
- Mantén la conversación profesional y constructiva
- Haz push de los cambios a la misma rama

### Después de la Aprobación

El mantenedor del proyecto se encargará de:
- Fusionar el PR
- Actualizar el CHANGELOG.md
- Crear tags de versión si es necesario

## Recursos Útiles

- [Documentación de Flutter](https://docs.flutter.dev)
- [Documentación de Dart](https://dart.dev/guides)
- [Firebase para Flutter](https://firebase.google.com/docs/flutter/setup)
- [Guía de Estilo de Dart](https://dart.dev/guides/language/effective-dart)

## Preguntas

Si tienes preguntas sobre cómo contribuir, por favor:
1. Revisa la documentación en la carpeta `docs/`
2. Busca en issues cerrados por respuestas similares
3. Abre un nuevo issue con la etiqueta `question`

## Agradecimientos

¡Gracias por contribuir a Bolómetro! Cada contribución, grande o pequeña, es valiosa y apreciada.

---

**Última actualización:** 2026-02-02
