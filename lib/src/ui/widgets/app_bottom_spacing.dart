import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class AppBottomSpacing extends StatelessWidget {
  final double padding;
  const AppBottomSpacing({super.key, this.padding = 0});

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, visible) {
        return SizedBox(
          height: visible
              ? MediaQuery.of(context).viewInsets.bottom + padding
              : padding,
        );
      },
    );
  }
}
