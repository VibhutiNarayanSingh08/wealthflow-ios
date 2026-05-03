import SwiftUI

struct InvestmentsView: View {
    @State private var viewModel = InvestmentsViewModel()
    @State private var showingAddInvestment = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio Value")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.totalCurrentValue)) ?? "₹0")
                                .font(.title2.bold())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("P&L")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.totalPnl >= 0 ? "+" + (NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.totalPnl)) ?? "₹0") : NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.totalPnl)) ?? "₹0")
                                .font(.title2.bold())
                                .foregroundStyle(viewModel.totalPnl >= 0 ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // Allocation
                    if !viewModel.allocation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Allocation")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.allocation, id: \.type.id) { item in
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: item.type.color))
                                            .frame(width: 12, height: 12)
                                        Text(item.type.label)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(NumberFormatter.currencyFormatter().string(from: NSNumber(value: item.value)) ?? "₹0")
                                            .font(.subheadline)
                                        Text(String(format: "%.1f%%", item.percent))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .trailing)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: viewModel.selectedType == nil) {
                                viewModel.selectedType = nil
                            }
                            ForEach(investmentTypes) { type in
                                FilterChip(title: type.label, isSelected: viewModel.selectedType == type.id) {
                                    viewModel.selectedType = viewModel.selectedType == type.id ? nil : type.id
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Holdings")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        if viewModel.filteredInvestments.isEmpty {
                            ContentUnavailableView("No investments", systemImage: "chart.line.uptrend.xyaxis")
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.filteredInvestments) { inv in
                                    InvestmentRow(investment: inv)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                Task { await viewModel.deleteInvestment(id: inv.id) }
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
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddInvestment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddInvestment) {
                AddInvestmentSheet(viewModel: viewModel)
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

struct InvestmentRow: View {
    let investment: Investment
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: investmentTypeFor(investment.type).color))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(investment.name)
                    .font(.subheadline.bold())
                Text(investmentTypeFor(investment.type).label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(investment.formattedAmount)
                    .font(.subheadline.bold())
                Text(investment.formattedPnl)
                    .font(.caption)
                    .foregroundStyle(investment.isProfit ? .green : .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AddInvestmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: InvestmentsViewModel
    
    @State private var name = ""
    @State private var type = "stocks"
    @State private var invested = ""
    @State private var currentValue = ""
    @State private var date = Date()
    @State private var note = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Asset") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(investmentTypes) { t in
                            Text(t.label).tag(t.id)
                        }
                    }
                }
                
                Section("Amounts") {
                    TextField("Invested", text: $invested)
                        .keyboardType(.decimalPad)
                    TextField("Current Value", text: $currentValue)
                        .keyboardType(.decimalPad)
                }
                
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }
            }
            .navigationTitle("Add Investment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || invested.isEmpty || currentValue.isEmpty || Double(invested) == nil || Double(currentValue) == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let inv = Double(invested), let cur = Double(currentValue) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let investment = Investment(
            id: Double(Date().timeIntervalSince1970),
            name: name,
            type: type,
            invested: inv,
            currentValue: cur,
            date: formatter.string(from: date),
            note: note.isEmpty ? nil : note
        )
        
        Task {
            await viewModel.addInvestment(investment)
            dismiss()
        }
    }
}
