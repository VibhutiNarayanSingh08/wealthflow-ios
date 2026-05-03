import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            Text(categoryFor(expense.category).emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(.subheadline.bold())
                Text(expense.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(expense.formattedAmount)
                .font(.subheadline.bold())
                .foregroundStyle(.red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
