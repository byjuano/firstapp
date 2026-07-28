import SwiftUI

struct WelcomeView: View {
    let onFinish: () -> Void

    private let pages: [(title: String, subtitle: String)] = [
        ("Enmarca tu foto", "Elige un diseño minimalista y aplícalo en segundos."),
        ("Cuenta cómo la tomaste", "Aperio lee el ISO, la apertura, la velocidad y la focal directo del EXIF."),
        ("Compártela con estilo", "Exportá lista para Feed, Vertical, Horizontal o Stories."),
    ]

    @State private var pageIndex = 0

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
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
                                .foregroundStyle(Theme.inkSoft)
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
                        .foregroundStyle(Theme.paper)
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
