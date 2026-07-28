# Aperio

Cada apertura cuenta una historia. App de iOS para enmarcar fotos con sus datos técnicos (EXIF), nativa en SwiftUI.

## Qué es esto

Este repositorio contiene el código fuente en Swift, pero **no incluye el archivo `.xcodeproj`**. Se genera localmente con [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir de `project.yml`. Esto evita subir un archivo binario/XML propenso a conflictos de merge, y mantiene la configuración del proyecto legible y versionada como texto plano.

Requiere una Mac con Xcode 15 o superior (SwiftUI no se puede compilar ni previsualizar fuera de macOS).

## Setup

```bash
# 1. Instalar XcodeGen (una sola vez)
brew install xcodegen

# 2. Generar el proyecto de Xcode
cd firstapp
xcodegen generate

# 3. Abrir en Xcode
open Aperio.xcodeproj
```

Cada vez que se edite `project.yml` (por ejemplo, al agregar un target nuevo o cambiar el bundle ID), hay que volver a correr `xcodegen generate`.

## Estructura

```
Sources/
  App/                  Entry point (AperioApp.swift) e Info.plist generado
  Models/
    FrameLayout.swift     Visor, Claqueta, Créditos
    FrameFit.swift        Recortar o foto completa con bandas
    FrameGeometry.swift   Dónde va la foto y dónde la banda (compartido)
    FrameContent.swift    Los textos ya resueltos desde el EXIF (compartido)
    FrameConfiguration.swift  Toda la configuración + el gating de Pro
    ExportFormat.swift, ExifData.swift, SavedFrame.swift
  Services/
    ExifReader.swift     Lee EXIF/GPS de la foto con ImageIO
    FrameRenderer.swift  Compone la imagen final (Core Graphics) para exportar
    FrameLibraryStore.swift  Persiste las fotos ya exportadas
    SubscriptionStore.swift  Estado de Aperio Pro vía StoreKit 2
  Utilities/
    Theme.swift           Tokens de marca: negro, ámbar, New York + SF Mono
  Views/
    RootView.swift
    Onboarding/WelcomeView.swift
    Library/LibraryView.swift
    Import/PhotoPickerView.swift    Selector de fotos (PhotosUI) + lectura de EXIF
    Editor/EditorView.swift          Controles a medida, vista previa fija
    Frame/FramePreviewView.swift     Preview en vivo de las 3 plantillas
    Paywall/PaywallView.swift
Tests/AperioTests/        Tests de los modelos y de la geometría
```

### Dos piezas centrales

`FrameGeometry` y `FrameContent` son consumidas tanto por la vista previa (SwiftUI) como por el render final (Core Graphics). Antes cada una calculaba su propio layout y armaba sus propios textos, que es la forma más segura de que lo que el usuario ve y lo que exporta se separen sin que nadie lo note. Al tocar el layout de una plantilla, hay que hacerlo en `FrameGeometry`, no en las vistas.

Todos los tamaños se expresan en `geo.unit` (1% del ancho del lienzo), así la vista previa de 300pt y la exportación de 1080px producen la misma composición.

## Estado actual (v0.2 del código)

Ya implementado:
- Los 3 diseños del v1 (Visor, Claqueta, Créditos), tanto en preview en vivo (SwiftUI) como en export final (Core Graphics).
- Los 2 encuadres (recortar o foto completa con bandas), con la regla de que al haber bandas los datos bajan a la banda y desaparece el degradado, que solo existía para dar contraste sobre la foto.
- Lectura automática de EXIF (cámara, lente, ISO, apertura, velocidad, focal, fecha, GPS) vía ImageIO.
- Los 4 formatos de exportación (Feed, Vertical, Horizontal, Stories), todos en el plan gratis.
- Gating de plan centralizado en `FrameConfiguration.resolved(isPro:)`: tinte y tamaño del texto, firma del fotógrafo, ubicación y marca de agua. Al estar en un solo lugar, la vista previa y el render no pueden aplicarlo de forma distinta.
- Paywall con los dos planes (mensual/anual), usando `Product` reales de StoreKit 2 (no precios hardcodeados).
- `SubscriptionStore` conectado a StoreKit 2: carga de productos, compra, escucha de `Transaction.updates` y `isPro` derivado de las entitlements vigentes.
- Biblioteca persistente: `FrameLibraryStore` guarda cada frame exportado (thumbnail + configuración) en el directorio de Documentos, y `LibraryView` muestra la grilla real.

Para probar las compras localmente sin depender de App Store Connect: en Xcode, `File > New > File > StoreKit Configuration File`, agregar los dos productos (`com.aperio.app.pro.monthly`, `com.aperio.app.pro.yearly`) como suscripciones auto-renovables, y seleccionar ese archivo en `Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration`.

Pendiente (siguientes pasos):
- Estilo de las bandas (hoy siempre negras; falta blanco y la foto desenfocada de fondo).
- Posición configurable del bloque de datos.
- Selección y exportación en lote.
- Presets guardados por el usuario.
- Sincronización con iCloud.
- Logo del fotógrafo (hoy la firma es solo texto).
- Ícono de app y pantalla de lanzamiento reales (hoy `AppIcon.appiconset` está vacío).

> Nota: este código se escribe sin poder compilarlo (el entorno de desarrollo es Linux, sin Xcode). Los errores de compilación se detectan al abrirlo en una Mac, no antes.
- Crear los productos de suscripción en App Store Connect antes de probar compras reales (más allá del StoreKit Configuration File local).
