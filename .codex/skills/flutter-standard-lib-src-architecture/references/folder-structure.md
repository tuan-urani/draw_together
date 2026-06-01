# Standard lib/src Folder Structure

A complete blueprint for the standard `lib/src` structure and a single page module.

```text
lib/src/
├── api/
├── core/
├── di/
├── enums/
├── extensions/
├── helper/
├── locale/
├── ui/
│   ├── authentication/
│   │   ├── binding/
│   │   │   └── authentication_binding.dart
│   │   ├── components/
│   │   │   └── login_form.dart
│   │   ├── interactor/
│   │   │   └── authentication_interactor.dart
│   │   └── authentication_page.dart
│   └── widgets/
│       └── app_button.dart
└── utils/
    ├── app_styles.dart
    ├── app_colors.dart
    └── app_pages.dart
```

## **Key Constraints**

1. **Page Encapsulation**: `ui/<page>/components` and `ui/<page>/binding` are page-private.
2. **Shared UI**: If reused by multiple pages, move it to `ui/widgets/`.
3. **No UI in API/Core**: `api/` and `core/` must not import from `ui/`.
