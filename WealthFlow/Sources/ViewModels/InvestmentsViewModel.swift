import Foundation
import Observation

@Observable
final class InvestmentsViewModel {
    var investments: [Investment] = []
    var isLoading = false
    var errorMessage: String?
    var selectedType: String? = nil
    
    var filteredInvestments: [Investment] {
        guard let type = selectedType else { return investments }
        return investments.filter { $0.type == type }
    }
    
    var totalInvested: Double {
        investments.reduce(0) { $0 + $1.invested }
    }
    
    var totalCurrentValue: Double {
        investments.reduce(0) { $0 + $1.currentValue }
    }
    
    var totalPnl: Double {
        totalCurrentValue - totalInvested
    }
    
    var allocation: [(type: InvestmentType, value: Double, percent: Double)] {
        let grouped = Dictionary(grouping: investments, by: { $0.type })
        return grouped.map { (key, values) in
            let value = values.reduce(0) { $0 + $1.currentValue }
            let percent = totalCurrentValue > 0 ? (value / totalCurrentValue) * 100 : 0
            return (type: investmentTypeFor(key), value: value, percent: percent)
        }.sorted { $0.value > $1.value }
    }
    
    func load() async {
        isLoading = true
        errorMessage = nil
        
        if investments.isEmpty, let cached = LocalCache.loadInvestments() {
            investments = cached
        }
        
        do {
            let data = try await APIClient.shared.getInvestments()
            await MainActor.run {
                self.investments = data
                LocalCache.saveInvestments(data)
                self.isLoading = false
            }
        } catch {
            let errMsg = "Investments load failed: \(error.localizedDescription)"
            print("[WealthFlow] \(errMsg)")
            await MainActor.run {
                self.errorMessage = errMsg
                self.isLoading = false
            }
        }
    }
    
    func addInvestment(_ investment: Investment) async {
        do {
            try await APIClient.shared.createInvestment(investment)
            await load()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteInvestment(id: Double) async {
        do {
            try await APIClient.shared.deleteInvestment(id: id)
            await MainActor.run {
                self.investments.removeAll { $0.id == id }
                LocalCache.saveInvestments(self.investments)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
