import SwiftUI

/// Minimal teleprompter view for external displays (AirPlay/HDMI)
/// Paragraph mode only — no controls, no overlays, just clean readable text
struct ExternalPromptView: View {
    var session: PromptSession
    var externalDisplay: ExternalDisplayManager

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: session.lineSpacing) {
                    // Top spacer — text starts mid-screen (standard teleprompter behavior)
                    Spacer().frame(height: geometry.size.height / 2)

                    Text(session.script.content)
                        .font(SSTypography.promptText(size: session.textSize))
                        .foregroundStyle(session.theme.textColor)
                        .lineSpacing(session.lineSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Bottom padding
                    Spacer().frame(height: geometry.size.height)
                }
                .padding(.horizontal, session.horizontalMargin)
                .frame(width: geometry.size.width)
            }
            .offset(y: -session.scrollOffset)
            .scaleEffect(x: externalDisplay.independentMirror ? -1 : 1, y: 1)
        }
        .background(session.theme.backgroundColor)
        .ignoresSafeArea()
    }
}
