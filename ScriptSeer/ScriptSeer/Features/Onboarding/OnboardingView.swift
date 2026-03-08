import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.text.fill",
            title: "Write Your Script",
            subtitle: "Create or import scripts from TXT, RTF, PDF, and DOCX files."
        ),
        OnboardingPage(
            icon: "play.fill",
            title: "Prompt Naturally",
            subtitle: "Read on camera without looking like you're reading. Focus Window keeps text near the lens."
        ),
        OnboardingPage(
            icon: "waveform",
            title: "Speech Follow",
            subtitle: "Your script advances as you speak. Strict mode for precision, Smart mode for flexibility."
        ),
        OnboardingPage(
            icon: "video.fill",
            title: "Record & Practice",
            subtitle: "Record with overlay or rehearse with stumble tracking. Your scripts stay private on-device."
        )
    ]

    var body: some View {
        ZStack {
            SSColors.background.ignoresSafeArea()

            VStack(spacing: SSSpacing.xl) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: SSSpacing.lg) {
                            Image(systemName: page.icon)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(SSColors.accent)

                            Text(page.title)
                                .font(SSTypography.title)
                                .foregroundStyle(SSColors.textPrimary)

                            Text(page.subtitle)
                                .font(SSTypography.subheadline)
                                .foregroundStyle(SSColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, SSSpacing.xl)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Spacer()

                // Actions
                VStack(spacing: SSSpacing.sm) {
                    if currentPage == pages.count - 1 {
                        SSButton("Get Started", icon: "arrow.right", variant: .primary) {
                            hasSeenOnboarding = true
                        }
                    } else {
                        SSButton("Next", variant: .secondary) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }

                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .foregroundStyle(SSColors.textTertiary)
                    .font(SSTypography.subheadline)
                }
                .padding(.horizontal, SSSpacing.lg)
                .padding(.bottom, SSSpacing.xl)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}
