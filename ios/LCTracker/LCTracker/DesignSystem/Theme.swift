import SwiftUI

/// The locked visual language from the design's `wireframe-kit.jsx` tokens:
/// a refined near-grayscale palette + a SINGLE cool-blue accent spent only on
/// signal (comfort, due/overdue, "new", in-review). Difficulty is a grayscale
/// ordinal so the two colored signals never collide; primary actions stay ink.
enum WF {
    // Neutrals
    static let ink = Color(hex: 0x15171c)    // primary text / primary action
    static let ink2 = Color(hex: 0x545a63)   // secondary text
    static let ink3 = Color(hex: 0x949aa3)   // muted / placeholder
    static let line = Color(hex: 0xdbdee2)    // borders
    static let line2 = Color(hex: 0xeceef0)   // hairline
    static let fill = Color(hex: 0xeef0f2)    // placeholder / track
    static let fill2 = Color(hex: 0xf6f7f8)   // subtle surface
    static let card = Color.white
    static let bg = Color(hex: 0xf3f5f7)

    // The one signal hue
    static let accent = Color(hex: 0x3a5bd0)
    static let accentText = Color(hex: 0x33489f)
    static let accentBg = Color(hex: 0xedf0fb)
    static let accentLine = Color(hex: 0xcdd6f2)
    static let accentMute = Color(hex: 0xaeb9e0)

    // Corner radii
    static let r1: CGFloat = 8
    static let r2: CGFloat = 11
    static let r3: CGFloat = 14
    static let r4: CGFloat = 18
}

/// Typography — IBM Plex Sans (bundled variable font) + IBM Plex Mono (static).
/// Sizes map the design's px values to fixed points (no Dynamic Type scaling) so
/// the dense wireframe layout reproduces faithfully. Missing fonts fall back to
/// the system font automatically.
enum Typo {
    static func sans(_ size: CGFloat, _ weight: Int = 400) -> Font {
        Font.custom(sansName(weight), fixedSize: size)
    }
    static func mono(_ size: CGFloat, _ weight: Int = 400) -> Font {
        Font.custom(monoName(weight), fixedSize: size)
    }

    private static func sansName(_ w: Int) -> String {
        switch w {
        case ..<450: return "IBMPlexSans-Regular"
        case 450..<550: return "IBMPlexSans-Medium"
        case 550..<680: return "IBMPlexSans-SemiBold"
        default: return "IBMPlexSans-Bold"
        }
    }
    private static func monoName(_ w: Int) -> String {
        switch w {
        case ..<450: return "IBMPlexMono-Regular"
        case 450..<550: return "IBMPlexMono-Medium"
        default: return "IBMPlexMono-SemiBold"
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
