//
//  APIClient.swift
//  LaSalleFoods
//
//  Cliente HTTP único hacia el backend Java (`/api/...`). Reemplaza al
//  cliente de Supabase: el backend reenvía a Supabase Auth/PostgREST por
//  debajo, así que los JSON que devuelve son los mismos que antes.
//

import Foundation

enum APIError: Error, LocalizedError {
    case server(status: Int, message: String)
    case decoding(Error)
    case encoding(Error)
    case network(Error)
    case unauthorized
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(_, let message): return message
        case .decoding: return "No se pudo leer la respuesta del servidor."
        case .encoding: return "No se pudo preparar la solicitud."
        case .network(let error): return error.localizedDescription
        case .unauthorized: return "Tu sesión expiró. Vuelve a iniciar sesión."
        case .invalidResponse: return "Respuesta inválida del servidor."
        }
    }
}

/// Body vacío para endpoints que ignoran el contenido (cancel, mark-read, logout).
struct EmptyBody: Encodable {}

enum APIClient {
    /// Backend Java en Azure Container Apps.
    static let baseURL = URL(string: "https://lasallefoods-backend.blackbay-608b8ac9.eastus2.azurecontainerapps.io/api")!

    // MARK: - Tokens

    static var accessToken: String? {
        get { KeychainStore.read(.accessToken) }
        set { KeychainStore.save(.accessToken, value: newValue) }
    }

    static var refreshToken: String? {
        get { KeychainStore.read(.refreshToken) }
        set { KeychainStore.save(.refreshToken, value: newValue) }
    }

    static func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }

    // MARK: - Codificación

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()

        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        withoutFraction.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFraction.date(from: raw) ?? withoutFraction.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Fecha inválida: \(raw)")
        }
        return decoder
    }()

    private static let encoder = JSONEncoder()

    // MARK: - API pública

    static func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let data = try await send(path: path, method: "GET", query: query)
        return try decode(T.self, from: data)
    }

    static func post<Body: Encodable, T: Decodable>(_ path: String, body: Body, authenticated: Bool = true) async throws -> T {
        let data = try await send(path: path, method: "POST", bodyData: try encode(body), authenticated: authenticated)
        return try decode(T.self, from: data)
    }

    @discardableResult
    static func postNoContent<Body: Encodable>(_ path: String, body: Body, authenticated: Bool = true) async throws -> Data {
        try await send(path: path, method: "POST", bodyData: try encode(body), authenticated: authenticated)
    }

    @discardableResult
    static func patchNoContent<Body: Encodable>(_ path: String, body: Body) async throws -> Data {
        try await send(path: path, method: "PATCH", bodyData: try encode(body))
    }

    @discardableResult
    static func putNoContent<Body: Encodable>(_ path: String, body: Body) async throws -> Data {
        try await send(path: path, method: "PUT", bodyData: try encode(body))
    }

    @discardableResult
    static func delete(_ path: String) async throws -> Data {
        try await send(path: path, method: "DELETE")
    }

    // MARK: - Privado

    private static func encode<Body: Encodable>(_ body: Body) throws -> Data {
        do { return try encoder.encode(body) } catch { throw APIError.encoding(error) }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) } catch { throw APIError.decoding(error) }
    }

    /// Envía la petición; si responde 401 intenta refrescar el access token
    /// una sola vez y reintenta antes de fallar.
    private static func send(
        path: String,
        method: String,
        query: [URLQueryItem] = [],
        bodyData: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Data {
        let (data, response) = try await perform(path: path, method: method, query: query, bodyData: bodyData, authenticated: authenticated)

        if response.statusCode == 401 && authenticated {
            guard await refreshSession() else {
                clearTokens()
                throw APIError.unauthorized
            }
            let (retryData, retryResponse) = try await perform(path: path, method: method, query: query, bodyData: bodyData, authenticated: authenticated)
            return try validate(retryData, retryResponse)
        }

        return try validate(data, response)
    }

    private static func perform(
        path: String,
        method: String,
        query: [URLQueryItem],
        bodyData: Data?,
        authenticated: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        var url = baseURL.appendingPathComponent(path)
        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = query
            url = components.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let bodyData {
            request.httpBody = bodyData
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error)
        }
    }

    private static func validate(_ data: Data, _ response: HTTPURLResponse) throws -> Data {
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.server(status: response.statusCode, message: serverErrorMessage(from: data))
        }
        return data
    }

    private static func serverErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["error_description"] as? String { return message }
            if let message = json["msg"] as? String { return message }
            if let message = json["message"] as? String { return message }
        }
        return String(data: data, encoding: .utf8)?.isEmpty == false
            ? String(data: data, encoding: .utf8)!
            : "Ocurrió un error inesperado."
    }

    /// Pide un nuevo `access_token`/`refresh_token` con el `refresh_token`
    /// guardado. Devuelve `false` si no hay refresh token o si falla.
    @discardableResult
    static func refreshSession() async -> Bool {
        guard let refreshToken else { return false }
        struct RefreshBody: Encodable { let refresh_token: String }
        do {
            let bodyData = try encode(RefreshBody(refresh_token: refreshToken))
            let (data, response) = try await perform(path: "auth/refresh", method: "POST", query: [], bodyData: bodyData, authenticated: false)
            guard (200..<300).contains(response.statusCode) else { return false }
            let session = try decode(AuthSession.self, from: data)
            guard let access = session.accessToken, let refresh = session.refreshToken else { return false }
            accessToken = access
            self.refreshToken = refresh
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Modelos de Supabase Auth (GoTrue)

/// Respuesta de `/api/auth/login`, `/api/auth/register` (con sesión) y
/// `/api/auth/refresh`.
struct AuthSession: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let user: AuthUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Respuesta de `/api/auth/me` (y el campo `user` de `AuthSession`).
struct AuthUser: Decodable {
    let id: UUID
    let email: String?
}
