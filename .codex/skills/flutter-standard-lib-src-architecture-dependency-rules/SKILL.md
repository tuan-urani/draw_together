---
name: Flutter Standard lib/src Architecture (Dependency Rules)
description: Dependency flow and separation of concerns for the project (UI -> BLoC -> Repository).
---

# Project Architecture & Dependency Rules

## **Priority: P0 (CRITICAL)**

This project follows a feature-based Clean Architecture adapted for Flutter.

## Structure

```text
lib/src/
├── api/                  # API definitions & DTOs
├── core/
│   └── repository/       # Data Layer (Repositories)
├── di/                   # Dependency Injection Setup
├── ui/                   # Presentation Layer
│   ├── <feature>/
│   │   ├── binding/      # DI Bindings
│   │   ├── bloc/         # OR interactor/ (Business Logic)
│   │   └── <page>.dart   # UI Widget
│   └── routing/          # Routing Logic
└── utils/                # Helpers & Constants
```

## Dependency Flow

**UI** (`ui/<feature>`) 
  ↓ calls
**BLoC** (`ui/<feature>/bloc` or `interactor`)
  ↓ calls
**Repository** (`core/repository`)
  ↓ calls
**API / Local Storage**

## Rules

### 1. Presentation Layer (UI)
- **Responsibility**: Render UI, handle user input, listen to State.
- **Dependencies**: Can depend on `BLoC` (via `BlocBuilder`/`BlocListener`).
- **Forbidden**: NO direct API calls. NO direct Repository access.

### 2. Business Logic Layer (BLoC/Interactor)
- **Responsibility**: State management, business logic, calling repositories.
- **Dependencies**: Can depend on `Repository`.
- **Forbidden**: NO UI widgets (`BuildContext`, `Scaffold`).

### 3. Data Layer (Repository)
- **Responsibility**: Coordinate data sources (Remote API, Local DB).
- **Dependencies**: `Api`, `SharedPreference`, etc.
- **Forbidden**: NO knowledge of UI or BLoC.

## Reference & Examples

See [references/repository-mapping.md](references/repository-mapping.md).
