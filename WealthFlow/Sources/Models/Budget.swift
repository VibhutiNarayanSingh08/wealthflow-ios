import Foundation

struct Budget: Codable, Identifiable, Equatable {
    let id: Double
    var category: String
    var limit: Double
    
    enum CodingKeys: String, CodingKey {
        case id, category
        case limit = "limit_amount"
    }
    
    var formattedLimit: String {
        NumberFormatter.currency.string(from: NSNumber(value: limit)) ?? "₹0"
    }
}
