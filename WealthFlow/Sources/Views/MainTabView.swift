import SwiftUI

struct MainTabView: View {
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "creditcard")
                }
            
            InvestmentsView()
                .tabItem {
                    Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "chart.pie")
                }
        }
        .tint(Color(hex: "#6366f1"))
    }
}
