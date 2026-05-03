import Foundation

struct Expense: Codable, Identifiable, Equatable {
    let id: Double
    var description: String
    var amount: Double
    var date: String
    var category: String
    var paymentMethod: String
    var note: String?
    
    enum CodingKeys: String, CodingKey {
        case id, description, amount, date, category, note
        case paymentMethod = "payment_method"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: date) else { return self.date }
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}

struct ExpenseCategory: Identifiable {
    let id: String
    let emoji: String
    let label: String
    let color: String
}

let expenseCategories: [ExpenseCategory] = [
    ExpenseCategory(id: "food", emoji: "🍔", label: "Food & Dining", color: "#f97316"),
    ExpenseCategory(id: "transport", emoji: "🚗", label: "Transport", color: "#3b82f6"),
    ExpenseCategory(id: "shopping", emoji: "🛍️", label: "Shopping", color: "#a855f7"),
    ExpenseCategory(id: "bills", emoji: "📄", label: "Bills & Utilities", color: "#ef4444"),
    ExpenseCategory(id: "entertainment", emoji: "🎬", label: "Entertainment", color: "#ec4899"),
    ExpenseCategory(id: "health", emoji: "💊", label: "Health", color: "#22c55e"),
    ExpenseCategory(id: "education", emoji: "📚", label: "Education", color: "#6366f1"),
    ExpenseCategory(id: "other", emoji: "📦", label: "Other", color: "#64748b")
]

func categoryFor(_ id: String) -> ExpenseCategory {
    expenseCategories.first { $0.id == id } ?? expenseCategories.last!
}
