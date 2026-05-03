# WealthFlow iOS App

A native SwiftUI iOS app for WealthFlow. Built with iOS 17+ features including `@Observable`, Swift Charts, and modern SwiftUI patterns.

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   SwiftUI   │────▶│  ViewModel  │────▶│  APIClient  │────▶ FastAPI Backend
│   Views     │     │  (@Observable)    │     │  (URLSession)   │
└─────────────┘     └─────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│  Keychain   │  ← JWT token storage
└─────────────┘
```

## Features

- **JWT Authentication** — Login/register with secure Keychain token storage
- **Dashboard** — Net worth, portfolio value, monthly expenses, recent transactions
- **Expenses** — Smart quick-add, preset tiles, recurring bills, category filters
- **Investments** — Holdings tracking, allocation breakdown, P&L
- **Budgets** — Monthly limits with progress bars
- **Offline-First** — All data cached locally, synced with backend

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0
- Active backend server (local or deployed)

## Setup

### 1. Open in Xcode

```bash
cd ios
open WealthFlow.xcodeproj
```

### 2. Configure Backend URL

In `WealthFlow/Sources/Services/APIClient.swift`, update the `baseURL`:

```swift
#if DEBUG
let baseURL = "http://localhost:8000"        // Local development
#else
let baseURL = "https://your-production-url.com"  // Production
#endif
```

> **Note:** For local development on a physical iOS device, use your Mac's local IP address (e.g., `http://192.168.1.5:8000`) instead of `localhost`.

### 3. Build & Run

1. Select a target (iPhone 16 Simulator or your device)
2. Press **Cmd+R** to build and run

### 4. First Login

The app starts with a login screen. Create an account or log in. The backend auto-creates your user and seeds demo data on first login.

## Project Structure

```
WealthFlow/Sources/
├── Models/
│   ├── User.swift              # Auth models
│   ├── Expense.swift           # Expense + categories
│   ├── Investment.swift        # Investment + types
│   ├── Budget.swift            # Budget model
│   └── RecurringExpense.swift  # Recurring bill model
├── Services/
│   ├── APIClient.swift         # URLSession wrapper, all endpoints
│   ├── AuthManager.swift       # Login state, token management
│   └── KeychainManager.swift   # Secure JWT storage
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── ExpensesViewModel.swift
│   ├── InvestmentsViewModel.swift
│   └── BudgetsViewModel.swift
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Expenses/
│   │   ├── ExpensesView.swift
│   │   ├── AddExpenseSheet.swift
│   │   └── AddRecurringSheet.swift
│   ├── Investments/
│   │   └── InvestmentsView.swift
│   ├── Budgets/
│   │   └── BudgetsView.swift
│   ├── Components/
│   │   └── Color+Hex.swift
│   ├── ContentView.swift
│   └── MainTabView.swift
└── WealthFlowApp.swift
```

## Key Design Decisions

### `@Observable` (iOS 17+)
All view models use `@Observable` instead of `ObservableObject` for better performance and simpler syntax.

### Keychain for Tokens
JWT tokens are stored in the iOS Keychain (not UserDefaults) for security. Tokens survive app restarts and are automatically validated on app launch.

### Singleton Services
`APIClient.shared` and `AuthManager.shared` are singletons accessed throughout the app. This simplifies dependency management without needing a full DI framework.

### Backend Sync Strategy
- All reads come from the backend API
- All writes update local state immediately for responsiveness, then sync to backend in background
- If backend fails, local state is preserved (user sees their data)

## Publishing to App Store

1. **Update bundle identifier** in `project.yml` (e.g., `com.yourcompany.wealthflow`)
2. **Set production backend URL** in `APIClient.swift`
3. **Configure signing** in Xcode (Apple Developer account required)
4. **Archive & upload** via Xcode → Product → Archive → Distribute App

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Cannot connect to server" | Check `baseURL` in `APIClient.swift`. Use IP address, not `localhost`, for physical devices |
| "Invalid token" | Log out and log back in. Token may have expired (7 days) |
| Keychain error on simulator | Keychain works on simulators but behaves differently. Test on device for production behavior |
| Build errors | Make sure you're using Xcode 15+ with iOS 17 SDK |
