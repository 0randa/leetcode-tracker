import Foundation

/// Thin async HTTP/JSON client over the backend. The client never touches a
/// database or LeetCode directly — every read and write goes through this API.
enum APIError: LocalizedError {
    case badStatus(Int)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "Server returned \(code)."
        case .transport(let e): return e.localizedDescription
        case .decoding: return "Couldn't read the server response."
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    /// Where the backend lives. Resolution order:
    ///   1. `LCTRACKER_API_BASE` env var (set in the Xcode scheme for dev runs),
    ///   2. the `APIBaseURL` Info.plist key (so untethered device installs work),
    ///   3. `http://localhost:8080` (simulator default).
    /// On a physical device set `APIBaseURL` to the Mac's LAN IP (same WiFi) or a
    /// hosted HTTPS URL once deployed.
    private let baseURL: URL

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        let env = ProcessInfo.processInfo.environment["LCTRACKER_API_BASE"]
        let plist = (Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String)?
            .trimmingCharacters(in: .whitespaces)
        let configured = [env, plist].compactMap { $0 }.first { !$0.isEmpty }
        self.baseURL = URL(string: configured ?? "http://localhost:8080")!
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: cfg)
    }

    // MARK: - Reads

    func today() async throws -> Today {
        try await get("/api/today")
    }

    func problems(search: String? = nil, topic: String? = nil,
                  difficulty: Difficulty? = nil, status: ProgressStatus? = nil) async throws -> [ProblemSummary] {
        var items: [URLQueryItem] = []
        if let search, !search.isEmpty { items.append(.init(name: "search", value: search)) }
        if let topic, !topic.isEmpty { items.append(.init(name: "topic", value: topic)) }
        if let difficulty { items.append(.init(name: "difficulty", value: difficulty.rawValue)) }
        if let status { items.append(.init(name: "status", value: status.rawValue)) }
        return try await get("/api/problems", query: items)
    }

    func detail(id: Int) async throws -> ProblemDetail {
        try await get("/api/problems/\(id)")
    }

    func topics() async throws -> [String] {
        try await get("/api/topics")
    }

    func resolve(query: String) async throws -> ResolveResponse {
        try await get("/api/resolve", query: [.init(name: "query", value: query)])
    }

    func analytics() async throws -> Analytics {
        try await get("/api/analytics")
    }

    // MARK: - Writes

    func logSession(problemId: Int, body: LogSessionRequest) async throws -> ScheduleResult {
        try await post("/api/problems/\(problemId)/sessions", body: body)
    }

    func previewSession(problemId: Int, body: LogSessionRequest) async throws -> ScheduleResult {
        try await post("/api/problems/\(problemId)/sessions/preview", body: body)
    }

    func submitOnboarding(_ body: OnboardingRequest) async throws {
        let _: EmptyResponse = try await post("/api/onboarding", body: body)
    }

    // MARK: - Plumbing

    private func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { comps.queryItems = query }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        return try await send(req)
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let data: Data, response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error)
        }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode)
        }
        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

/// Placeholder for endpoints that return no body (or a body we ignore).
struct EmptyResponse: Decodable {
    init() {}
    init(from decoder: Decoder) throws {}
}
