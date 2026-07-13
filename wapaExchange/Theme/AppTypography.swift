import SwiftUI

enum AppTypography {
    static func largeTitle() -> Font { .system(size: 32, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 24, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func bodyBold() -> Font { .system(size: 16, weight: .semibold) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func amount() -> Font { .system(size: 44, weight: .bold, design: .rounded) }
}
