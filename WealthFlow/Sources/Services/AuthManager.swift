import Foundation
import Observation

@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()
    
    var isAuthenticated = false
    var user: User?
    var isLoading = false
    var errorMessage: String?
    
    private init() {
        checkAuth()
    }
    
    func checkAuth() {
        guard let token = KeychainManager.shared.getToken() else {
            isAuthenticated = false
            return
        }
        Task {
            do {
                let user: User = try await APIClient.shared.get("/auth/me")
                await MainActor.run {
                    self.user = user
                    self.isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    self.logout()
                }
            }
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            try KeychainManager.shared.saveToken(response.token)
            await MainActor.run {
                self.user = response.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIClient.shared.register(email: email, password: password, name: name)
            try KeychainManager.shared.saveToken(response.token)
            await MainActor.run {
                self.user = response.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        KeychainManager.shared.deleteToken()
        user = nil
        isAuthenticated = false
        errorMessage = nil
    }
}
