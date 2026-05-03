import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let name: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name
        case createdAt = "created_at"
    }
    
    var displayName: String {
        name ?? email.components(separatedBy: "@").first ?? "User"
    }
    
    var initials: String {
        let parts = displayName.split(separator: " ")
        let chars = parts.prefix(2).map { String($0.prefix(1)) }
        return chars.joined().uppercased()
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}
