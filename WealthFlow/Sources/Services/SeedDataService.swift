import Foundation

enum SeedDataService {
    static func seed() async throws {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        
        let sampleExpenses: [Expense] = [
            Expense(id: generateId(), description: "Lunch at office", amount: 250, date: formatter.string(from: today), category: "food", paymentMethod: "upi", note: ""),
            Expense(id: generateId(), description: "Petrol", amount: 1200, date: formatter.string(from: yesterday), category: "transport", paymentMethod: "card", note: ""),
            Expense(id: generateId(), description: "Netflix subscription", amount: 649, date: formatter.string(from: yesterday), category: "entertainment", paymentMethod: "upi", note: ""),
            Expense(id: generateId(), description: "Groceries", amount: 1800, date: formatter.string(from: twoDaysAgo), category: "food", paymentMethod: "upi", note: "BigBasket"),
            Expense(id: generateId(), description: "Cab to airport", amount: 850, date: formatter.string(from: lastWeek), category: "transport", paymentMethod: "upi", note: ""),
            Expense(id: generateId(), description: "Electricity bill", amount: 2400, date: formatter.string(from: lastMonth), category: "bills", paymentMethod: "card", note: "March bill")
        ]
        
        let sampleInvestments: [Investment] = [
            Investment(id: generateId(), name: "NIFTY 50 Index Fund", type: "mutual_fund", invested: 50000, currentValue: 54200, date: formatter.string(from: lastMonth), note: nil),
            Investment(id: generateId(), name: "Apple Inc.", type: "stocks", invested: 25000, currentValue: 28300, date: formatter.string(from: twoDaysAgo), note: nil),
            Investment(id: generateId(), name: "SBI FD", type: "fd", invested: 100000, currentValue: 104000, date: formatter.string(from: lastMonth), note: "1 year FD")
        ]
        
        let sampleBudgets: [Budget] = [
            Budget(id: generateId(), category: "food", limit: 8000),
            Budget(id: generateId(), category: "transport", limit: 5000),
            Budget(id: generateId(), category: "entertainment", limit: 3000),
            Budget(id: generateId(), category: "bills", limit: 10000)
        ]
        
        for expense in sampleExpenses {
            try await APIClient.shared.createExpense(expense)
        }
        print("[SeedData] Created \(sampleExpenses.count) sample expenses")
        
        for investment in sampleInvestments {
            try await APIClient.shared.createInvestment(investment)
        }
        print("[SeedData] Created \(sampleInvestments.count) sample investments")
        
        for budget in sampleBudgets {
            try await APIClient.shared.createBudget(budget)
        }
        print("[SeedData] Created \(sampleBudgets.count) sample budgets")
    }
    
    private static func generateId() -> Double {
        Double(Date().timeIntervalSince1970 * 1000) + Double.random(in: 0..<1000)
    }
}
