# New Page Localization Template (GetX)

This template follows modular locale maps per feature with aggregator files.

## 1) Add keys (LocaleKey)

```dart
// lib/src/locale/keys/customer_detail_locale_key.dart
class CustomerDetailLocaleKey {
  static const String title = 'customer_detail_title';
  static const String save = 'customer_detail_save';
  static const String delete = 'customer_detail_delete';
}

// lib/src/locale/locale_key.dart (barrel)
export 'keys/customer_detail_locale_key.dart';
```

## 2) Add feature language modules

```dart
// lib/src/locale/en/customer_detail_en.dart
import '../locale_key.dart';

final Map<String, String> customerDetailEn = <String, String>{
  CustomerDetailLocaleKey.title: 'Customer Detail',
  CustomerDetailLocaleKey.save: 'Save',
  CustomerDetailLocaleKey.delete: 'Delete',
};
```

```dart
// lib/src/locale/ja/customer_detail_ja.dart
import '../locale_key.dart';

final Map<String, String> customerDetailJa = <String, String>{
  CustomerDetailLocaleKey.title: '顧客詳細',
  CustomerDetailLocaleKey.save: '保存',
  CustomerDetailLocaleKey.delete: '削除',
};
```

```dart
// lib/src/locale/vi/customer_detail_vi.dart
import '../locale_key.dart';

final Map<String, String> customerDetailVi = <String, String>{
  CustomerDetailLocaleKey.title: 'Chi tiết khách hàng',
  CustomerDetailLocaleKey.save: 'Lưu',
  CustomerDetailLocaleKey.delete: 'Xóa',
};
```

## 3) Merge in language aggregators

```dart
// lib/src/locale/lang_en.dart
import 'en/customer_detail_en.dart' as customer_detail_en;

final Map<String, String> enUs = <String, String>{
  ...customer_detail_en.customerDetailEn,
};
```

```dart
// lib/src/locale/lang_ja.dart
import 'ja/customer_detail_ja.dart' as customer_detail_ja;

final Map<String, String> jaJp = <String, String>{
  ...customer_detail_ja.customerDetailJa,
};
```

```dart
// lib/src/locale/lang_vi.dart
import 'vi/customer_detail_vi.dart' as customer_detail_vi;

final Map<String, String> viVn = <String, String>{
  ...customer_detail_vi.customerDetailVi,
};
```

## 4) Register locales

```dart
// lib/src/locale/translation_manager.dart
Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
  'en_US': enUs,
  'ja_JP': jaJp,
  'vi_VN': viVn,
};
```

## 5) Use in UI

```dart
Text(CustomerDetailLocaleKey.title.tr)
```

## 6) Quick checks

- All active locale modules contain same key set.
- No raw strings in widgets.
- `lang_*.dart` contains only map aggregation (no inline feature strings).
