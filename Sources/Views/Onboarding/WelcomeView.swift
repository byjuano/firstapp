import SwiftUI

struct WelcomeView: View {
    let onFinish: () -> Void

    private let pages: [(title: String, subtitle: String)] = [
        ("Tus ajustes, sobre la foto", "El ISO, la apertura, la velocidad y el lente salen solos del archivo."),
        ("Tres formas de contarlo", "Sobre la imagen o en la banda, según lo que pida cada toma."),
        ("Lista para publicar", "Feed, Vertical, Horizontal y Stories, sin recortar la foto."),
    ]

    @State private var pageIndex = 0

    var body: some View {
        ZStack {
            Theme.void.ignoresSafeArea()
            VStack(spacing: 32) {
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(Theme.Font.display(30))
                                .italic()
                                .multilineTextAlignment(.center)
                            Text(page.subtitle)
                                .font(.body)
                                .foregroundStyle(Theme.inkDim)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 220)

                Button(action: advance) {
                    Text(pageIndex == pages.count - 1 ? "Empezar" : "Siguiente")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Theme.void)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 32)
            }
            .foregroundStyle(Theme.ink)
        }
    }

    private func advance() {
        if pageIndex < pages.count - 1 {
            pageIndex += 1
        } else {
            onFinish()
        }
    }
}

#Preview {
    WelcomeView(onFinish: {})
}
