import SwiftUI

struct ExpensesView: View {
    @State private var viewModel = ExpensesViewModel()
    @State private var showingAddExpense = false
    @State private var showingAddRecurring = false
    @State private var quickInput = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Add Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Add")
                            .font(.headline)
                        
                        HStack {
                            TextField("Swiggy 450", text: $quickInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button {
                                addQuickExpense()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#6366f1"))
                            }
                        }
                        
                        Text("Examples: Zomato 320, Petrol 1020")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            PresetButton(emoji: "☕", label: "Coffee", amount: 50, action: { addPreset(name: "Coffee", amount: 50, category: "food") })
                            PresetButton(emoji: "🍕", label: "Lunch", amount: 150, action: { addPreset(name: "Lunch", amount: 150, category: "food") })
                            PresetButton(emoji: "🍽️", label: "Dinner", amount: 300, action: { addPreset(name: "Dinner", amount: 300, category: "food") })
                            PresetButton(emoji: "⛽", label: "Petrol", amount: 500, action: { addPreset(name: "Petrol", amount: 500, category: "transport") })
                            PresetButton(emoji: "🛒", label: "Groceries", amount: 800, action: { addPreset(name: "Groceries", amount: 800, category: "food") })
                            PresetButton(emoji: "🚕", label: "Cab", amount: 120, action: { addPreset(name: "Cab", amount: 120, category: "transport") })
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recurring
                    if !viewModel.recurring.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recurring")
                                    .font(.title3.bold())
                                Spacer()
                                Button("Add") {
                                    showingAddRecurring = true
                                }
                                .foregroundStyle(Color(hex: "#6366f1"))
                            }
                            .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.recurring) { rec in
                                    RecurringRow(rec: rec) {
                                        Task { await viewModel.markRecurringPaid(id: rec.id) }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(expenseCategories) { cat in
                                FilterChip(title: "\(cat.emoji) \(cat.label)", isSelected: viewModel.selectedCategory == cat.id) {
                                    viewModel.selectedCategory = viewModel.selectedCategory == cat.id ? nil : cat.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Expenses List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transactions")
                                .font(.title3.bold())
                            Spacer()
                            Text(NumberFormatter.currency.string(from: NSNumber(value: viewModel.totalThisMonth)) ?? "₹0")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.filteredExpenses.isEmpty {
                            ContentUnavailableView("No expenses", systemImage: "doc.text")
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.filteredExpenses) { expense in
                                    ExpenseRowView(expense: expense)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                Task { await viewModel.deleteExpense(id: expense.id) }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingAddRecurring) {
                AddRecurringSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
    
    private func addQuickExpense() {
        let text = quickInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        let parts = text.components(separatedBy: .whitespaces)
        guard let amountStr = parts.first(where: { Double($0) != nil }),
              let amount = Double(amountStr) else { return }
        
        let amountIndex = parts.firstIndex(of: amountStr) ?? parts.count
        let description = parts[0..<amountIndex].joined(separator: " ").capitalized
        let categoryHint = amountIndex < parts.count - 1 ? parts[amountIndex + 1] : nil
        
        var category = "other"
        if let hint = categoryHint, expenseCategories.contains(where: { $0.id == hint }) {
            category = hint
        } else {
            let lower = text.lowercased()
            let keywords: [(String, [String])] = [
                ("food", ["swiggy","zomato","pizza","lunch","dinner","coffee","grocery","milk"]),
                ("transport", ["uber","ola","cab","petrol","fuel","metro"]),
                ("bills", ["rent","electricity","recharge","bill","wifi"]),
                ("entertainment", ["movie","netflix","prime","spotify"]),
                ("health", ["medicine","doctor","gym","pharmacy"]),
                ("shopping", ["amazon","flipkart","clothes","shoes"])
            ]
            for (cat, words) in keywords {
                if words.contains(where: { lower.contains($0) }) {
                    category = cat
                    break
                }
            }
        }
        
        let expense = Expense(
            id: Double(Date().timeIntervalSince1970),
            description: description.isEmpty ? "Expense" : description,
            amount: amount,
            date: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: Date())
            }(),
            category: category,
            paymentMethod: "upi",
            note: ""
        )
        
        Task {
            await viewModel.addExpense(expense)
            await MainActor.run { quickInput = "" }
        }
    }
    
    private func addPreset(name: String, amount: Double, category: String) {
        let expense = Expense(
            id: Double(Date().timeIntervalSince1970),
            description: name,
            amount: amount,
            date: {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: Date())
            }(),
            category: category,
            paymentMethod: "upi",
            note: ""
        )
        Task { await viewModel.addExpense(expense) }
    }
}

struct PresetButton: View {
    let emoji: String
    let label: String
    let amount: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                Text("₹\(Int(amount))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 80)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct RecurringRow: View {
    let rec: RecurringExpense
    let onMarkPaid: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rec.name)
                    .font(.subheadline.bold())
                Text(categoryFor(rec.category).label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(rec.formattedAmount)
                    .font(.subheadline.bold())
                Text(rec.statusText)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: rec.statusColor).opacity(0.2))
                    .foregroundStyle(Color(hex: rec.statusColor))
                    .clipShape(Capsule())
            }
            
            if !rec.isPaidThisMonth {
                Button(action: onMarkPaid) {
                    Text("Pay")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#6366f1"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


