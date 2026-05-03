import SwiftUI

struct BudgetsView: View {
    @State private var viewModel = BudgetsViewModel()
    @State private var showingAddBudget = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.budgets.isEmpty {
                        ContentUnavailableView {
                            Label("No budgets set", systemImage: "chart.pie")
                        } description: {
                            Text("Set up your first budget to track spending")
                        } actions: {
                            Button("Create Budget") {
                                showingAddBudget = true
                            }
                        }
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.budgets) { budget in
                                BudgetCard(budget: budget, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetSheet(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

struct BudgetCard: View {
    let budget: Budget
    let viewModel: BudgetsViewModel
    
    var spent: Double { viewModel.spent(for: budget.category) }
    var percent: Double { viewModel.percentUsed(for: budget) }
    var isOver: Bool { viewModel.isOverBudget(budget) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(categoryFor(budget.category).emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryFor(budget.category).label)
                        .font(.subheadline.bold())
                    Text("Limit: \(budget.formattedLimit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isOver {
                    Text("Over Budget")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOver ? Color.red : Color(hex: "#6366f1"))
                        .frame(width: geo.size.width * CGFloat(min(max(percent, 0), 100) / 100), height: 8)
                        .animation(.easeInOut, value: percent)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Spent: \(NumberFormatter.currencyFormatter().string(from: NSNumber(value: spent)) ?? "₹0")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(String(format: "%.0f", percent))%")
                    .font(.caption.bold())
                    .foregroundStyle(isOver ? .red : .primary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await viewModel.deleteBudget(id: budget.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: BudgetsViewModel
    
    @State private var category = "food"
    @State private var limit = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    Picker("Category", selection: $category) {
                        ForEach(expenseCategories) { cat in
                            Text("\(cat.emoji) \(cat.label)").tag(cat.id)
                        }
                    }
                    
                    TextField("Monthly Limit", text: $limit)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Set Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(limit.isEmpty || Double(limit) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let limitValue = Double(limit) else { return }
        
        let budget = Budget(
            id: Double(Date().timeIntervalSince1970),
            category: category,
            limit: limitValue
        )
        
        Task {
            await viewModel.addBudget(budget)
            dismiss()
        }
    }
}
