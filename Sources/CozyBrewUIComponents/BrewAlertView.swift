import SwiftUI

/// エラー表示ビュー
public struct BrewAlertView: View {
    let title: String
    let message: String
    let rawLog: String?
    let onDismiss: () -> Void
    
    @State private var showRawLog = false
    
    public init(
        title: String,
        message: String,
        rawLog: String? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.rawLog = rawLog
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Text(message)
                .font(.body)
            
            if let rawLog = rawLog, !rawLog.isEmpty {
                DisclosureGroup("Show Raw Log", isExpanded: $showRawLog) {
                    ScrollView {
                        Text(rawLog)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            HStack {
                Spacer()
                Button("OK", action: onDismiss)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
}
