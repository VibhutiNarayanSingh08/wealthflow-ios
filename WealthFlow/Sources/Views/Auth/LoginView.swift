import SwiftUI

struct LoginView: View {
    @State private var authManager = AuthManager.shared
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#6366f1"), Color(hex: "#9333ea")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
                
                Text("WealthFlow")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#818cf8"), Color(hex: "#c084fc")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your personal finance companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isRegistering ? "Get started" : "Welcome back")
                        .font(.title2.bold())
                    
                    Text(isRegistering ? "Create your free account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isRegistering {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(AuthTextFieldStyle())
                }
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(AuthTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textContentType(isRegistering ? .newPassword : .password)
                    .textFieldStyle(AuthTextFieldStyle())
                
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
                Button {
                    Task {
                        if isRegistering {
                            await authManager.register(email: email, password: password, name: name)
                        } else {
                            await authManager.login(email: email, password: password)
                        }
                    }
                } label: {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isRegistering ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#6366f1"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authManager.isLoading || email.isEmpty || password.count < 6)
                
                Button {
                    isRegistering.toggle()
                    authManager.errorMessage = nil
                } label: {
                    Text(isRegistering ? "Already have an account? Sign in" : "Don't have an account? Create one")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#818cf8"))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10)
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}
