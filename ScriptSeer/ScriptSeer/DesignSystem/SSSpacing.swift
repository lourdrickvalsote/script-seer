import SwiftUI

enum SSSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

enum SSRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 100
}

enum SSAnimation {
    static let quick: Animation = .easeInOut(duration: 0.15)
    static let standard: Animation = .easeInOut(duration: 0.25)
    static let smooth: Animation = .easeInOut(duration: 0.35)
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.8)
}
