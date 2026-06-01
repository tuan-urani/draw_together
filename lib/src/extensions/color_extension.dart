import 'dart:ui';

extension ColorOpacity on Color {
  Color withOpacityX(double value) => withAlpha((value * 255).toInt());
}
