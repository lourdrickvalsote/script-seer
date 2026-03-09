import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showPaywall = false

    private let totalPages = 5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SSColors.background.ignoresSafeArea()

                // Pages
                ZStack {
                    ForEach(0..<totalPages, id: \.self) { index in
                        pageView(for: index)
                            .frame(width: geometry.size.width)
                            .offset(x: CGFloat(index - currentPage) * geometry.size.width + dragOffset)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 80
                            if value.translation.width < -threshold, currentPage < totalPages - 1 {
                                withAnimation(SSAnimation.spring) {
                                    currentPage += 1
                                    dragOffset = 0
                                }
                                SSHaptics.selection()
                            } else if value.translation.width > threshold, currentPage > 0 {
                                withAnimation(SSAnimation.spring) {
                                    currentPage -= 1
                                    dragOffset = 0
                                }
                                SSHaptics.selection()
                            } else {
                                withAnimation(SSAnimation.spring) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

                // Bottom controls overlay
                VStack {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                        .padding(.trailing, SSSpacing.lg)
                        .padding(.top, SSSpacing.xs)
                    }

                    Spacer()

                    VStack(spacing: SSSpacing.md) {
                        OnboardingProgressBar(currentPage: currentPage, totalPages: totalPages)

                        if currentPage < totalPages - 1 {
                            SSButton("Continue", variant: .secondary) {
                                withAnimation(SSAnimation.spring) {
                                    currentPage += 1
                                }
                                SSHaptics.selection()
                            }
                        } else {
                            SSButton("Get Started", icon: "arrow.right", variant: .primary) {
                                completeOnboarding()
                            }
                        }
                    }
                    .padding(.horizontal, SSSpacing.lg)
                    .padding(.bottom, SSSpacing.xl)
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            ProUpgradeView()
                .onDisappear {
                    hasSeenOnboarding = true
                }
        }
    }

    @ViewBuilder
    private func pageView(for index: Int) -> some View {
        switch index {
        case 0: OnboardingProblemPage(isActive: currentPage == 0)
        case 1: OnboardingTeleprompterPage(isActive: currentPage == 1)
        case 2: OnboardingSpeechFollowPage(isActive: currentPage == 2)
        case 3: OnboardingRecordPage(isActive: currentPage == 3)
        case 4: OnboardingReadyPage(isActive: currentPage == 4)
        default: EmptyView()
        }
    }

    private func completeOnboarding() {
        if StoreManager.shared.isProUser {
            hasSeenOnboarding = true
        } else {
            showPaywall = true
        }
    }
}
