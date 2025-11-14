import SwiftUI

/// インストール進捗ビュー
public struct InstallProgressView: View {
    let title: String
    let logOutput: String
    let onCancel: (() -> Void)?
    let isCancellable: Bool
    
    @State private var isExpanded: Bool = true
    
    public init(
        title: String,
        logOutput: String,
        onCancel: (() -> Void)? = nil,
        isCancellable: Bool = true
    ) {
        self.title = title
        self.logOutput = logOutput
        self.onCancel = onCancel
        self.isCancellable = isCancellable
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if isCancellable, let onCancel = onCancel {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                }
            }
            
            // ログ出力
            DisclosureGroup("Show Log", isExpanded: $isExpanded) {
                ScrollView {
                    Text(logOutput)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
