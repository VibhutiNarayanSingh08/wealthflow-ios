import Foundation
import Observation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code, let msg): return "Error \(code): \(msg)"
        case .decodingError: return "Failed to decode response"
        }
    }
}

@Observable
final class APIClient {
    nonisolated(unsafe) static let shared = APIClient()
    
    // CHANGE THIS TO YOUR PRODUCTION BACKEND URL
    #if DEBUG
    let baseURL = "http://localhost:8000"
    #else
    let baseURL = "https://wealthflow-api-rz5w.onrender.com"
    #endif
    
    private var token: String? {
        KeychainManager.shared.getToken()
    }
    
    private func request(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(httpResponse.statusCode, message)
        }
        
        return data
    }
    
    func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await request(path: path)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func post<T: Decodable>(_ path: String, body: Encodable) async throws -> T {
        let data = try await request(path: path, method: "POST", body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func post(_ path: String, body: Encodable) async throws {
        _ = try await request(path: path, method: "POST", body: body)
    }
    
    func delete(_ path: String) async throws {
        _ = try await request(path: path, method: "DELETE")
    }
}

// MARK: - Auth Endpoints
extension APIClient {
    func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/auth/login", body: LoginRequest(email: email, password: password))
    }
    
    func register(email: String, password: String, name: String) async throws -> AuthResponse {
        try await post("/auth/register", body: RegisterRequest(email: email, password: password, name: name))
    }
    
    func getMe() async throws -> User {
        try await get("/auth/me")
    }
}

// MARK: - Expense Endpoints
extension APIClient {
    func getExpenses() async throws -> [Expense] {
        try await get("/api/expenses")
    }
    
    func createExpense(_ expense: Expense) async throws {
        try await post("/api/expenses", body: expense)
    }
    
    func deleteExpense(id: Double) async throws {
        try await delete("/api/expenses/\(id)")
    }
}

// MARK: - Investment Endpoints
extension APIClient {
    func getInvestments() async throws -> [Investment] {
        try await get("/api/investments")
    }
    
    func createInvestment(_ investment: Investment) async throws {
        try await post("/api/investments", body: investment)
    }
    
    func deleteInvestment(id: Double) async throws {
        try await delete("/api/investments/\(id)")
    }
}

// MARK: - Budget Endpoints
extension APIClient {
    func getBudgets() async throws -> [Budget] {
        try await get("/api/budgets")
    }
    
    func createBudget(_ budget: Budget) async throws {
        try await post("/api/budgets", body: budget)
    }
    
    func deleteBudget(id: Double) async throws {
        try await delete("/api/budgets/\(id)")
    }
}

// MARK: - Recurring Endpoints
extension APIClient {
    func getRecurring() async throws -> [RecurringExpense] {
        try await get("/api/recurring")
    }
    
    func createRecurring(_ rec: RecurringExpense) async throws {
        try await post("/api/recurring", body: rec)
    }
    
    func deleteRecurring(id: Double) async throws {
        try await delete("/api/recurring/\(id)")
    }
    
    func markRecurringPaid(id: Double) async throws {
        try await post("/api/recurring/\(id)/paid", body: EmptyBody())
    }
}

struct EmptyBody: Codable {}
