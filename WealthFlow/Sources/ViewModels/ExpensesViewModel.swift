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
        do {
            async let expensesTask: [Expense] = APIClient.shared.getExpenses()
            async let recurringTask: [RecurringExpense] = APIClient.shared.getRecurring()
            let (e, r) = try await (expensesTask, recurringTask)
            await MainActor.run {
                self.expenses = e
                self.recurring = r
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
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
