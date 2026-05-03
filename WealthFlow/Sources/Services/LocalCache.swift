import Foundation

enum LocalCache {
    private static let defaults = UserDefaults.standard
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    private enum Keys {
        static let expenses = "cached_expenses"
        static let investments = "cached_investments"
        static let budgets = "cached_budgets"
        static let recurring = "cached_recurring"
    }
    
    static func save<T: Codable>(_ items: T, for key: String) {
        do {
            let data = try encoder.encode(items)
            defaults.set(data, forKey: key)
        } catch {
            print("[LocalCache] Failed to save \(key): \(error)")
        }
    }
    
    static func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("[LocalCache] Failed to load \(key): \(error)")
            return nil
        }
    }
    
    static func saveExpenses(_ items: [Expense]) { save(items, for: Keys.expenses) }
    static func loadExpenses() -> [Expense]? { load([Expense].self, for: Keys.expenses) }
    
    static func saveInvestments(_ items: [Investment]) { save(items, for: Keys.investments) }
    static func loadInvestments() -> [Investment]? { load([Investment].self, for: Keys.investments) }
    
    static func saveBudgets(_ items: [Budget]) { save(items, for: Keys.budgets) }
    static func loadBudgets() -> [Budget]? { load([Budget].self, for: Keys.budgets) }
    
    static func saveRecurring(_ items: [RecurringExpense]) { save(items, for: Keys.recurring) }
    static func loadRecurring() -> [RecurringExpense]? { load([RecurringExpense].self, for: Keys.recurring) }
    
    static func clearAll() {
        defaults.removeObject(forKey: Keys.expenses)
        defaults.removeObject(forKey: Keys.investments)
        defaults.removeObject(forKey: Keys.budgets)
        defaults.removeObject(forKey: Keys.recurring)
    }
}
