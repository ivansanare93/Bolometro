# 🎳 Bolómetro

<p align="center">
  <img src="assets/logo_bolometro.png" alt="Bolómetro Logo" width="180"/>
</p>

<p align="center">
  <strong>Registra tus partidas, analiza tu evolución y mejora tu juego de bolos.</strong>
</p>

---

## 📌 Estado actual

**Bolómetro** es una app Flutter multiplataforma centrada en el seguimiento y mejora del rendimiento en bolos.

### Funcionalidades principales implementadas

- Registro de partidas y sesiones completas.
- Estadísticas y visualizaciones de rendimiento.
- Sistema de logros y nivel (gamificación).
- Sistema social: amigos, solicitudes y rankings.
- Perfil de usuario y personalización básica.
- **Mis Bolas**: inventario de equipación (bolas de bolos), asignación de bola por partida, estadísticas por bola y registro de mantenimiento.
- Modo offline con almacenamiento local (Hive).
- Sincronización cloud con Firebase (Google Sign-In + Firestore).
- Soporte multi-plataforma: Android, iOS, Web, Windows, macOS y Linux.

---

## 🎳 Mis Bolas (equipación)

Bolómetro incluye un inventario básico de equipación centrado en las bolas de
bolos y su impacto en el rendimiento.

### Cómo usarlo

1. Desde la pantalla principal, entra en **"Mis Bolas"**.
2. Pulsa el botón **+** para agregar una bola (nombre, peso, marca, coverstock,
   acabado, fecha de compra y notas son opcionales salvo nombre y peso).
3. Al registrar o editar una partida, usa el campo **"Bola utilizada"** para
   asignar una de tus bolas activas, o deja **"Sin especificar"**.
4. Entra en el detalle de una bola para ver sus **estadísticas** (partidas
   jugadas, promedio, mejor partida, % de strikes y tendencia reciente) y su
   **historial de mantenimiento** (limpieza, resurfacing, extracción de
   aceite u otro).
5. Puedes **archivar** una bola que ya no uses (no se borra: se conserva su
   histórico) o **reactivarla** más adelante.

### Limitaciones del MVP

- El inventario de equipación (bolas y mantenimientos) se guarda únicamente
  de forma local (Hive) y todavía no se sincroniza con Firestore/la nube.
- Solo se admite un tipo de equipación (bolas); no hay soporte para zapatos,
  muñequeras u otros accesorios.
- La "tendencia" de rendimiento es un cálculo simple (comparación de
  promedios recientes vs. anteriores), no un modelo predictivo.
- No hay recordatorios automáticos (notificaciones) de mantenimiento
  periódico; el registro es manual.

---

## 🧱 Stack tecnológico

- **Framework:** Flutter
- **Lenguaje:** Dart
- **Persistencia local:** Hive
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, FCM)
- **Estado:** Provider
- **Gráficas:** FL Chart

---

## 🚀 Arranque rápido

```bash
git clone https://github.com/ivansanare93/Bolometro.git
cd Bolometro
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 📚 Documentación técnica

La documentación detallada está en [`docs/`](docs/).

Documentos recomendados para empezar:

- [`docs/GAMIFICATION.md`](docs/GAMIFICATION.md)
- [`docs/FRIENDS_SYSTEM.md`](docs/FRIENDS_SYSTEM.md)
- [`docs/ANALYTICS.md`](docs/ANALYTICS.md)
- [`docs/TESTING.md`](docs/TESTING.md)
- [`docs/CICD.md`](docs/CICD.md)

> Nota: se ha simplificado este README para evitar duplicidad y mantener aquí solo información de alto nivel.

---

## 🗺️ Siguientes pasos (post-temporadas)

Una vez cerrada la implementación total de temporadas, el roadmap propuesto es:

1. **Integración total de temporadas en estadísticas y rankings**
   - Filtros por temporada en todas las vistas clave.
   - Comparativas entre temporadas.
   - Métricas históricas por temporada.

2. **Mejoras de experiencia de usuario**
   - Flujos de registro más rápidos.
   - Mejor feedback visual en acciones clave.
   - Revisión de estados vacíos y mensajes de error.

3. **Calidad técnica y mantenibilidad**
   - Refuerzo de pruebas unitarias/integración en módulos de temporada.
   - Limpieza incremental de documentación técnica obsoleta.
   - Revisión de rendimiento en consultas y cálculos agregados.

4. **Evolución social y competitiva**
   - Más tipos de ranking vinculados a temporadas.
   - Retos periódicos por temporada (futuro).

---

## 🧠 Idea futura: “Entrenador”

Se propone incorporar un módulo de **Entrenador** que ofrezca tips accionables y personalizados, por ejemplo:

- Recomendaciones según tus patrones (spares fallados, consistencia, frames críticos).
- Sugerencias de objetivos semanales (p. ej. subir % de spare en X puntos).
- Alertas inteligentes de progreso/retroceso.
- Resúmenes tipo “qué mejorar en tu próxima sesión”.

### Primera versión (MVP sugerido)

- Reglas simples basadas en métricas ya existentes.
- Tips en lenguaje natural dentro de la pantalla de estadísticas.
- Sistema de prioridad de recomendaciones (máx. 2–3 tips por sesión).

---

## 🤝 Contribución

Si quieres colaborar:

1. Crea una rama de trabajo.
2. Implementa cambios con pruebas.
3. Abre un Pull Request con contexto y capturas si aplica.

---

## 👨‍💻 Autor

**Iván Sanare**  
GitHub: [@ivansanare93](https://github.com/ivansanare93)
