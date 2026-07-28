import SwiftUI

struct EditorView: View {
    let photo: UIImage
    let exif: ExifData

    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var libraryStore: FrameLibraryStore
    @State private var configuration = FrameConfiguration()
    @State private var isShowingPaywall = false
    @State private var exportedImage: ShareableImage?

    private let horizontalPadding: CGFloat = 18

    var body: some View {
        // La foto queda fija arriba y solo scrollea el panel: con los controles
        // apilados, la vista previa se perdía de pantalla justo cuando el
        // usuario tocaba lo que la modifica.
        GeometryReader { proxy in
            VStack(spacing: 0) {
                previewArea(available: proxy.size)
                Divider().overlay(Theme.hairline)
                controlsPanel
            }
        }
        .background(Theme.void.ignoresSafeArea())
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.void, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: export) {
                    Text("Exportar")
                        .font(Theme.Font.mono(12, weight: .semibold))
                        .foregroundStyle(Theme.void)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(item: $exportedImage) { item in
            ShareSheet(image: item.image)
        }
    }

    // MARK: - Vista previa

    private func previewArea(available: CGSize) -> some View {
        let areaHeight = max(available.height * 0.46, 1)
        let size = previewSize(
            fitting: CGSize(width: available.width - horizontalPadding * 2, height: areaHeight - 24)
        )

        return FramePreviewView(
            photo: photo,
            exif: exif,
            configuration: configuration,
            isPro: subscriptionStore.isPro,
            size: size
        )
        // El borde fino no es decorativo: sin él, una foto oscura sobre fondo
        // negro no deja ver dónde termina la imagen que se va a exportar.
        .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
        .frame(width: available.width, height: areaHeight)
    }

    private func previewSize(fitting available: CGSize) -> CGSize {
        let safeWidth = max(available.width, 1)
        let safeHeight = max(available.height, 1)
        let ratio = configuration.format.aspectRatio
        let width = max(min(safeWidth, safeHeight * ratio), 1)
        return CGSize(width: width, height: max(width / ratio, 1))
    }

    // MARK: - Controles

    private var controlsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ControlGroup(title: "Diseño", isFirst: true) {
                    OptionRow(options: FrameLayout.allCases, selection: $configuration.layout) { $0.displayName }
                }
                ControlGroup(title: "Formato") {
                    OptionRow(options: ExportFormat.allCases, selection: $configuration.format) { $0.displayName }
                }
                ControlGroup(title: "Encuadre") {
                    OptionRow(options: FrameFit.allCases, selection: $configuration.fit) { $0.displayName }
                }
                ControlGroup(title: "Datos a mostrar") {
                    VStack(spacing: 0) {
                        FieldRow(name: "ISO", isOn: $configuration.visibleFields.iso)
                        FieldRow(name: "Apertura", isOn: $configuration.visibleFields.aperture)
                        FieldRow(name: "Velocidad", isOn: $configuration.visibleFields.shutterSpeed)
                        FieldRow(name: "Focal", isOn: $configuration.visibleFields.focalLength)
                        FieldRow(name: "Cámara y lente", isOn: $configuration.visibleFields.cameraAndLens, isLast: true)
                    }
                }

                if subscriptionStore.isPro {
                    ControlGroup(title: "Tinte de los datos") {
                        OptionRow(options: AccentTint.allCases, selection: $configuration.accent) { $0.displayName }
                    }
                    ControlGroup(title: "Tamaño del texto") {
                        TextScaleRow(scale: $configuration.textScale)
                    }
                    ControlGroup(title: "Tu firma") {
                        SignatureRow(
                            name: $configuration.photographerName,
                            isShown: $configuration.visibleFields.photographerCredit
                        )
                    }
                    ControlGroup(title: "Ubicación") {
                        FieldRow(
                            name: "Fecha, hora y lugar",
                            isOn: $configuration.visibleFields.dateTimeAndLocation,
                            isLast: true
                        )
                    }
                } else {
                    // Todo lo de pago junto y al final: el usuario recorre
                    // primero lo que sí puede usar y llega al muro una sola vez,
                    // en lugar de chocarlo en cada grupo de controles.
                    ProBlock { isShowingPaywall = true }
                        .padding(.top, 20)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 32)
        }
        .background(Theme.void)
    }

    private func export() {
        let image = FrameRenderer.render(
            photo: photo,
            exif: exif,
            configuration: configuration,
            isPro: subscriptionStore.isPro
        )
        libraryStore.save(image: image, configuration: configuration, exif: exif)
        exportedImage = ShareableImage(image: image)
    }
}

private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Controles a medida

/// Un grupo de controles, separado por una línea fina en vez de una tarjeta.
private struct ControlGroup<Content: View>: View {
    let title: String
    var isFirst = false
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(Theme.Font.mono(10))
                .tracking(1.4)
                .foregroundStyle(Theme.inkFaint)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            if !isFirst {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
        }
    }
}

/// Selector de texto plano: la opción activa se subraya. Sin pastillas ni
/// segmentado de sistema.
private struct OptionRow<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 18, alignment: .leading)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            ForEach(options) { option in
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(.system(size: 15, weight: option == selection ? .semibold : .regular))
                        .foregroundStyle(option == selection ? Theme.ink : Theme.inkDim)
                        .padding(.bottom, 4)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(option == selection ? Theme.ink : Color.clear)
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Casilla cuadrada en vez de switch: un borde visible se lee como algo
/// tocable, cosa que una palabra suelta ("ON") no lograba. La fila entera es
/// área de toque.
private struct FieldRow: View {
    let name: String
    @Binding var isOn: Bool
    var isLast = false

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Text(name)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ink)
                Spacer()
                CheckBox(isOn: isOn)
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
        }
    }
}

private struct CheckBox: View {
    let isOn: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isOn ? Theme.ink : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(isOn ? Theme.ink : Theme.inkFaint, lineWidth: 1))
            .frame(width: 18, height: 18)
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.void)
                }
            }
    }
}

private struct TextScaleRow: View {
    @Binding var scale: Double

    private let options: [(label: String, value: Double)] = [
        ("Chico", 0.85), ("Normal", 1.0), ("Grande", 1.2),
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(options, id: \.label) { option in
                Button {
                    scale = option.value
                } label: {
                    Text(option.label)
                        .font(.system(size: 15, weight: isSelected(option.value) ? .semibold : .regular))
                        .foregroundStyle(isSelected(option.value) ? Theme.ink : Theme.inkDim)
                        .padding(.bottom, 4)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(isSelected(option.value) ? Theme.ink : Color.clear)
                                .frame(height: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private func isSelected(_ value: Double) -> Bool {
        abs(scale - value) < 0.01
    }
}

private struct SignatureRow: View {
    @Binding var name: String
    @Binding var isShown: Bool

    var body: some View {
        VStack(spacing: 12) {
            TextField("Tu nombre", text: $name)
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink)
                .textFieldStyle(.plain)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
            FieldRow(name: "Mostrar en la foto", isOn: $isShown, isLast: true)
        }
    }
}

/// El bloque de pago, con la lista completa a la vista antes de tocar nada.
private struct ProBlock: View {
    let action: () -> Void

    private let benefits = [
        "Tu nombre y tu logo",
        "Fecha, hora y ubicación",
        "Tinte y tamaño del texto",
        "Estilo de las bandas",
        "Presets, lote ilimitado, sin marca de agua",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("APERIO PRO")
                    .font(Theme.Font.mono(11))
                    .tracking(1.8)
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text("$4.99 / mes")
                    .font(Theme.Font.mono(11))
                    .foregroundStyle(Theme.inkFaint)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 9) {
                        Rectangle()
                            .fill(Theme.accent)
                            .frame(width: 5, height: 1)
                            .padding(.top, 8)
                        Text(benefit)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkDim)
                    }
                }
            }

            Button(action: action) {
                Text("Probar 7 días gratis")
                    .font(Theme.Font.mono(12, weight: .semibold))
                    .foregroundStyle(Theme.void)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentDim, lineWidth: 1))
    }
}
