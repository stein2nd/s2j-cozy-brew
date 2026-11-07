import SwiftUI

/// brew 操作中表示の挙動
enum BrewOperationOverlayStyle {
    /// 画面全体を暗くし、操作をブロックする (Formula 等)
    case blocking
    /// 管理者ダイアログを隠さない (Cask Upgrade)。暗幕なし・カードは右上・背面は操作不可だがヒットは透過
    case passwordFriendly
}

/// brew 操作 (Upgrade 等) 中に一覧・詳細の進行を示す
struct BrewOperationOverlay: View {
    let title: String
    var footnote: String?
    var style: BrewOperationOverlayStyle = .blocking

    var body: some View {
        switch style {
        case .blocking:
            blockingOverlay
        case .passwordFriendly:
            passwordFriendlyOverlay
        }
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(style == .blocking ? .large : .regular)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let footnote {
                Text(footnote)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var blockingOverlay: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            progressCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(true)
        .accessibilityAddTraits(.isModal)
    }

    private var passwordFriendlyOverlay: some View {
        VStack {
            HStack {
                Spacer()
                progressCard
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .allowsHitTesting(false)
    }
}
