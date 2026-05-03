import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        SummaryCard(
                            title: "Net Worth",
                            value: NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.netWorth)) ?? "₹0",
                            icon: "wallet.pass",
                            color: "#6366f1"
                        )
                        SummaryCard(
                            title: "Portfolio",
                            value: NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.totalPortfolioValue)) ?? "₹0",
                            icon: "chart.line.uptrend.xyaxis",
                            color: "#10b981"
                        )
                        SummaryCard(
                            title: "Monthly Expenses",
                            value: NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.monthlyExpenses)) ?? "₹0",
                            icon: "creditcard",
                            color: "#f43f5e"
                        )
                        SummaryCard(
                            title: "Invested",
                            value: NumberFormatter.currencyFormatter().string(from: NSNumber(value: viewModel.totalInvested)) ?? "₹0",
                            icon: "banknote",
                            color: "#f59e0b"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        if viewModel.recentExpenses.isEmpty {
                            ContentUnavailableView("No transactions yet", systemImage: "doc.text")
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.recentExpenses) { expense in
                                    ExpenseRowView(expense: expense)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Category Breakdown
                    if !viewModel.categoryBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Categories")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.categoryBreakdown.prefix(5), id: \.category.id) { item in
                                    HStack {
                                        Text(item.category.emoji)
                                        Text(item.category.label)
                                            .font(.subheadline)
                                        Spacer()
                                        Text(NumberFormatter.currencyFormatter().string(from: NSNumber(value: item.amount)) ?? "₹0")
                                            .font(.subheadline.bold())
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: color))
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


