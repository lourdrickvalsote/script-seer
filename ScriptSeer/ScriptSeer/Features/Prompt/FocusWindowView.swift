import SwiftUI

struct FocusWindowView: View {
    let lines: [String]
    let currentLineIndex: Int
    let config: FocusWindowConfig
    let theme: PromptTheme
    let textSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let yPosition = geometry.size.height * config.verticalOffset

            VStack(spacing: config.preset.lineSpacing) {
                // Past context (de-emphasized)
                ForEach(contextBefore, id: \.self) { line in
                    richText(line, size: textSize * 0.85, color: theme.textColor.opacity(config.deemphasizePastFuture ? 0.25 : 0.6))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                }

                // Current line (highlighted)
                if let currentLine {
                    richText(currentLine, size: textSize, color: theme.textColor)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .shadow(color: config.highlightCurrent ? theme.textColor.opacity(0.3) : .clear, radius: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentLine)
                }

                // Future context (de-emphasized)
                ForEach(contextAfter, id: \.self) { line in
                    richText(line, size: textSize * 0.85, color: theme.textColor.opacity(config.deemphasizePastFuture ? 0.3 : 0.6))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, config.preset.horizontalMargin)
            .frame(width: geometry.size.width)
            .position(x: geometry.size.width / 2, y: yPosition)
        }
    }

    private func richText(_ content: String, size: CGFloat, color: Color) -> Text {
        let segments = CueParser.parse(content)
        var result = Text("")
        for segment in segments {
            switch segment.kind {
            case .cue(let cue):
                result = result + Text(" \(cue.displaySymbol) ")
                    .font(.system(size: size * 0.7))
                    .foregroundColor(cue.promptColor)
            case .speaker(let name):
                result = result + Text("\(name.uppercased()): ")
                    .font(.system(size: size * 0.8, weight: .bold))
                    .foregroundColor(SSColors.accent)
            case .section(let title):
                result = result + Text("— \(title) — ")
                    .font(.system(size: size * 0.75, weight: .semibold))
                    .foregroundColor(SSColors.silverSage)
            case .text:
                result = result + Text(segment.content)
                    .font(SSTypography.promptText(size: size))
                    .foregroundColor(color)
            }
        }
        return result
    }

    private var currentLine: String? {
        guard currentLineIndex >= 0, currentLineIndex < lines.count else { return nil }
        return lines[currentLineIndex]
    }

    private var contextBefore: [String] {
        let start = max(0, currentLineIndex - config.contextLinesBefore)
        let end = currentLineIndex
        guard start < end, end <= lines.count else { return [] }
        return Array(lines[start..<end])
    }

    private var contextAfter: [String] {
        let start = currentLineIndex + 1
        let end = min(lines.count, start + config.contextLinesAfter)
        guard start < end else { return [] }
        return Array(lines[start..<end])
    }
}

// MARK: - Preset Picker

struct GlancePresetPicker: View {
    @Binding var selectedPreset: GlancePreset
    let onSelect: (GlancePreset) -> Void

    var body: some View {
        VStack(spacing: SSSpacing.sm) {
            Text("Reading Preset")
                .font(SSTypography.headline)
                .foregroundStyle(.white)

            ForEach(GlancePreset.allCases, id: \.self) { preset in
                Button(action: {
                    selectedPreset = preset
                    onSelect(preset)
                    SSHaptics.selection()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: SSSpacing.xxs) {
                            Text(preset.rawValue)
                                .font(SSTypography.headline)
                                .foregroundStyle(selectedPreset == preset ? SSColors.accent : .white)
                            Text(preset.description)
                                .font(SSTypography.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        if selectedPreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SSColors.accent)
                        }
                    }
                    .padding(SSSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: SSRadius.sm)
                            .fill(selectedPreset == preset ? SSColors.accentSubtle : SSColors.surfaceGlass)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
