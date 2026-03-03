# Política de Privacidad de Bolómetro

**Última actualización:** 03 de marzo de 2026  
**Versión de la aplicación:** 1.1.5

---

## 1. Introducción

Bienvenido a **Bolómetro**, la aplicación para jugadores de bolos que permite registrar, analizar y mejorar el rendimiento en cada sesión y partida. Esta Política de Privacidad describe cómo recopilamos, usamos, almacenamos y protegemos tu información personal cuando usas nuestra aplicación.

Al usar Bolómetro, aceptas las prácticas descritas en esta política. Si no estás de acuerdo con alguno de los términos aquí expuestos, te pedimos que no uses la aplicación.

---

## 2. Información que Recopilamos

### 2.1 Información que Tú Proporcionas

Cuando usas Bolómetro, puedes proporcionarnos voluntariamente la siguiente información:

- **Datos de perfil:** Nombre, dirección de correo electrónico, club de bolos, mano dominante, fecha de nacimiento, biografía e imagen de avatar.
- **Datos de sesiones y partidas:** Registros de sesiones de entrenamiento y competición, incluyendo fecha, lugar, tipo de sesión, puntuaciones por frame, notas y pines derribados por tiro.

### 2.2 Información Recopilada Automáticamente

La aplicación recopila automáticamente cierta información para mejorar la experiencia del usuario:

- **Datos de autenticación:** Identificador único de usuario (UID) de Firebase Authentication, vinculado a tu cuenta de Google.
- **Datos de uso y analíticas:** A través de Firebase Analytics, registramos eventos de uso de la aplicación, como vistas de pantallas, creación o eliminación de sesiones y partidas, cambios de configuración, y uso de funcionalidades de estadísticas y gráficos. Estos datos son anónimos y no incluyen información personal identificable (PII).
- **Notificaciones push:** Utilizamos Firebase Cloud Messaging (FCM) para enviar notificaciones push. Se puede recopilar un token de dispositivo con el fin de entregar dichas notificaciones.
- **Información técnica del dispositivo:** El sistema operativo y la versión de la aplicación pueden registrarse con fines de diagnóstico.

### 2.3 Datos de la Red Social (Sistema de Amigos)

Si utilizas las funcionalidades sociales de la aplicación, recopilamos:

- Solicitudes de amistad enviadas y recibidas.
- Lista de amigos asociada a tu cuenta.

---

## 3. Cómo Usamos tu Información

Usamos la información recopilada para:

- **Proporcionar y mejorar la app:** Guardar tus sesiones y partidas, calcular estadísticas de rendimiento y mostrar tu historial.
- **Sincronización en la nube:** Si inicias sesión con Google, sincronizamos tus datos entre dispositivos mediante Firebase Firestore para que puedas acceder a tu información desde cualquier lugar.
- **Autenticación:** Verificar tu identidad de forma segura mediante Firebase Authentication y Google Sign-In.
- **Notificaciones:** Enviarte notificaciones relevantes sobre la aplicación (si has otorgado permiso).
- **Análisis y mejora:** Entender cómo se usa la aplicación para mejorar funcionalidades y la experiencia del usuario mediante Firebase Analytics.
- **Funcionalidades sociales:** Gestionar solicitudes de amistad y el sistema de amigos.

---

## 4. Almacenamiento de Datos

### 4.1 Almacenamiento Local

Los datos se guardan localmente en tu dispositivo utilizando **Hive**, una base de datos local. Esto permite que la aplicación funcione sin conexión a Internet.

### 4.2 Almacenamiento en la Nube

Si inicias sesión con tu cuenta de Google, tus datos se almacenan en **Firebase Firestore** (Google Cloud), lo que permite sincronizarlos entre dispositivos. Solo tú puedes leer y escribir en tu propia información; las reglas de seguridad de Firestore garantizan que ningún otro usuario pueda acceder a tus datos.

### 4.3 Retención de Datos

- Tus datos se conservan mientras mantengas tu cuenta activa.
- Si eliminas tu cuenta, tus datos en Firestore serán eliminados. Los datos locales en el dispositivo permanecerán hasta que desinstales la aplicación o los elimines manualmente.

---

## 5. Compartición de Datos con Terceros

No vendemos ni alquilamos tu información personal a terceros. Sin embargo, utilizamos los siguientes servicios de terceros que pueden tener acceso a ciertos datos:

| Servicio | Proveedor | Finalidad |
|---|---|---|
| Firebase Authentication | Google LLC | Autenticación de usuarios |
| Firebase Firestore | Google LLC | Almacenamiento en la nube |
| Firebase Analytics | Google LLC | Análisis de uso anónimo |
| Firebase Cloud Messaging | Google LLC | Notificaciones push |
| Google Sign-In | Google LLC | Inicio de sesión con Google |

Todos estos servicios son proporcionados por **Google LLC** y están sujetos a la [Política de Privacidad de Google](https://policies.google.com/privacy).

---

## 6. Seguridad de los Datos

Tomamos medidas razonables para proteger tu información:

- **Autenticación segura:** Usamos Firebase Authentication; las credenciales de Google nunca se almacenan localmente en la app.
- **Reglas de seguridad de Firestore:** Solo el propietario de los datos puede acceder a ellos. Ningún otro usuario puede leer o modificar tu información.
- **Transmisión cifrada:** Toda comunicación con Firebase se realiza a través de conexiones cifradas (HTTPS/TLS).

Sin embargo, ningún sistema de seguridad es completamente infalible. Te recomendamos que mantengas seguras tus credenciales de Google.

---

## 7. Tus Derechos

Tienes los siguientes derechos respecto a tus datos personales:

- **Acceso:** Puedes consultar todos tus datos directamente en la aplicación.
- **Rectificación:** Puedes editar tu perfil y tus registros de sesiones en cualquier momento desde la app.
- **Eliminación:** Puedes eliminar tus sesiones, partidas y datos de perfil desde la propia aplicación. Para eliminar completamente tu cuenta y todos los datos asociados en la nube, contáctanos (ver sección 10).
- **Portabilidad:** Puedes exportar tus datos usando la funcionalidad de compartir disponible en la app.
- **Opt-out de Analytics:** Puedes deshabilitar la recopilación de analíticas desde los ajustes de tu dispositivo o mediante la opción correspondiente en la aplicación (si está disponible).

---

## 8. Privacidad de Menores

Bolómetro no está dirigida a menores de 13 años. No recopilamos intencionalmente información personal de niños menores de 13 años. Si eres padre o tutor y crees que tu hijo ha proporcionado información personal a través de la app, contáctanos para que podamos tomar las medidas oportunas.

---

## 9. Cambios en esta Política de Privacidad

Podemos actualizar esta Política de Privacidad ocasionalmente para reflejar cambios en la aplicación o en la legislación aplicable. Cuando lo hagamos, actualizaremos la fecha indicada al comienzo del documento. Te recomendamos revisar esta política periódicamente. El uso continuado de la aplicación tras la publicación de cambios constituye tu aceptación de dichos cambios.

---

## 10. Contacto

Si tienes preguntas, comentarios o solicitudes relacionadas con esta Política de Privacidad o con el tratamiento de tus datos personales, puedes contactarnos a través del repositorio oficial del proyecto:

- **Repositorio:** [https://github.com/ivansanare93/Bolometro](https://github.com/ivansanare93/Bolometro)

---

## 11. Legislación Aplicable

Esta Política de Privacidad se rige por la legislación española y europea en materia de protección de datos, incluyendo el **Reglamento General de Protección de Datos (RGPD/GDPR)** de la Unión Europea y la **Ley Orgánica 3/2018, de Protección de Datos Personales y garantía de los derechos digitales (LOPDGDD)** de España.

---

*Esta política de privacidad ha sido elaborada para la aplicación **Bolómetro**, desarrollada por ivansanare93.*
