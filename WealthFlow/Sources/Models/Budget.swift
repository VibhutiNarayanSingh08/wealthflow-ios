import Foundation

struct Budget: Codable, Identifiable, Equatable {
    let id: Double
    var category: String
    var limit: Double
    
    enum CodingKeys: String, CodingKey {
        case id, category, limit
    }
    
    var formattedLimit: String {
        NumberFormatter.currencyFormatter().string(from: NSNumber(value: limit)) ?? "₹0"
    }
}
