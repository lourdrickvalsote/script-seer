import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @State private var store = StoreManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var showError = false
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum PlanType {
        case monthly, annual
    }

    var body: some View {
        ZStack {
            SSColors.background.ignoresSafeArea()

            if store.isProUser {
                activeProView
            } else {
                paywallView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .preference(key: HideRecordButtonKey.self, value: true)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(store.errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    // MARK: - Paywall

    private var paywallView: some View {
        VStack(spacing: 0) {
            // Close button row
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SSColors.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.top, SSSpacing.xs)

            Spacer(minLength: SSSpacing.xs)

            // Hero
            heroSection

            Spacer(minLength: SSSpacing.md)

            // Benefits
            benefitsSection
                .padding(.horizontal, SSSpacing.lg)

            Spacer(minLength: SSSpacing.md)

            // Plan cards
            planCardsSection
                .padding(.horizontal, SSSpacing.md)

            Spacer(minLength: SSSpacing.md)

            // CTA + footer
            ctaSection
                .padding(.horizontal, SSSpacing.md)
                .padding(.bottom, SSSpacing.sm)
        }
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(SSAnimation.smooth) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: SSSpacing.sm) {
            ZStack {
                // Large pulsing aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SSColors.accent.opacity(0.35),
                                SSColors.accent.opacity(0.12),
                                SSColors.accent.opacity(0.03),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 20)
                    .modifier(BreathingPulseModifier(
                        minScale: 0.92, maxScale: 1.10,
                        minOpacity: 0.5, maxOpacity: 1.0,
                        duration: 2.5
                    ))

                // 3D tilting disc assembly
                ZStack {
                    // Outer accent ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    SSColors.accent,
                                    SSColors.accent.opacity(0.4),
                                    SSColors.accent.opacity(0.1),
                                    SSColors.accent.opacity(0.4),
                                    SSColors.accent
                                ],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 140, height: 140)

                    // Main disc
                    Circle()
                        .fill(SSColors.surfaceElevated)
                        .frame(width: 130, height: 130)
                        // Top-left shine
                        .overlay(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            SSColors.accent.opacity(0.12),
                                            SSColors.accent.opacity(0.03),
                                            Color.clear
                                        ],
                                        center: UnitPoint(x: 0.3, y: 0.25),
                                        startRadius: 0,
                                        endRadius: 70
                                    )
                                )
                        )
                        // Inner rim
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            SSColors.accent.opacity(0.4),
                                            SSColors.divider,
                                            SSColors.accent.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                    // Icon
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    SSColors.accent,
                                    SSColors.accent.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: SSColors.accent.opacity(0.6), radius: 12)
                        .shadow(color: SSColors.accent.opacity(0.3), radius: 24)
                }
                .shadow(color: SSColors.accent.opacity(0.4), radius: 30, x: 0, y: 6)
                .shadow(color: SSColors.shadow, radius: 20, x: 0, y: 12)
                .modifier(TiltingDiscModifier(duration: 4.0))
            }
            .frame(height: 150)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .blur(radius: appeared ? 0 : 10)
            .animation(reduceMotion ? nil : SSAnimation.smooth, value: appeared)

            Text("ScriptSeer Pro")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(SSColors.textPrimary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(reduceMotion ? nil : SSAnimation.smooth.delay(0.15), value: appeared)

            Text("Your words. Their attention.")
                .font(SSTypography.subheadline)
                .foregroundStyle(SSColors.textSecondary)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : SSAnimation.standard.delay(0.30), value: appeared)
        }
    }

    // MARK: - Benefits

    private var benefitsSection: some View {
        VStack(spacing: SSSpacing.xs) {
            benefitRow(icon: "text.viewfinder", text: "Focus Window teleprompter mode", delay: 0.40)
            benefitRow(icon: "waveform", text: "Voice-tracking auto-scroll", delay: 0.48)
            benefitRow(icon: "camera.fill", text: "Record video with script overlay", delay: 0.56)
            benefitRow(icon: "sparkles", text: "AI script rewriting and cleanup", delay: 0.64)
            benefitRow(icon: "doc.on.doc", text: "Unlimited script variants", delay: 0.72)
            benefitRow(icon: "paintpalette", text: "Custom themes and display modes", delay: 0.80)
            benefitRow(icon: "square.and.arrow.down", text: "Import scripts from TXT, PDF, DOCX", delay: 0.88)
        }
    }

    private func benefitRow(icon: String, text: String, delay: Double) -> some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SSColors.accent)
                .frame(width: 24, height: 24)
                .background(
                    Circle().fill(SSColors.accentSubtle)
                )

            Text(text)
                .font(SSTypography.footnote)
                .foregroundStyle(SSColors.textPrimary)

            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(reduceMotion ? nil : SSAnimation.standard.delay(delay), value: appeared)
    }

    // MARK: - Plan Cards

    private var planCardsSection: some View {
        HStack(spacing: SSSpacing.sm) {
            PlanCard(
                title: "Monthly",
                price: store.monthlyProduct?.displayPrice ?? "$4.99",
                period: "/mo",
                badge: nil,
                subtitle: nil,
                isSelected: selectedPlan == .monthly
            ) {
                withAnimation(SSAnimation.spring) { selectedPlan = .monthly }
                SSHaptics.selection()
            }

            PlanCard(
                title: "Annual",
                price: store.annualProduct?.displayPrice ?? "$39.99",
                period: "/yr",
                badge: "Save 33%",
                subtitle: "7-day free trial",
                isSelected: selectedPlan == .annual
            ) {
                withAnimation(SSAnimation.spring) { selectedPlan = .annual }
                SSHaptics.selection()
            }
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.95)
        .animation(reduceMotion ? nil : SSAnimation.spring.delay(0.75), value: appeared)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: SSSpacing.xs) {
            // CTA button
            Button {
                SSHaptics.light()
                Task { await purchaseSelected() }
            } label: {
                HStack(spacing: SSSpacing.xs) {
                    if selectedPlan == .annual {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(selectedPlan == .annual ? "Start Free Trial" : "Subscribe Now")
                        .font(SSTypography.headline)
                }
                .foregroundStyle(.white)
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
                        .shadow(color: SSColors.accent.opacity(0.4), radius: 16, x: 0, y: 6)
                )
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading)
            .opacity(store.isLoading ? 0.6 : 1.0)
            .overlay {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }

            Text(
                selectedPlan == .annual
                    ? "7-day free trial, then $39.99/year · Cancel anytime"
                    : "$4.99 billed monthly · Cancel anytime"
            )
            .font(SSTypography.caption)
            .foregroundStyle(SSColors.textTertiary)
            .padding(.top, SSSpacing.xxs)

            HStack(spacing: SSSpacing.sm) {
                Button("Restore") {
                    Task { await store.restorePurchases() }
                }
                .disabled(store.isLoading)

                Text("·").foregroundStyle(SSColors.textTertiary)

                if let url = URL(string: "https://scriptseer.app/privacy") {
                    Link("Privacy", destination: url)
                }

                Text("·").foregroundStyle(SSColors.textTertiary)

                if let url = URL(string: "https://scriptseer.app/terms") {
                    Link("Terms", destination: url)
                }
            }
            .font(SSTypography.caption)
            .foregroundStyle(SSColors.textTertiary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .animation(reduceMotion ? nil : SSAnimation.smooth.delay(0.90), value: appeared)
    }

    // MARK: - Active Pro

    private var activeProView: some View {
        VStack(spacing: SSSpacing.xl) {
            // Close button row
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SSColors.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
            }
            .padding(.horizontal, SSSpacing.md)
            .padding(.top, SSSpacing.xs)

            Spacer()

            VStack(spacing: SSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.green)
                }

                Text(store.hasActiveTrialInfo ?? "Pro Active")
                    .font(SSTypography.title2)
                    .foregroundStyle(SSColors.textPrimary)

                Text("You have access to all ScriptSeer features.")
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("Manage Subscription") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .font(SSTypography.subheadline)
            .foregroundStyle(SSColors.accent)
            .padding(.bottom, SSSpacing.xl)
        }
        .padding(.horizontal, SSSpacing.md)
    }

    // MARK: - Purchase

    private func purchaseSelected() async {
        let product: Product?
        switch selectedPlan {
        case .monthly: product = store.monthlyProduct
        case .annual: product = store.annualProduct
        }
        guard let product else {
            store.errorMessage = "Product not available"
            showError = true
            return
        }
        do {
            try await store.purchase(product)
        } catch {
            store.errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: SSSpacing.xs) {
                // Badge or spacer
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(SSColors.accent))
                } else {
                    Color.clear.frame(height: 18)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SSColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(price)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(SSColors.textPrimary)
                    Text(period)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SSColors.textTertiary)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SSColors.accent)
                } else {
                    Color.clear.frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .padding(.vertical, SSSpacing.md)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: SSRadius.lg)
                        .fill(SSColors.surfaceElevated)
                    if isSelected {
                        RoundedRectangle(cornerRadius: SSRadius.lg)
                            .fill(SSColors.accent.opacity(0.04))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.lg)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(
                                AngularGradient(
                                    colors: [SSColors.accent, SSColors.accent.opacity(0.4), SSColors.accent],
                                    center: .center
                                )
                            )
                            : AnyShapeStyle(SSColors.divider),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? SSColors.accent.opacity(0.25) : .clear, radius: 16, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.06 : 0.95)
            .opacity(isSelected ? 1 : 0.7)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animation Modifiers

private struct BreathingPulseModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double

    @State private var active = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1.0 : (active ? maxScale : minScale))
            .opacity(reduceMotion ? 1.0 : (active ? maxOpacity : minOpacity))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    active = true
                }
            }
    }
}

private struct TiltingDiscModifier: ViewModifier {
    let duration: Double

    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let xTilt = sin(time * (2 * .pi / duration)) * 12
            let yTilt = cos(time * (2 * .pi / (duration * 0.7))) * 8

            content
                .rotation3DEffect(.degrees(xTilt), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
                .rotation3DEffect(.degrees(yTilt), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        }
    }
}

