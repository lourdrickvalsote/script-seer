import SwiftUI

struct ScriptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var script: Script
    @State private var editingTitle = false
    @State private var editedTitle = ""
    @State private var showExportSheet = false
    @State private var exportItems: [URL] = []
    @State private var showExportError = false
    @State private var exportErrorMessage = ""
    @State private var appeared = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: SSSpacing.lg) {
                titleSection
                metadataRow
                tagsSection
                contentCard
                variantsSection
            }
            .padding(.top, SSSpacing.xl)

            Spacer(minLength: SSSpacing.md)

            // Bottom CTA
            startButton
        }
        .background(SSColors.background)
        .toolbar(.hidden, for: .tabBar)
        .preference(key: HideRecordButtonKey.self, value: true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: SSSpacing.sm) {
                    NavigationLink(destination: ScriptEditorView(script: script)) {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SSColors.accent)
                    }

                    Menu {
                        Button(action: { exportScript(format: .plainText) }) {
                            Label("Share as Plain Text", systemImage: "doc.plaintext")
                        }
                        Button(action: { exportScript(format: .withCues) }) {
                            Label("Share with Cues", systemImage: "doc.text")
                        }
                        Button(action: { exportScript(format: .pdf) }) {
                            Label("Share as PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SSColors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportItems.first {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK") {}
        } message: {
            Text(exportErrorMessage)
        }
        .onAppear {
            guard !appeared else { return }
            appeared = true
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: SSSpacing.xs) {
            if editingTitle {
                TextField("Script Title", text: $editedTitle)
                    .font(SSTypography.largeTitle)
                    .foregroundStyle(SSColors.textPrimary)
                    .focused($titleFocused)
                    .onSubmit { commitTitleEdit() }
                    .onChange(of: titleFocused) {
                        if !titleFocused { commitTitleEdit() }
                    }
            } else {
                Text(script.title)
                    .font(SSTypography.largeTitle)
                    .foregroundStyle(SSColors.textPrimary)
                    .onTapGesture {
                        editedTitle = script.title
                        editingTitle = true
                        titleFocused = true
                    }
            }

            // Accent underline bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(SSColors.accent)
                .frame(width: appeared ? 40 : 0, height: 3)
                .animation(reduceMotion ? nil : SSAnimation.smooth.delay(0.15), value: appeared)
        }
        .padding(.horizontal, SSSpacing.md)
        .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.0))
    }

    // MARK: - Metadata Row (condensed inline)

    private var metadataRow: some View {
        HStack(spacing: SSSpacing.xs) {
            Text(script.formattedDuration)
                .fontWeight(.medium)
            Text("·")
                .foregroundStyle(SSColors.textTertiary)
            Text("\(script.wordCount) words")
            Text("·")
                .foregroundStyle(SSColors.textTertiary)
            Text("Edited \(script.updatedAt.formatted(.relative(presentation: .named)))")
        }
        .font(SSTypography.footnote)
        .foregroundStyle(SSColors.textSecondary)
        .padding(.horizontal, SSSpacing.md)
        .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.08))
    }

    // MARK: - Tags Section

    @ViewBuilder
    private var tagsSection: some View {
        if !script.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SSSpacing.xs) {
                    ForEach(script.tags, id: \.self) { tag in
                        Text(tag)
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.accent)
                            .padding(.horizontal, SSSpacing.sm)
                            .padding(.vertical, SSSpacing.xxs)
                            .background(
                                Capsule()
                                    .fill(SSColors.accentSubtle)
                            )
                    }
                }
                .padding(.horizontal, SSSpacing.md)
            }
            .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.16))
        }
    }

    // MARK: - Content Card (scrollable)

    private var contentCard: some View {
        HStack(alignment: .top, spacing: 0) {
            // Accent notch
            RoundedRectangle(cornerRadius: 1.5)
                .fill(SSColors.accent)
                .frame(width: 3, height: 24)
                .padding(.top, SSSpacing.lg)
                .padding(.leading, SSSpacing.md)

            if script.content.isEmpty {
                Text("No content yet. Tap the pencil icon to start writing.")
                    .font(SSTypography.body)
                    .foregroundStyle(SSColors.textTertiary)
                    .lineSpacing(6)
                    .padding(SSSpacing.md)
            } else {
                ScrollView {
                    Text(script.content)
                        .font(SSTypography.body)
                        .foregroundStyle(SSColors.textPrimary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SSSpacing.md)
                }
                .frame(maxHeight: 280)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SSRadius.lg)
                .fill(SSColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    SSColors.divider.opacity(0.8),
                                    SSColors.divider.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: SSColors.shadow, radius: 8, x: 0, y: 2)
        .padding(.horizontal, SSSpacing.md)
        .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.24))
    }

    // MARK: - Variants Section

    @ViewBuilder
    private var variantsSection: some View {
        if !script.variants.isEmpty {
            VStack(alignment: .leading, spacing: SSSpacing.sm) {
                Text("Variants")
                    .font(SSTypography.footnote)
                    .foregroundStyle(SSColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                ForEach(script.variants) { variant in
                    HStack(spacing: SSSpacing.sm) {
                        Text(variant.title)
                            .font(SSTypography.body)
                            .foregroundStyle(SSColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(variant.sourceType.displayName)
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.accent)
                            .padding(.horizontal, SSSpacing.xs)
                            .padding(.vertical, SSSpacing.xxxs)
                            .background(
                                Capsule()
                                    .fill(SSColors.accentSubtle)
                            )
                    }
                    .padding(.vertical, SSSpacing.xxs)
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.32))
        }
    }

    // MARK: - Start Button (pinned to bottom)

    private var startButton: some View {
        NavigationLink(destination: TeleprompterView(script: script)) {
            HStack(spacing: SSSpacing.xs) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Begin Reading")
                    .font(SSTypography.headline)
            }
            .foregroundStyle(SSColors.lavenderMist)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.md)
                    .fill(
                        LinearGradient(
                            colors: [SSColors.accent, SSColors.accent.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: SSColors.accent.opacity(0.3), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, SSSpacing.md)
        .padding(.bottom, SSSpacing.lg)
        .modifier(CardEntrance(appeared: appeared, reduceMotion: reduceMotion, delay: 0.40))
    }

    // MARK: - Helpers

    private func commitTitleEdit() {
        editingTitle = false
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != script.title {
            script.updateTitle(trimmed)
        }
    }

    private func exportScript(format: ExportService.ExportFormat) {
        do {
            let url = try ExportService.createTempFile(script: script, format: format)
            exportItems = [url]
            showExportSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
        }
    }
}

// MARK: - CardEntrance Modifier

private struct CardEntrance: ViewModifier {
    let appeared: Bool
    let reduceMotion: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(reduceMotion ? nil : SSAnimation.smooth.delay(delay), value: appeared)
    }
}
