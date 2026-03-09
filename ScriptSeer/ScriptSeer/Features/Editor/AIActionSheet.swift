import SwiftUI
import SwiftData

struct AIActionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let script: Script
    @State private var aiService = AIActionService()
    @State private var selectedAction: AIAction?
    @State private var aiStatus: AppleIntelligenceStatus?
    @State private var loadingRotation: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: SSSpacing.md) {
                switch aiService.state {
                case .idle:
                    actionList
                case .loading:
                    loadingView
                case .success(let result):
                    successView(result: result)
                case .failed(let message):
                    failedView(message: message)
                }
            }
            .background(SSColors.background)
            .navigationTitle("AI Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SSColors.textSecondary)
                }
            }
            .task {
                if aiStatus == nil {
                    aiStatus = AppleIntelligenceStatus.current()
                }
            }
        }
    }

    // MARK: - Action List

    private var actionList: some View {
        let status = aiStatus ?? .simulator
        return ScrollView {
            VStack(spacing: SSSpacing.sm) {
                if !status.isFunctional {
                    unavailableBanner(status: status)
                }

                ForEach(AIAction.allCases) { action in
                    Button(action: {
                        selectedAction = action
                        executeAction(action)
                    }) {
                        SSCard {
                            HStack(spacing: SSSpacing.sm) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(SSColors.accent)
                                    .frame(width: 36, height: 36)
                                    .background(SSColors.accentSubtle)
                                    .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

                                VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                                    Text(action.rawValue)
                                        .font(SSTypography.headline)
                                        .foregroundStyle(SSColors.textPrimary)
                                    Text(action.description)
                                        .font(SSTypography.caption)
                                        .foregroundStyle(SSColors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(SSColors.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!status.isFunctional)
                    .opacity(status.isFunctional ? 1.0 : 0.5)
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.top, SSSpacing.sm)
        }
    }

    private func unavailableBanner(status: AppleIntelligenceStatus) -> some View {
        SSCard {
            VStack(spacing: SSSpacing.sm) {
                Image(systemName: status.systemImage)
                    .font(.system(size: 28))
                    .foregroundStyle(SSColors.accent)
                Text("Apple Intelligence \(status.label)")
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)
                if let detail = status.detail {
                    Text(detail)
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SSSpacing.md)
        }
        .padding(.horizontal, SSSpacing.md)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(SSColors.accent.opacity(0.15), lineWidth: 3)
                    .frame(width: 100, height: 100)

                // Animated arc
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        SSColors.accent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(loadingRotation))

                // Center icon
                if let action = selectedAction {
                    Image(systemName: action.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(SSColors.accent)
                }
            }

            VStack(spacing: SSSpacing.xs) {
                if let action = selectedAction {
                    Text(action.rawValue)
                        .font(SSTypography.title2)
                        .foregroundStyle(SSColors.textPrimary)
                }

                Text("Processing your script...")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
            }
            .padding(.top, SSSpacing.xl)

            Spacer()

            SSGlassPanel {
                HStack(spacing: SSSpacing.sm) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SSColors.accent)
                    Text("Your original script is safe. This creates a new variant.")
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                }
                .padding(.vertical, SSSpacing.xxs)
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, SSSpacing.lg)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                loadingRotation = 360
            }
        }
    }

    // MARK: - Success

    private func successView(result: String) -> some View {
        VStack(spacing: SSSpacing.md) {
            ScrollView {
                VStack(alignment: .leading, spacing: SSSpacing.sm) {
                    Text("Result Preview")
                        .font(SSTypography.title2)
                        .foregroundStyle(SSColors.textPrimary)

                    Text(result)
                        .font(SSTypography.body)
                        .foregroundStyle(SSColors.textSecondary)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SSSpacing.md)
            }

            VStack(spacing: SSSpacing.sm) {
                SSButton("Save as Variant", icon: "checkmark", variant: .primary) {
                    saveVariant(result: result)
                }
                SSButton("Discard", variant: .ghost) {
                    aiService.reset()
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.bottom, SSSpacing.md)
        }
    }

    // MARK: - Failed

    private func failedView(message: String) -> some View {
        VStack(spacing: SSSpacing.lg) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(SSColors.textTertiary)

            Text(message)
                .font(SSTypography.subheadline)
                .foregroundStyle(SSColors.textSecondary)
                .multilineTextAlignment(.center)

            SSButton("Try Again", variant: .secondary) {
                aiService.reset()
            }
            .frame(width: 160)
            Spacer()
        }
    }

    // MARK: - Actions

    private func executeAction(_ action: AIAction) {
        guard !script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            aiService.state = .failed("Script is empty. Add some content first.")
            return
        }
        Task {
            _ = await aiService.execute(action: action, content: script.content)
        }
    }

    private func saveVariant(result: String) {
        guard let action = selectedAction else { return }
        let variant = ScriptVariant(
            title: "\(script.title) — \(action.rawValue)",
            content: result,
            sourceType: action.variantSourceType,
            parentScript: script
        )
        modelContext.insert(variant)
        SSHaptics.success()
        dismiss()
    }
}
