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
  Models/                FrameLayout, ExportFormat, ExifData, FrameConfiguration
  Services/
    ExifReader.swift     Lee EXIF/GPS de la foto con ImageIO
    FrameRenderer.swift  Compone la imagen final (Core Graphics) para exportar
    SubscriptionStore.swift  Estado de Aperio Pro (StoreKit 2 pendiente de conectar)
  Utilities/
    Theme.swift           Tokens de marca: colores y tipografía (New York + SF Mono)
  Views/
    RootView.swift
    Onboarding/WelcomeView.swift
    Library/LibraryView.swift
    Import/PhotoPickerView.swift    Selector de fotos (PhotosUI) + lectura de EXIF
    Editor/EditorView.swift          Diseño, formato, sliders de color/tamaño, campos
    Frame/FramePreviewView.swift     Preview en vivo de las 3 plantillas
    Paywall/PaywallView.swift
Tests/AperioTests/        Tests unitarios de los modelos
```

## Estado actual (v0.1 del código)

Ya implementado:
- Los 3 diseños del v1 (Línea, Ficha, Esquina), tanto en preview en vivo (SwiftUI) como en export final (Core Graphics).
- Lectura automática de EXIF (cámara, lente, ISO, apertura, velocidad, focal, fecha, GPS) vía ImageIO.
- Los 4 formatos de exportación (Feed, Vertical, Horizontal, Stories), todos en el plan gratis.
- Gating de plan: color y tamaño de marco personalizables, campos extra (fecha/hora/ubicación, nombre o logo) y remoción de marca de agua quedan detrás de `SubscriptionStore.isPro`.
- Paywall con los dos planes (mensual/anual).

Pendiente (siguientes pasos):
- Conectar `SubscriptionStore` a StoreKit 2 real (productos, compra, restauración, verificación de transacción).
- Persistencia de la biblioteca de frames creados (hoy `LibraryView` siempre muestra el estado vacío).
- Selección y exportación en lote.
- Presets guardados por el usuario.
- Sincronización con iCloud.
- Ícono de app y pantalla de lanzamiento reales (hoy `AppIcon.appiconset` está vacío).
