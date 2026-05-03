import Foundation

struct Investment: Codable, Identifiable, Equatable {
    let id: Double
    var name: String
    var type: String
    var invested: Double
    var currentValue: Double
    var date: String
    var note: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, invested, date, note
        case currentValue = "current_value"
    }
    
    var pnl: Double { currentValue - invested }
    var pnlPercent: Double { invested > 0 ? (pnl / invested) * 100 : 0 }
    var isProfit: Bool { pnl >= 0 }
    
    var formattedAmount: String {
        NumberFormatter.currency.string(from: NSNumber(value: currentValue)) ?? "₹0"
    }
    
    var formattedInvested: String {
        NumberFormatter.currency.string(from: NSNumber(value: invested)) ?? "₹0"
    }
    
    var formattedPnl: String {
        let sign = pnl >= 0 ? "+" : ""
        return sign + (NumberFormatter.currency.string(from: NSNumber(value: pnl)) ?? "₹0")
    }
}

struct InvestmentType: Identifiable {
    let id: String
    let label: String
    let color: String
}

let investmentTypes: [InvestmentType] = [
    InvestmentType(id: "stocks", label: "Stocks", color: "#10b981"),
    InvestmentType(id: "crypto", label: "Crypto", color: "#f59e0b"),
    InvestmentType(id: "mutual_fund", label: "Mutual Fund", color: "#8b5cf6"),
    InvestmentType(id: "bonds", label: "Bonds", color: "#3b82f6"),
    InvestmentType(id: "real_estate", label: "Real Estate", color: "#ec4899"),
    InvestmentType(id: "other", label: "Other", color: "#64748b")
]

func investmentTypeFor(_ id: String) -> InvestmentType {
    investmentTypes.first { $0.id == id } ?? investmentTypes.last!
}

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.maximumFractionDigits = 2
        return f
    }()
}
