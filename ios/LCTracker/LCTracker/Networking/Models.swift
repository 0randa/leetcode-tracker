import Foundation

// Codable mirrors of the backend DTOs (dev.lctracker.backend.web.Dtos.kt).
// Enum-like fields use the exact Kotlin constant names Jackson serializes.
// Date fields stay as the raw server strings (LocalDate "2026-06-01",
// Instant ISO-8601) and are formatted for display in the view layer.

enum Difficulty: String, Codable, CaseIterable {
    case easy = "EASY", medium = "MEDIUM", hard = "HARD"

    /// Title-case label matching the design ("Easy" / "Medium" / "Hard").
    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    /// Grayscale ordinal: filled segments out of three.
    var level: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

enum ProgressStatus: String, Codable {
    case todo = "TODO", review = "REVIEW", mastered = "MASTERED"

    /// Design label ("To do" / "In review" / "Mastered").
    var label: String {
        switch self {
        case .todo: return "To do"
        case .review: return "In review"
        case .mastered: return "Mastered"
        }
    }
}

enum TopicRating: String, Codable {
    case comfortable = "COMFORTABLE", shaky = "SHAKY", notTried = "NOT_TRIED"

    /// Design label ("Comfortable" / "Shaky" / "Not tried").
    var label: String {
        switch self {
        case .comfortable: return "Comfortable"
        case .shaky: return "Shaky"
        case .notTried: return "Not tried"
        }
    }

    init?(label: String) {
        switch label {
        case "Comfortable": self = .comfortable
        case "Shaky": self = .shaky
        case "Not tried": self = .notTried
        default: return nil
        }
    }
}

enum SessionOutcome: String, Codable {
    case solvedClean = "SOLVED_CLEAN", solvedHints = "SOLVED_HINTS", didntSolve = "DIDNT_SOLVE"

    /// Design label ("Solved cleanly" / "Solved with hints" / "Didn't solve").
    var label: String {
        switch self {
        case .solvedClean: return "Solved cleanly"
        case .solvedHints: return "Solved with hints"
        case .didntSolve: return "Didn't solve"
        }
    }

    init?(label: String) {
        switch label {
        case "Solved cleanly": self = .solvedClean
        case "Solved with hints": self = .solvedHints
        case "Didn't solve", "Didn’t solve": self = .didntSolve
        default: return nil
        }
    }
}

enum DueState: String, Codable {
    case overdue = "OVERDUE", due = "DUE", soon = "SOON", scheduled = "SCHEDULED"
}

struct DueInfo: Codable, Hashable {
    let state: DueState
    let days: Int
    let text: String
}

struct ProblemSummary: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let difficulty: Difficulty
    let topics: [String]
    let status: ProgressStatus
    let comfort: Int
    let lcUrl: String

    /// Primary topic tag shown on cards/rows.
    var topic: String { topics.first ?? "" }
}

struct TodayCard: Codable, Hashable {
    let kind: String   // "Review" | "New"
    let due: DueInfo?
    let problem: ProblemSummary

    var isNew: Bool { kind == "New" }
}

struct Today: Codable {
    let date: String
    let reviewCount: Int
    let newCount: Int
    let estimatedMinutes: Int
    let streak: Int
    let totalSolved: Int
    let set: [TodayCard]
}

struct Session: Codable, Hashable {
    let date: String
    let outcome: SessionOutcome
    let peeked: Bool
    let timeTakenMin: Int?
    let timeComplexity: String?
    let spaceComplexity: String?
    let comfort: Double?
}

struct ProblemDetail: Codable {
    let id: Int
    let slug: String
    let title: String
    let difficulty: Difficulty
    let topics: [String]
    let status: ProgressStatus
    let comfort: Int
    let comfortTrend: [Double]
    let nextReview: DueInfo?
    let lcUrl: String
    let history: [Session]

    var topic: String { topics.first ?? "" }
}

struct ScheduleResult: Codable {
    let stageFrom: Int
    let stageTo: Int
    let comfortFrom: Double
    let comfortTo: Double
    let intervalDays: Int
    let reviewDate: String
    let dueText: String
    let status: ProgressStatus
    let advanced: Bool
    let slipped: Bool
}

struct LogSessionRequest: Codable {
    let outcome: SessionOutcome
    var peeked: Bool = false
    var timeTakenMin: Int? = nil
    var timeComplexity: String? = nil
    var spaceComplexity: String? = nil
}

struct TopicRatingDTO: Codable {
    let category: String
    let rating: TopicRating
}

struct OnboardingRequest: Codable {
    let ratings: [TopicRatingDTO]
}

struct ResolveResponse: Codable {
    let found: Bool
    let matches: [ProblemSummary]
    let note: String?
}

struct TopicComfort: Codable, Hashable {
    let topic: String
    let score: Double
    let count: Int
}

struct Analytics: Codable {
    let streak: Int
    let totalSolved: Int
    let topics: [TopicComfort]
    let weekly: [Int]
}
