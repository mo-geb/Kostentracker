# ClutterFree Expenses - Technical Documentation

> [!NOTE]
> This is the official technical documentation for **ClutterFree Expenses** (internal project name: *Kostentracker*). This document provides a high-level overview of the application's architecture, data models, views, and core logic components for the solo developer currently maintaining it.

## 📱 App Overview

**ClutterFree Expenses** is a streamlined, SwiftUI-based iOS application designed to track user spending, manage recurring costs, and visually highlight cash flow. The application prioritizes aesthetic design, strong visual hierarchy, and unparalleled performance achieved through state-caching and modern MVVM architecture. 

It is built completely with native Apple frameworks, utilizing **SwiftUI** for the user interface and **SwiftData** for local offline persistence.

---

## 🏗️ Architecture

The app is built using a modern **MVVM (Model-View-ViewModel)** architectural pattern. This ensures that the UI elements remain declarative and lightweight, while heavy data processing (filtering, grouping, and calculating costs) is deferred to dedicated ViewModels.

### Key Architectural Guidelines
1. **Separation of Concerns**: Views are responsible only for displaying data. ViewModels (like `StatisticsViewModel` and `ListViewModel`) pull data from SwiftData and process it for the view to consume.
2. **State Caching**: The ViewModels cache their processed data (e.g. pre-calculated arrays, grouped dictionaries) and only update when their `update(from: ui: userSettings:)` method is explicitly called. This removes redundant parsing during UI redraws.
3. **Draft Architecture for Mutation**: Creating or editing models (`Expense`, `ExpenseCategory`, `ExpenseAccount`) doesn't mutate SwiftData objects directly until the user confirms. Instead, the UI works on a lightweight temporary `Draft` struct (e.g., `ExpenseDraft`).
4. **Environment Driving the UI**: The global `UIState` and `UserSettings` objects are pushed down the view hierarchy using `.environment(...)`. They store user preferences (like selected accounts or the current display period) ensuring all tabs are synchronized instantly when a filter changes.

---

## 🗄️ Data Models (SwiftData)

The database schema relies on three `@Model` classes, all of which support Cascade Deferring and safe data fallbacks.

### 1. `Expense`
The core entity representing a user's expense.
- **Support for Recurrence**: Can represent `oneTime`, `recurring`, or `inactive` expenses. Recurring expenses are tracked using a `FrequencyUnit` (day, week, month, year) and a `frequencyValue`.
- **Cost Calculation Methods**: Contains helpers like `yearlyCost`, `monthlyCost`, and `totalForMonth(containing:)` which power the cost breakdowns across the app.
- **Customization**: Supports a custom Emoji character string or an actual Image via the `customImageData` attribute. Falls back to its Category styling if empty.

### 2. `ExpenseCategory`
Defines groupings for expenses (e.g. "Food", "Transport").
- **Styling**: Categories have their own custom SwiftUI `Color` and SF Symbol (`iconName`).
- **Default Category Fallback**: When a category is deleted, the system executes `deleteSafely(from:)`. Instead of letting expenses become orphans, they are transferred automatically to a designated standard "Other" `isDefault` category.

### 3. `ExpenseAccount`
Optional segmentation context for expenses indicating where money is drawn from (e.g. "Wallet", "Credit Card"). It acts similarly to a Category but handles high-level filtering which the user can toggle on or off via `UserSettings.enableAccounts`.

---

## 🖼️ User Interface & Core Views

The application relies on a `MainTabView` which manages the primary navigation between the main functional sections.

### Tabs & ViewModels

| View Component | Backing ViewModel | Description |
|---|---|---|
| **ListView** | `ListViewModel` | Shows all saved entries. Supports multi-faceted grouping (`none`, `categories`, `frequency`) and sorting. The `ListViewModel` processes an unstructured array into `ProcessedGroup`s before rendering. |
| **StatisticsView** | `StatisticsViewModel` | Displays metrics about the user's spending habits. Computes `TotalCosts`, category proportions, and visualizes a monthly bar/pie chart breakdown. The VM pre-maps the necessary 12-month array of displayable costs to keep scroll performance smooth. |
| **TimelineView** | `TimelineViewModel` | Gives an absolute chronological rundown of approaching charges grouped by Month. For recurring items, users can "Mark as Paid", executing `advanceDueDate()` which automatically shifts the expense into its next cycle. |
| **SearchView** | *N/A* | Allows users to query the SwiftData model context by title explicitly to find distinct past/future entries. |

### Detailed Views (Inspectors)
The `Detailed Views` folder contains the editing forms: `ExpenseInspector`, `CategoryInspector`, and `AccountInspector`. These modules are designed to:
- Bind directly to a `Draft` struct instead of the SwiftData object.
- Automatically save and overwrite the corresponding Core Data target *only* when the execution buttons ("Save", "Create") are actioned.

---

## ⚙️ App Global Configuration

### `UIState`
A centralized coordinator that manages volatile global application states. It dictates what the user is currently displaying: e.g. `selectedFilter`, `selectedDisplayPeriod` (is the user viewing Monthly or Yearly costs?), `selectedSort`, and `selectedAccountIDs` map states.

### `SetupCoordinator`
On application startup inside `KostentrackerApp.swift`, `SetupCoordinator` is instantiated to run any fundamental checks such as enforcing minimum Default Categories, ensuring all accounts are attached to expenses, and purging invalid redundant context references.

---

## 🎯 Future-Proofing & Best Practices
- **Accessibility**: A voice-over `accessibilityLabel` has been mapped out on `Expense` rendering a cleanly formulated sentence summarizing the expense title, amount, and frequency. This shouldn't be overlooked in subsequent additions.
- **Performance Optimizations**: Heavy dictionary aggregations required for graphs and groups have been fully stripped from SwiftUI `var body: some View` and pushed into `@Observable` state objects, strictly guarding against UI lag.

> [!TIP] 
> Whenever you add new views, ensure that complex data slicing logic defaults back into an isolated ViewModel or Model-side helper function to keep the codebase "Clutter-Free".
