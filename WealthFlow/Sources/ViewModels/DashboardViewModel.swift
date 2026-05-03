import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var expenses: [Expense] = []
    var investments: [Investment] = []
    var budgets: [Budget] = []
    var isLoading = false
    
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
        do {
            async let exp: [Expense] = APIClient.shared.getExpenses()
            async let inv: [Investment] = APIClient.shared.getInvestments()
            async let bud: [Budget] = APIClient.shared.getBudgets()
            let (e, i, b) = try await (exp, inv, bud)
            await MainActor.run {
                self.expenses = e
                self.investments = i
                self.budgets = b
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func dateFrom(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
