import Foundation
import Observation

@Observable
final class BudgetsViewModel {
    var budgets: [Budget] = []
    var expenses: [Expense] = []
    var isLoading = false
    var errorMessage: String?
    
    func load() async {
        isLoading = true
        do {
            async let budgetsTask: [Budget] = APIClient.shared.getBudgets()
            async let expensesTask: [Expense] = APIClient.shared.getExpenses()
            let (b, e) = try await (budgetsTask, expensesTask)
            await MainActor.run {
                self.budgets = b
                self.expenses = e
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func spent(for category: String) -> Double {
        let calendar = Calendar.current
        return expenses
            .filter {
                $0.category == category &&
                calendar.isDate(dateFrom($0.date) ?? Date.distantPast, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    func percentUsed(for budget: Budget) -> Double {
        budget.limit > 0 ? min((spent(for: budget.category) / budget.limit) * 100, 100) : 0
    }
    
    func isOverBudget(_ budget: Budget) -> Bool {
        spent(for: budget.category) > budget.limit
    }
    
    func addBudget(_ budget: Budget) async {
        do {
            try await APIClient.shared.createBudget(budget)
            await load()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteBudget(id: Double) async {
        do {
            try await APIClient.shared.deleteBudget(id: id)
            await MainActor.run {
                self.budgets.removeAll { $0.id == id }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func dateFrom(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
