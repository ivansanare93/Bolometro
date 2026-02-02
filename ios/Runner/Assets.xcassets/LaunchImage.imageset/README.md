# Launch Screen Assets

## Personalización

Puedes personalizar la pantalla de lanzamiento con tus propios recursos reemplazando los archivos de imagen en este directorio.

También puedes hacerlo abriendo el proyecto Xcode de tu proyecto Flutter con `open ios/Runner.xcworkspace`, seleccionando `Runner/Assets.xcassets` en el Navegador de Proyecto y arrastrando las imágenes deseadas.

## Especificaciones de Imágenes

### Tamaños Requeridos

Para una pantalla de lanzamiento óptima en todos los dispositivos iOS, se recomiendan las siguientes resoluciones:

- **LaunchImage.png** (1x): 320 x 480 px
- **LaunchImage@2x.png** (2x): 640 x 960 px  
- **LaunchImage@3x.png** (3x): 1242 x 2208 px

### Formato

- **Formato:** PNG con transparencia (alpha)
- **Espacio de color:** sRGB
- **Resolución:** 72 DPI mínimo

## Recomendaciones

1. **Diseño simple:** Mantén el diseño simple y limpio
2. **Sin texto:** Evita texto que pueda requerir localización
3. **Centrado:** Elementos importantes centrados para diferentes tamaños de pantalla
4. **Logo:** Usa el logo de la aplicación para branding consistente

## Más Información

Para más detalles sobre las pantallas de lanzamiento en iOS, consulta:
- [Documentación oficial de Apple](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/launch-screen/)
- [Guía de Flutter para iOS](https://docs.flutter.dev/deployment/ios)