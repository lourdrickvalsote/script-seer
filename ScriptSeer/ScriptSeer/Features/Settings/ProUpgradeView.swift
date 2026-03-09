import SwiftUI
import StoreKit

struct ProUpgradeView: View {
    @State private var store = StoreManager.shared
    @State private var selectedPlan: PlanType = .annual
    @State private var showError = false

    enum PlanType {
        case monthly, annual
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SSSpacing.xl) {
                // Hero
                VStack(spacing: SSSpacing.md) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(SSColors.accent)

                    Text("ScriptSeer Pro")
                        .font(SSTypography.largeTitle)
                        .foregroundStyle(SSColors.textPrimary)

                    Text("Unlock the full teleprompter experience")
                        .font(SSTypography.subheadline)
                        .foregroundStyle(SSColors.textSecondary)

                    if store.isProUser {
                        HStack(spacing: SSSpacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text(store.hasActiveTrialInfo ?? "Pro Active")
                                .font(SSTypography.subheadline)
                                .foregroundStyle(.green)
                        }
                        .padding(.top, SSSpacing.xs)
                    }
                }
                .padding(.top, SSSpacing.xl)

                // Features
                VStack(alignment: .leading, spacing: SSSpacing.md) {
                    ProFeatureRow(icon: "wand.and.stars", title: "AI Script Actions", subtitle: "Shorten, simplify, rewrite, and optimize scripts")
                    ProFeatureRow(icon: "waveform", title: "Speech Follow", subtitle: "Hands-free script advancement with voice")
                    ProFeatureRow(icon: "camera.fill", title: "Camera Overlay", subtitle: "Record with script overlay for eye contact")
                    ProFeatureRow(icon: "chart.bar", title: "Practice Analytics", subtitle: "Detailed feedback on your rehearsals")
                    ProFeatureRow(icon: "paintpalette", title: "Custom Themes", subtitle: "Additional high-contrast display themes")
                    ProFeatureRow(icon: "tv", title: "External Display", subtitle: "Output to AirPlay, HDMI, and monitors")
                }
                .padding(.horizontal, SSSpacing.md)

                if !store.isProUser {
                    // Plan selection
                    VStack(spacing: SSSpacing.sm) {
                        // Monthly plan
                        PlanCard(
                            title: "Monthly",
                            price: store.monthlyProduct?.displayPrice ?? "$4.99",
                            period: "/month",
                            isSelected: selectedPlan == .monthly,
                            badge: nil
                        ) {
                            selectedPlan = .monthly
                        }

                        // Annual plan
                        PlanCard(
                            title: "Annual",
                            price: store.annualProduct?.displayPrice ?? "$39.99",
                            period: "/year",
                            isSelected: selectedPlan == .annual,
                            badge: "Save 33%"
                        ) {
                            selectedPlan = .annual
                        }
                    }
                    .padding(.horizontal, SSSpacing.md)

                    // CTA
                    VStack(spacing: SSSpacing.sm) {
                        SSButton("Start Free Trial", icon: "star.fill", variant: .primary) {
                            Task { await purchaseSelected() }
                        }
                        .disabled(store.isLoading)

                        Text("7-day free trial, then auto-renews")
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textTertiary)

                        Text("Basic features always free. No lock-out.")
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textTertiary)

                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.accent)
                        .padding(.top, SSSpacing.xs)

                        HStack(spacing: SSSpacing.md) {
                            if let privacyURL = URL(string: "https://scriptseer.app/privacy") {
                                Link("Privacy Policy", destination: privacyURL)
                            }
                            Text("·").foregroundStyle(SSColors.textTertiary)
                            if let termsURL = URL(string: "https://scriptseer.app/terms") {
                                Link("Terms of Service", destination: termsURL)
                            }
                        }
                        .font(SSTypography.caption)
                        .foregroundStyle(SSColors.textTertiary)
                        .padding(.top, SSSpacing.xs)
                    }
                    .padding(.horizontal, SSSpacing.md)
                }

                // Subscription management
                if store.isProUser {
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(SSTypography.subheadline)
                    .foregroundStyle(SSColors.accent)
                }
            }
        }
        .background(SSColors.background)
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(store.errorMessage ?? "Something went wrong. Please try again.")
        }
    }

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
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            SSHaptics.selection()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: SSSpacing.xxxs) {
                    HStack {
                        Text(title)
                            .font(SSTypography.headline)
                            .foregroundStyle(SSColors.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(SSColors.lavenderMist)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SSColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    HStack(spacing: 0) {
                        Text(price)
                            .font(SSTypography.subheadline)
                            .foregroundStyle(SSColors.textPrimary)
                        Text(period)
                            .font(SSTypography.caption)
                            .foregroundStyle(SSColors.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? SSColors.accent : SSColors.textTertiary)
                    .font(.system(size: 22))
            }
            .padding(SSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: SSRadius.md)
                    .fill(SSColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: SSRadius.md)
                    .stroke(isSelected ? SSColors.accent : SSColors.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: SSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(SSColors.accent)
                .frame(width: 40, height: 40)
                .background(SSColors.accentSubtle)
                .clipShape(RoundedRectangle(cornerRadius: SSRadius.sm))

            VStack(alignment: .leading, spacing: SSSpacing.xxxs) {
                Text(title)
                    .font(SSTypography.headline)
                    .foregroundStyle(SSColors.textPrimary)
                Text(subtitle)
                    .font(SSTypography.caption)
                    .foregroundStyle(SSColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
