import SwiftUI

struct VariantBrowser: View {
    @Bindable var script: Script
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if script.variants.isEmpty {
                    SSEmptyState(
                        icon: "doc.on.doc",
                        title: "No Variants Yet",
                        subtitle: "Use AI actions or duplicate to create variants of this script."
                    )
                } else {
                    List {
                        ForEach(script.variants) { variant in
                            VStack(alignment: .leading, spacing: SSSpacing.xs) {
                                HStack {
                                    Text(variant.title)
                                        .font(SSTypography.headline)
                                        .foregroundStyle(SSColors.textPrimary)
                                    Spacer()
                                    Text(variant.sourceType.displayName)
                                        .font(SSTypography.caption)
                                        .foregroundStyle(SSColors.accent)
                                        .padding(.horizontal, SSSpacing.xs)
                                        .padding(.vertical, SSSpacing.xxxs)
                                        .background(SSColors.accentSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))
                                }

                                Text(variant.content.prefix(100) + (variant.content.count > 100 ? "..." : ""))
                                    .font(SSTypography.footnote)
                                    .foregroundStyle(SSColors.textSecondary)
                                    .lineLimit(2)

                                Text(variant.createdAt.formatted(.relative(presentation: .named)))
                                    .font(SSTypography.caption)
                                    .foregroundStyle(SSColors.textTertiary)
                            }
                            .padding(.vertical, SSSpacing.xxs)
                            .listRowBackground(SSColors.surfaceElevated)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(SSColors.background)
            .navigationTitle("Variants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SSColors.accent)
                }
            }
        }
    }
}
