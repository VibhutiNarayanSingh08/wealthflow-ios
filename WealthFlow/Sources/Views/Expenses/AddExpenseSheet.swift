import SwiftUI

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ExpensesViewModel
    
    @State private var description = ""
    @State private var amount = ""
    @State private var category = "food"
    @State private var paymentMethod = "upi"
    @State private var note = ""
    @State private var date = Date()
    
    let paymentMethods = [
        ("upi", "📱 UPI"),
        ("cash", "💵 Cash"),
        ("credit_card", "💳 Credit Card"),
        ("debit_card", "💳 Debit Card"),
        ("netbanking", "🏦 Net Banking")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Description", text: $description)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(expenseCategories) { cat in
                            Text("\(cat.emoji) \(cat.label)").tag(cat.id)
                        }
                    }
                }
                
                Section("Payment Method") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.0) { method in
                            Text(method.1).tag(method.0)
                        }
                    }
                }
                
                Section {
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(description.isEmpty || amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let amountValue = Double(amount) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let expense = Expense(
            id: Double(Date().timeIntervalSince1970),
            description: description,
            amount: amountValue,
            date: formatter.string(from: date),
            category: category,
            paymentMethod: paymentMethod,
            note: note.isEmpty ? nil : note
        )
        
        Task {
            await viewModel.addExpense(expense)
            dismiss()
        }
    }
}

struct AddRecurringSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: ExpensesViewModel
    
    @State private var name = ""
    @State private var amount = ""
    @State private var category = "bills"
    @State private var dayOfMonth = 1
    @State private var frequency = "monthly"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Schedule") {
                    Picker("Category", selection: $category) {
                        ForEach(expenseCategories) { cat in
                            Text("\(cat.emoji) \(cat.label)").tag(cat.id)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        Text("Monthly").tag("monthly")
                        Text("Weekly").tag("weekly")
                        Text("Yearly").tag("yearly")
                    }
                    
                    Stepper("Due day: \(dayOfMonth)", value: $dayOfMonth, in: 1...31)
                }
            }
            .navigationTitle("Add Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty || amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let amountValue = Double(amount) else { return }
        
        let rec = RecurringExpense(
            id: Double(Date().timeIntervalSince1970),
            name: name,
            amount: amountValue,
            category: category,
            frequency: frequency,
            dayOfMonth: dayOfMonth,
            active: 1,
            lastPaid: nil
        )
        
        Task {
            await viewModel.addRecurring(rec)
            dismiss()
        }
    }
}
