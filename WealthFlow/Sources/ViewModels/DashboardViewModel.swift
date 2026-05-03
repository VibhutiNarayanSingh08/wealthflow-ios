import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var expenses: [Expense] = []
    var investments: [Investment] = []
    var budgets: [Budget] = []
    var isLoading = false
    var errorMessage: String?
    
    var totalInvested: Double {
        investments.reduce(0) { $0 + $1.invested }
    }
    
    var totalPortfolioValue: Double {
        investments.reduce(0) { $0 + $1.currentValue }
    }
    
    var netWorth: Double {
        totalPortfolioValue + availableCash
    }
    
    var availableCash: Double {
        // Simplified: assume some cash based on income vs expenses
        50000 - monthlyExpenses
    }
    
    var monthlyExpenses: Double {
        let calendar = Calendar.current
        return expenses
            .filter {
                guard let date = dateFrom($0.date) else { return false }
                return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var recentExpenses: [Expense] {
        expenses.prefix(5).map { $0 }
    }
    
    var categoryBreakdown: [(category: ExpenseCategory, amount: Double)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { (key, values) in
            (category: categoryFor(key), amount: values.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
    
    func load() async {
        isLoading = true
        errorMessage = nil
        var errors: [String] = []
        
        async let expTask: [Expense]? = fetchOrNil(APIClient.shared.getExpenses)
        async let invTask: [Investment]? = fetchOrNil(APIClient.shared.getInvestments)
        async let budTask: [Budget]? = fetchOrNil(APIClient.shared.getBudgets)
        
        let exp = await expTask
        let inv = await invTask
        let bud = await budTask
        
        if let e = exp { expenses = e } else { errors.append("expenses") }
        if let i = inv { investments = i } else { errors.append("investments") }
        if let b = bud { budgets = b } else { errors.append("budgets") }
        
        if !errors.isEmpty {
            errorMessage = "Failed to load: \(errors.joined(separator: ", ")). Pull to refresh."
            print("[WealthFlow] Dashboard partial load failure: \(errors.joined(separator: ", "))")
        }
        
        isLoading = false
    }
    
    private func fetchOrNil<T>(_ operation: @escaping () async throws -> T) async -> T? {
        do {
            return try await operation()
        } catch {
            print("[WealthFlow] Fetch error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func dateFrom(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
