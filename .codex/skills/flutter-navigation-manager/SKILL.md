---
name: Flutter Navigation Manager
description: Routing strategy management (GetX is the Project Standard).
---

# Flutter Navigation Strategy

## **Active Strategy: GetX**

This project currently uses **GetX** for all navigation requirements.

**Do NOT use:**
- AutoRoute
- GoRouter
- Navigator 2.0 (Raw)

## Guidelines

### GetX Routing
- **Configuration**: `lib/src/utils/app_pages.dart`
- **Navigation**: `Get.toNamed()`, `Get.offNamed()`
- **Bindings**: Attach dependencies via `binding` property in `GetPage`.

### Prototype → Route Mapping Rules
- **Full Screen (Hides BottomBar)**: Register the route in `AppPages` and use `Get.toNamed(AppPages.some)`. Back: `Navigator.pop(context)`.
- **Nested Under BottomBar (Keeps Visible)**:
  - Register routes in `lib/src/ui/routing/<tab>_router.dart` (or `common_router.dart` if shared).
  - Use `Navigator.of(context).push(...)` to push onto the tab’s internal stack, avoiding root replacement.
  - Back: `Navigator.pop(context)` (do not use `Get.back()` to avoid popping the wrong stack).
- **Shared Page (Keeps BottomBar)**: Register in `common_router.dart` and use `Navigator.of(context)` within the current tab context.

### Decision Heuristics (Prototype Mapping)
- Destination keeps BottomBar visible → Nested route.
- Destination covers entire screen (modal/full-screen) → Full screen GetX route.
- Detail flow originating from the current tab (e.g., Customer → Customer Detail) → Nested.
- Flow leaving tab context (e.g., Login, standalone Privacy Policy) → Full screen.

### Arguments (GetX vs Navigator)
- **GetX (Full Screen)**:
  - Send: `Get.toNamed(AppPages.detail, arguments: {'id': 123, 'mode': 'edit'})`
  - Receive: 
    ```dart
    final args = Get.arguments as Map<String, dynamic>;
    final id = args['id'] as int;
    final mode = args['mode'] as String?;
    ```
- **Navigator (Nested)**:
  - Prefer constructor parameters for strong typing:
    ```dart
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailPage(id: 123, mode: 'edit'),
    ));
    ```
  - If using `settings.arguments`:
    ```dart
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(arguments: {'id': 123}),
      builder: (_) => const DetailPage(),
    ));
    // In DetailPage (build):
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    ```
  - Rule: Constructor > settings.arguments > Get.arguments in nested flows to avoid stack/context confusion.

### Examples
```dart
// Full screen: hides BottomBar
Get.toNamed(AppPages.visitRecord);
// Back
Navigator.pop(context);

// Nested: keeps BottomBar
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const CustomerDetailPage()),
);
// Back
Navigator.pop(context);
```

## Related Topics
getx-state-management | dependency-injection
