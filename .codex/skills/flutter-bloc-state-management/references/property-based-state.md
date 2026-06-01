# Property-Based State Pattern (Forms & Complex Data)

This pattern uses a single data class to maintain the entire state of a feature. It is the preferred approach for forms, multi-step wizards, and screens with persistent filtering.

## **Pattern Implementation**

```dart
class NewRequestState extends Equatable {
  final List<ReturnMaterial> selectedItems;
  final String returnReference;
  final SalesOrg salesOrg;

  final bool showErrorMessages;
  final bool isSubmitting;

  final String? submitSuccessMessage;
  final ApiFailure? submitFailure;

  const NewRequestState({
    required this.selectedItems,
    required this.returnReference,
    required this.salesOrg,
    required this.showErrorMessages,
    required this.isSubmitting,
    this.submitSuccessMessage,
    this.submitFailure,
  });

  factory NewRequestState.initial() => NewRequestState(
        selectedItems: const [],
        returnReference: '',
        salesOrg: SalesOrg.empty(),
        showErrorMessages: false,
        isSubmitting: false,
      );

  NewRequestState copyWith({
    List<ReturnMaterial>? selectedItems,
    String? returnReference,
    SalesOrg? salesOrg,
    bool? showErrorMessages,
    bool? isSubmitting,
    String? submitSuccessMessage,
    ApiFailure? submitFailure,
  }) {
    return NewRequestState(
      selectedItems: selectedItems ?? this.selectedItems,
      returnReference: returnReference ?? this.returnReference,
      salesOrg: salesOrg ?? this.salesOrg,
      showErrorMessages: showErrorMessages ?? this.showErrorMessages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccessMessage: submitSuccessMessage,
      submitFailure: submitFailure,
    );
  }

  @override
  List<Object?> get props => [
        selectedItems,
        returnReference,
        salesOrg,
        showErrorMessages,
        isSubmitting,
        submitSuccessMessage,
        submitFailure,
      ];
}
```

## **When to use this vs. Union States?**

### **1. Use Property-Based (Flat) State when:**

- **Preservation is key**: You are building a **Form** or a **wizard** where users enter data. If you used a Union `Loading` state, the user's current input would be lost unless passed forward manually.
- **Overlapping UI**: You need to show a loading indicator *on top* of existing data (e.g., a "loading" overlay on a list).
- **Complex Filtering**: Multiple filters (search, date, category) that all need to persist.

### **2. Use Union States (Sealed Classes) when:**

- **Exclusive Phases**: The screen looks completely different in each state (e.g., Login Screen -> Loading Spinner -> Dashboard).
- **Simple Lifecycle**: Fetch data once -> Display it. No complex user input involved.
- **Type Safety**: The UI *must* have data in the `Success` state and *must not* have it in `Initial`.

## **UI Consumption (Success/Failure fields)**

```dart
BlocListener<NewRequestBloc, NewRequestState>(
  listenWhen: (p, c) =>
      p.submitSuccessMessage != c.submitSuccessMessage ||
      p.submitFailure != c.submitFailure,
  listener: (context, state) {
    if (state.submitFailure != null) {
      showErrorSnackbar(state.submitFailure!.message);
      return;
    }
    if (state.submitSuccessMessage != null) {
      navigateToSummary();
      return;
    }
  },
  child: ...,
)
```
