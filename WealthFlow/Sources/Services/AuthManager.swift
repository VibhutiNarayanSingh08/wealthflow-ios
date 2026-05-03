import Foundation
import Observation

@Observable
final class AuthManager {
    static let shared = AuthManager()

    var isAuthenticated = false
    var user: User?
    var isLoading = false
    var errorMessage: String?

    private var validationTask: Task<Void, Never>?

    private init() {
        checkAuth()
    }

    func checkAuth() {
        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            isAuthenticated = false
            return
        }
        // Cancel any previous validation task to prevent race conditions
        validationTask?.cancel()
        validationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let user: User = try await APIClient.shared.get("/auth/me")
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.user = user
                    self.isAuthenticated = true
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.logout()
                }
            }
        }
    }

    func login(email: String, password: String) async {
        validationTask?.cancel()
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            let response = try await APIClient.shared.login(email: email, password: password)
            let saved = KeychainManager.shared.saveToken(response.token)
            print("[WealthFlow] Token save result: \(saved)")
            guard saved else {
                await MainActor.run {
                    self.errorMessage = "Failed to save login token. Please try again."
                    self.isLoading = false
                }
                return
            }
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
        validationTask?.cancel()
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            let response = try await APIClient.shared.register(email: email, password: password, name: name)
            let saved = KeychainManager.shared.saveToken(response.token)
            print("[WealthFlow] Token save result: \(saved)")
            guard saved else {
                await MainActor.run {
                    self.errorMessage = "Failed to save registration token. Please try again."
                    self.isLoading = false
                }
                return
            }
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
        validationTask?.cancel()
        _ = KeychainManager.shared.deleteToken()
        user = nil
        isAuthenticated = false
        errorMessage = nil
    }
}
