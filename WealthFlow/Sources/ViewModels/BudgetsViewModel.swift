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
        errorMessage = nil
        var errors: [String] = []
        
        async let budTask: [Budget]? = fetchOrNil(APIClient.shared.getBudgets)
        async let expTask: [Expense]? = fetchOrNil(APIClient.shared.getExpenses)
        
        let bud = await budTask
        let exp = await expTask
        
        if let b = bud { budgets = b } else { errors.append("budgets") }
        if let e = exp { expenses = e } else { errors.append("expenses") }
        
        if !errors.isEmpty {
            errorMessage = "Failed to load: \(errors.joined(separator: ", ")). Pull to refresh."
            print("[WealthFlow] Budgets partial load failure: \(errors.joined(separator: ", "))")
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
