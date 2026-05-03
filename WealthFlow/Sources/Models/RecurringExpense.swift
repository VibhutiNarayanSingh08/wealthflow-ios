import Foundation

struct RecurringExpense: Codable, Identifiable, Equatable {
    let id: Double
    var name: String
    var amount: Double
    var category: String
    var frequency: String
    var dayOfMonth: Int
    var active: Int
    var lastPaid: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, category, frequency, active
        case dayOfMonth = "day_of_month"
        case lastPaid = "last_paid"
    }
    
    var isPaidThisMonth: Bool {
        guard let lastPaid = lastPaid else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: lastPaid) else { return false }
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    var statusText: String {
        if isPaidThisMonth { return "Paid" }
        let today = Calendar.current.component(.day, from: Date())
        return dayOfMonth <= today ? "Due" : "Due \(dayOfMonth)"
    }
    
    var statusColor: String {
        if isPaidThisMonth { return "#10b981" }
        let today = Calendar.current.component(.day, from: Date())
        return dayOfMonth <= today ? "#f59e0b" : "#64748b"
    }
    
    var formattedAmount: String {
        NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}
