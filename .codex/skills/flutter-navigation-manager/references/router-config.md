# Router Configuration (GetX)

## AppPages Configuration
Located in `lib/src/utils/app_pages.dart`.

```dart
import 'package:get/get.dart';
import 'package:link_home/src/ui/home/home_page.dart';
import 'package:link_home/src/ui/auth/login/login_page.dart';
import 'package:link_home/src/ui/auth/login/binding/login_binding.dart';

class AppPages {
  static const String login = _Paths.login;
  static const String home = _Paths.home;

  static final pages = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginPage(),
      binding: LoginBinding(), // Attach Binding
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomePage(),
    ),
  ];
}

abstract class _Paths {
  static const String login = "/login";
  static const String home = "/home";
}
```

## Common Router (Nested/Shared)
Located in `lib/src/ui/routing/common_router.dart`.
Used for handling routes that might be accessible from multiple entry points or require custom transitions.

```dart
class CommonRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppPages.notification:
        return GetPageRoute(
          page: () => const NotificationPage(),
          settings: settings,
          binding: NotificationBinding(),
        );
      default:
        return GetPageRoute(
          page: () => const NotFoundPage(),
          settings: settings,
        );
    }
  }
}
```
