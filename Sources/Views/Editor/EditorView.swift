import SwiftUI

struct EditorView: View {
    let photo: UIImage
    let exif: ExifData

    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var libraryStore: FrameLibraryStore
    @State private var configuration = FrameConfiguration()
    @State private var isShowingPaywall = false
    @State private var exportedImage: ShareableImage?

    var body: some View {
        // El GeometryReader envuelve TODA la pantalla, fuera del ScrollView a propósito:
        // un GeometryReader anidado directamente dentro del contenido de un ScrollView
        // puede reportar un tamaño "ideal" incorrecto (un quirk conocido de SwiftUI) que
        // hace que el ScrollView recorte el contenido a un tamaño distinto del que en
        // realidad se dibuja. Midiendo la pantalla completa una sola vez, antes de entrar
        // al ScrollView, se evita esa ambigüedad.
        GeometryReader { screenGeometry in
            let horizontalPadding: CGFloat = 32
            let resolvedPreviewSize = previewSize(
                fitting: CGSize(width: screenGeometry.size.width - horizontalPadding, height: 420)
            )

            ZStack {
                Theme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Spacer(minLength: 0)
                            FramePreviewView(photo: photo, exif: exif, configuration: configuration, isPro: subscriptionStore.isPro)
                                .frame(width: resolvedPreviewSize.width, height: resolvedPreviewSize.height)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 12)

                        VStack(spacing: 20) {
                            layoutControl
                            formatControl
                            colorControl
                            sizeControl
                            fieldsControl
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, horizontalPadding / 2)
                }
            }
        }
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Exportar", action: export)
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(item: $exportedImage) { item in
            ShareSheet(image: item.image)
        }
    }

    // MARK: - Controls

    private var layoutControl: some View {
        ControlGroup(title: "Diseño") {
            Picker("Diseño", selection: $configuration.layout) {
                ForEach(FrameLayout.allCases) { layout in
                    Text(layout.displayName).tag(layout)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var formatControl: some View {
        ControlGroup(title: "Formato", badge: .free("Los 4, gratis")) {
            Picker("Formato", selection: $configuration.format) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var colorControl: some View {
        ControlGroup(title: "Color del marco", badge: .pro) {
            if subscriptionStore.isPro {
                Slider(value: $configuration.color.position, in: 0...1)
            } else {
                LockedControl(message: "Marco claro u oscuro fijo en el plan gratis.") {
                    isShowingPaywall = true
                }
            }
        }
    }

    private var sizeControl: some View {
        ControlGroup(title: "Tamaño del marco", badge: .pro) {
            if subscriptionStore.isPro {
                Slider(value: $configuration.sizeFraction, in: 0...1)
            } else {
                LockedControl(message: "Tamaño estándar fijo en el plan gratis.") {
                    isShowingPaywall = true
                }
            }
        }
    }

    private var fieldsControl: some View {
        ControlGroup(title: "Datos a mostrar") {
            VStack(spacing: 10) {
                Toggle("ISO", isOn: $configuration.visibleFields.iso)
                Toggle("Apertura", isOn: $configuration.visibleFields.aperture)
                Toggle("Velocidad", isOn: $configuration.visibleFields.shutterSpeed)
                Toggle("Focal", isOn: $configuration.visibleFields.focalLength)
                Toggle("Cámara y lente", isOn: $configuration.visibleFields.cameraAndLens)

                Divider()

                proToggle(
                    "Fecha, hora y ubicación",
                    isOn: $configuration.visibleFields.dateTimeAndLocation
                )
                proToggle(
                    "Nombre o logo del fotógrafo",
                    isOn: $configuration.visibleFields.photographerCredit
                )
            }
            .toggleStyle(.switch)
            .tint(Theme.accent)
        }
    }

    @ViewBuilder
    private func proToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        if subscriptionStore.isPro {
            Toggle(title, isOn: isOn)
        } else {
            Button {
                isShowingPaywall = true
            } label: {
                HStack {
                    Text(title)
                    Spacer()
                    Text("Pro")
                        .font(Theme.Font.mono(10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 3))
                        .foregroundStyle(Theme.paper)
                }
            }
            .foregroundStyle(Theme.ink)
        }
    }

    private func export() {
        let image = FrameRenderer.render(photo: photo, exif: exif, configuration: configuration, isPro: subscriptionStore.isPro)
        libraryStore.save(image: image, configuration: configuration, exif: exif)
        exportedImage = ShareableImage(image: image)
    }

    /// Calcula un tamaño exacto (no ambiguo) que respeta `configuration.format.aspectRatio`
    /// dentro del espacio disponible. `aspectRatio(contentMode: .fit)` dentro de un
    /// `ScrollView` puede calcular un tamaño mucho mayor a la pantalla al no tener una
    /// propuesta de ancho concreta; pasar un `CGSize` ya resuelto evita ese problema.
    private func previewSize(fitting available: CGSize) -> CGSize {
        let ratio = configuration.format.aspectRatio
        let widthIfHeightConstrained = available.height * ratio
        let width = min(available.width, widthIfHeightConstrained)
        let height = width / ratio
        return CGSize(width: width, height: height)
    }
}

private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Un grupo de control del editor, con su título y un badge opcional de plan.
private struct ControlGroup<Content: View>: View {
    enum Badge {
        case free(String)
        case pro
    }

    let title: String
    var badge: Badge?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title.uppercased())
                    .font(Theme.Font.mono(11))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSoft)
                if let badge {
                    badgeView(badge)
                }
                Spacer()
            }
            content
        }
        .padding(14)
        .background(Theme.paperRaised, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func badgeView(_ badge: Badge) -> some View {
        switch badge {
        case .free(let label):
            Text(label.uppercased())
                .font(Theme.Font.mono(9))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(Theme.accent)
        case .pro:
            Text("PRO")
                .font(Theme.Font.mono(9))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(Theme.paper)
        }
    }
}

private struct LockedControl: View {
    let message: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lock.fill")
                Text(message)
                    .font(.subheadline)
                Spacer()
            }
            .foregroundStyle(Theme.inkSoft)
        }
    }
}
