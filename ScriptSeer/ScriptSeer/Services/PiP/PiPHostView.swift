import SwiftUI
import AVFoundation

struct PiPHostView: UIViewRepresentable {
    let service: PiPTeleprompterService

    func makeUIView(context: Context) -> PiPContainerView {
        let view = PiPContainerView()
        view.configure(with: service.displayLayer)
        return view
    }

    func updateUIView(_ uiView: PiPContainerView, context: Context) {
    }
}

class PiPContainerView: UIView {

    private var displayLayer: AVSampleBufferDisplayLayer?

    func configure(with layer: AVSampleBufferDisplayLayer) {
        guard displayLayer == nil else { return }
        displayLayer = layer
        layer.frame = bounds
        self.layer.addSublayer(layer)
        // Near-invisible — real teleprompter is shown by SwiftUI
        alpha = 0.01
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        displayLayer?.frame = bounds
    }
}
