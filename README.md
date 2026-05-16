# ClutterFree Expenses - Technical Documentation

> [!NOTE]
> This is the official technical documentation for **ClutterFree Expenses** (internal project name: *Kostentracker*). This document provides a high-level overview of the application's architecture, data models, views, and core logic components for the solo developer currently maintaining it.

## 📱 App Overview

**ClutterFree Expenses** is a streamlined, SwiftUI-based iOS application designed to track user spending, manage recurring costs, and visually highlight cash flow. The application prioritizes aesthetic design, strong visual hierarchy, and unparalleled performance achieved through live reactive data binding and lightweight local computed transformations. 

It is built completely with native Apple frameworks, utilizing **SwiftUI** for the user interface and **SwiftData** for local offline persistence.

---

## 🏗️ Architecture

The app is built using a modern **Reactive, State-Driven SwiftUI + SwiftData** architectural pattern. Rather than relying on separate ViewModel layers, the application leverages SwiftData's live query engine to stream data directly into the view, where it is transformed on-the-fly via localized computed properties and extension helpers.

### Key Architectural Guidelines
1. **Live Database Streams**: Views declare live query descriptors using `@Query`. SwiftData automatically tracks changes to the persistent store and animates changes in real time.
2. **Local Computed State**: Heavy transformations (such as chronological grouping, currency formatting, and statistics calculations) are localized to dedicated computed properties (e.g., `processedGroups` or `stats`) directly within each view, keeping layout structure simple.
3. **Draft Architecture for Mutation**: Creating or editing models (`Expense`, `ExpenseCategory`, `ExpenseAccount`) doesn't mutate SwiftData objects directly until the user confirms. Instead, the UI works on a lightweight temporary `Draft` struct (e.g., `CategoryDraft` or `ExpenseDraft`).
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

### Tabs & Live Views

| View Component | Data Slicing & Processing | Description |
|---|---|---|
| **ListView** | Local `processedGroups` property | Shows all saved entries. Supports dynamic grouping (`none`, `categories`, `frequency`) and sorting. Processes the SwiftData query array into `ProcessedGroup` structs on-the-fly. |
| **StatisticsView** | Local `stats` property | Displays metrics about the user's spending habits. Computes aggregated costs, category proportions, and maps out a 12-month array of monthly costs for charts. |
| **TimelineView** | Local `monthlyGroups` property | Gives a chronological rundown of approaching charges grouped by month. For recurring items, handles advancing the due date when marked as paid. |
| **SearchView** | Local title-based filtering | Allows users to query the SwiftData model context by title explicitly to find distinct past/future entries. |

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
- **Performance Optimizations**: Heavy dictionary aggregations and grouping logic should be isolated in extension methods or computed properties. When a computed property is accessed multiple times inside a SwiftUI view's `body` rendering pass, evaluate it once and store it in a local constant (`let currentStats = stats`) to avoid redundant repeat calculations.

> [!TIP] 
> Whenever you add new views, keep complex layout and data slicing logic cleanly separated into localized data structures and helper methods to keep the codebase "Clutter-Free".
