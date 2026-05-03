import Foundation
import Observation

@Observable
final class ExpensesViewModel {
    var expenses: [Expense] = []
    var recurring: [RecurringExpense] = []
    var isLoading = false
    var errorMessage: String?
    var selectedCategory: String? = nil
    
    var filteredExpenses: [Expense] {
        guard let category = selectedCategory else { return expenses }
        return expenses.filter { $0.category == category }
    }
    
    var totalThisMonth: Double {
        let calendar = Calendar.current
        return expenses
            .filter {
                guard let date = dateFrom($0.date) else { return false }
                return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var categoryTotals: [(category: ExpenseCategory, amount: Double)] {
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
        async let recTask: [RecurringExpense]? = fetchOrNil(APIClient.shared.getRecurring)
        
        let exp = await expTask
        let rec = await recTask
        
        if let e = exp { expenses = e } else { errors.append("expenses") }
        if let r = rec { recurring = r } else { errors.append("recurring") }
        
        if !errors.isEmpty {
            errorMessage = "Failed to load: \(errors.joined(separator: ", ")). Pull to refresh."
            print("[WealthFlow] Expenses partial load failure: \(errors.joined(separator: ", "))")
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
    
    func addExpense(_ expense: Expense) async {
        do {
            try await APIClient.shared.createExpense(expense)
            await load()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteExpense(id: Double) async {
        do {
            try await APIClient.shared.deleteExpense(id: id)
            await MainActor.run {
                self.expenses.removeAll { $0.id == id }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func addRecurring(_ rec: RecurringExpense) async {
        do {
            try await APIClient.shared.createRecurring(rec)
            await load()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func markRecurringPaid(id: Double) async {
        do {
            try await APIClient.shared.markRecurringPaid(id: id)
            await load()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteRecurring(id: Double) async {
        do {
            try await APIClient.shared.deleteRecurring(id: id)
            await MainActor.run {
                self.recurring.removeAll { $0.id == id }
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
