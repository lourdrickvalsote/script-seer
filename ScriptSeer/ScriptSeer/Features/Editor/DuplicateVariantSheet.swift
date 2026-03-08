import SwiftUI
import SwiftData

struct DuplicateVariantSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let script: Script
    @State private var variantTitle = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: SSSpacing.lg) {
                SSInputRow("Variant Title", text: $variantTitle, placeholder: "e.g. Shortened version")

                Text("This creates a copy of your script as a variant. The original remains unchanged.")
                    .font(SSTypography.footnote)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                SSButton("Create Variant", icon: "doc.on.doc", variant: .primary) {
                    createVariant()
                }
            }
            .padding(SSSpacing.lg)
            .background(SSColors.background)
            .navigationTitle("Duplicate as Variant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SSColors.textSecondary)
                }
            }
            .onAppear {
                variantTitle = "\(script.title) — Copy"
            }
        }
    }

    private func createVariant() {
        let variant = ScriptVariant(
            title: variantTitle.isEmpty ? "\(script.title) — Copy" : variantTitle,
            content: script.content,
            sourceType: .custom,
            parentScript: script
        )
        modelContext.insert(variant)
        SSHaptics.success()
        dismiss()
    }
}
