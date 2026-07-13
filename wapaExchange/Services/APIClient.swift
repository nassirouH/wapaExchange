import Foundation

enum APIEnvironment {
    static let baseURL = URL(string: "https://api.wapaexchange.com/v1")!
    static let useMock = true
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case decoding(Error)
    case server(status: Int, message: String?)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .transport(let e): e.localizedDescription
        case .decoding: "Could not read the server response."
        case .server(_, let msg): msg ?? "Something went wrong on our end."
        case .unauthorized: "Your session expired. Please sign in again."
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        dec.keyDecodingStrategy = .useDefaultKeys
        self.decoder = dec

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
    }

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try await request(path: path, method: "GET", body: Optional<EmptyBody>.none, as: type)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        try await request(path: path, method: "POST", body: body, as: type)
    }

    func patch<T: Decodable, B: Encodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        try await request(path: path, method: "PATCH", body: body, as: type)
    }

    func delete(_ path: String) async throws {
        _ = try await request(path: path, method: "DELETE", body: Optional<EmptyBody>.none, as: EmptyBody.self)
    }

    private func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B?,
        as type: T.Type
    ) async throws -> T {
        let url = APIEnvironment.baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = await KeychainHelper.shared.getAccessToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(status: 0, message: nil)
        }

        switch http.statusCode {
        case 200...299:
            if T.self == EmptyBody.self { return EmptyBody() as! T }
            do { return try decoder.decode(T.self, from: data) }
            catch { throw APIError.decoding(error) }
        case 401:
            throw APIError.unauthorized
        default:
            let msg = String(data: data, encoding: .utf8)
            throw APIError.server(status: http.statusCode, message: msg)
        }
    }
}

struct EmptyBody: Codable {}
