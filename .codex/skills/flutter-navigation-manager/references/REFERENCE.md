# GetX Routing Reference

Examples for implementing scalable routing with **GetX** and nested **Navigator** stacks.

## References

- [Router Configuration](router-config.md) — Standard setup with `AppPages`, `GetPage`, and `CommonRouter`.
- [Skill: Flutter Navigation Manager](../SKILL.md) — Strategy, prototype mapping, and arguments.

## Quick Navigation

```dart
// Full-screen route (hides BottomBar)
Get.toNamed(AppPages.detail, arguments: {'id': 123});
// Back
Navigator.pop(context);
```

```dart
// Nested route under BottomBar (keeps visible)
Navigator.of(context).pushNamed(
  AppPages.detail,
  arguments: {'id': 123},
);
// Back
Navigator.pop(context);
```

## Arguments

```dart
// GetX: send & receive
Get.toNamed(AppPages.detail, arguments: {'id': 123, 'mode': 'edit'});
final args = Get.arguments as Map<String, dynamic>;
final id = args['id'] as int;
final mode = args['mode'] as String?;
```

```dart
// Navigator: prefer pushNamed with arguments
Navigator.of(context).pushNamed(
  AppPages.detail,
  arguments: {'id': 123, 'mode': 'edit'},
);
// Receive in the destination page
final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
final id = args?['id'] as int?;
final mode = args?['mode'] as String?;
```

## Bindings

Use bindings with routes to initialize dependencies:

```dart
// AppPages (GetPage)
GetPage(
  name: AppPages.notification,
  page: () => const NotificationPage(),
  binding: NotificationBinding(),
);
```

```dart
// CommonRouter (nested/shared) using GetPageRoute
return GetPageRoute(
  page: () => const NotificationPage(),
  settings: settings,
  binding: NotificationBinding(),
);
```
