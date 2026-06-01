---
name: GetX Localization Standard
description: "Standards for GetX-based multi-language (locale_key + lang_*.dart). Invoke when generating a new page/feature or adding any user-facing text."
---

# GetX Localization Standard

## Priority

P1 (HIGH)

All user-facing text MUST be localized via GetX translations using `LocaleKey` + `lang_*.dart` aggregators.

## Core Rules

### 1) LocaleKey update is mandatory
- Add every new key used by the feature.
- Key naming format: `<feature>_<screen>_<element>` in `snake_case`.
- Prefer split-by-feature key files:
  - `lib/src/locale/keys/<feature>_locale_key.dart`
  - `lib/src/locale/locale_key.dart` acts as barrel/aggregator.

### 2) Update all active languages
When adding keys, update all active locale maps.
Current baseline in this pack:
- `en_US` (`enUs`)
- `ja_JP` (`jaJp`)
- `vi_VN` (`viVn`) when project enables Vietnamese

No active language is allowed to miss keys.

### 3) UI must use `.tr`
- Always write: `LocaleKey.some_key.tr`
- Never hardcode visible strings in widgets.

## Project Structure (Source of Truth)

- Keys: `lib/src/locale/locale_key.dart` (+ optional `lib/src/locale/keys/*.dart`)
- Feature language modules:
  - `lib/src/locale/en/<feature>_en.dart`
  - `lib/src/locale/ja/<feature>_ja.dart`
  - `lib/src/locale/vi/<feature>_vi.dart` (if enabled)
- Language aggregators:
  - `lib/src/locale/lang_en.dart` exporting `enUs`
  - `lib/src/locale/lang_ja.dart` exporting `jaJp`
  - `lib/src/locale/lang_vi.dart` exporting `viVn` (if enabled)
- Registry:
  - `lib/src/locale/translation_manager.dart`

## Aggregator Contract (Required)

- `lang_*.dart` are aggregator-only files.
- Merge feature maps with spread syntax:
  - `...home_en.homeEn`
  - `...onboarding_en.onboardingEn`
- Do not place inline feature strings directly in `lang_*.dart`.
- Keep exported map names stable (`enUs`, `jaJp`, `viVn`).

## Feature Modularization Pattern

- Split translations by feature to reduce merge conflicts:
  - `en/onboarding_en.dart`, `ja/onboarding_ja.dart`, `vi/onboarding_vi.dart`
- Create a feature `common` module per language for shared phrases:
  - `common_en.dart`, `common_ja.dart`, `common_vi.dart`
- Reuse common keys (`ok`, `cancel`, `loading`, `error`) instead of duplicating per feature.

## Adding a New Language

1. Create feature modules under `lib/src/locale/<lang>/`.
2. Create `lang_<lang>.dart` aggregator exporting locale map variable.
3. Register locale in `TranslationManager.appLocales` and `TranslationManager.keys`.
4. Ensure parity with existing active locales.

## Verification Gates

- Any new page with raw strings is rejected.
- Any key added without updating all active locale modules is rejected.
- `lang_*.dart` must remain aggregator-only.
- Locale parity check must pass across all active languages.

## Recommended Parity Check (Optional Script)

- Compare keys in `locale_key.dart` with keys used in locale modules (`en/`, `ja/`, `vi/`).
- Block merge if missing/extra keys are detected.
