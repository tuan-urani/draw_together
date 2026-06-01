import 'package:flutter/material.dart';
import '../extensions/color_extension.dart';

class AppColors {
  // ===========================================================================
  // PRIMARY
  // ===========================================================================
  static const Color primary = Color(0xFF84C93F);
  static const Color primaryLight = Color(0xFF5CC7A0);

  /// Alpha variants
  static const Color primaryAlpha10 = Color(0x1A84C93F);

  // Backward compatibility
  static const Color color84C93F = primaryAlpha10;
  static const Color color1A84C93F = primaryAlpha10;

  // ===========================================================================
  // SECONDARY
  // ===========================================================================
  static const Color secondary1 = Color(0xFFCAE7B4);
  static const Color secondary2 = Color(0xFFE6F4EC);

  // ===========================================================================
  // NEUTRAL / BLACK
  // ===========================================================================
  static const Color black = Color(0xFF000000);

  // ===========================================================================
  // NEUTRAL / WHITE
  // ===========================================================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);

  // ===========================================================================
  // STATUS
  // ===========================================================================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ===========================================================================
  // TEXT
  // ===========================================================================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textDisabled = Color(0xFFC0C0C0);
  static const Color textInverse = white;

  static const greyF3 = Color(0xFFF3F3F3);
  static const color2D7DD2 = Color(0xFF2D7DD2);
  static const color1D2410 = Color(0xFF1D2410);
  static const color484848 = Color(0xFF484848);
  static const color1C274C = Color(0xFF1C274C);
  static const colorFFF4F2 = Color(0xFFFFF4F2);
  static const colorF5F7FA = Color(0xFFF5F7FA);
  static const colorE6F7ED = Color(0xFFE6F7ED);
  static const color667394 = Color(0xFF667394);
  static const colorFF9800 = Color(0xFFFF9800);
  static const colorB8BCC6 = Color(0xFFB8BCC6);
  static const colorF2F4F7 = Color(0xFFF2F4F7);
  static const colorF9FAFB = Color(0xFFF9FAFB);
  static const colorE1E1E1 = Color(0xFFE1E1E1);
  static const colorE3F2D9 = Color(0xFFE3F2D9);
  static const colorEEEDE9 = Color(0xFFEEEDE9);
  static const color333333 = Color(0xFF333333);
  static const colorEFF8DD = Color(0xFFEFF8DD);
  static const color475467 = Color(0xFF475467);
  static const colorE8EDF5 = Color(0xFFE8EDF5);
  static const colorF4F4F4 = Color(0xFFF4F4F4);
  static const color131A29 = Color(0xFF131A29);
  static const colorD1E8BE = Color(0xFFD1E8BE);
  static const colorE6FAD2 = Color(0xFFE6FAD2);
  static const colorDAFFE0 = Color(0xFFDAFFE0);
  static const color0F000000 = Color(0x0F000000);
  static const colorFAFAFA = Color(0xFFFAFAFA);
  static const colorF8F1DD = Color(0xFFF8F1DD);
  static const colorB7B7B7 = Color(0xFFB7B7B7);
  static const colorFF8C42 = Color(0xFFFF8C42);
  static const color1AFF8C42 = Color(0x1AFF8C42);
  static const colorF1D2BC = Color(0xFFF1D2BC);
  static const colorDFE4F5 = Color(0xFFDFE4F5);
  static const colorF39702 = Color(0xFFF39702);
  static const colorFB1B8D1 = Color(0xFFB1B8D1);
  static const colorF64748B = Color(0xFF64748B);
  static const colorFEF4056 = Color(0xFFEF4056);
  static const colorF586AA6 = Color(0xFF586AA6);
  static const colorFDEF1BC = Color(0xFFDEF1BC);
  static const color101828 = Color(0xFF101828);
  static const colorFFE53E = Color(0xFFFFE53E);
  static const colorEEEAE8 = Color(0xFFEEEAE8);
  static const colorEF4056 = Color(0xFFEF4056);
  static const color1AEF4056 = Color(0x1AEF4056);
  static const colorFF5B42 = Color(0xFFFF5B42);
  static const color33FF5B42 = Color(0x33FF5B42);
  static const color0095FF = Color(0xFF0095FF);
  static const color1A0095FF = Color(0x1A0095FF);
  static const color88CF66 = Color(0xFF88CF66);
  static const color1A88CF66 = Color(0x1A88CF66);
  static const color1A2D7DD2 = Color(0x1A2D7DD2);
  static const colorFEFEFE = Color(0xFFFEFEFE);
  static const colorDCDFEB = Color(0xFFDCDFEB);
  static const color80586AA6 = Color(0x80586AA6);
  static const colorF59AEF9 = Color(0xFF59AEF9);
  static const colorFE4F3FF = Color(0xFFE4F3FF);
  static const colorF6B7280 = Color(0xFF6B7280);
  static const colorFE6F4EC = Color(0xFFE6F4EC);
  static const colorFBFC9DE = Color(0xFFBFC9DE);
  static const colorFE7EDF3 = Color(0xFFE7EDF3);
  static const colorFDCDFEB = Color(0xFFDCDFEB);
  static const colorF101828 = Color(0xFF101828);
  static const colorF646C72 = Color(0xFF646C72);
  static const colorF3F7FC9 = Color(0xFF3F7FC9);
  static const colorFA1AEBE = Color(0xFFA1AEBE);
  static const colorEAF9E6 = Color(0xFFEAF9E6);
  static const colorC8E6C9 = Color(0xFFC8E6C9);
  static const colorE3F2FD = Color(0xFFE3F2FD);
  static const colorFFF3E0 = Color(0xFFFFF3E0);
  static const colorF3E5F5 = Color(0xFFF3E5F5);
  static const color9C27B0 = Color(0xFF9C27B0);
  static const colorFAF9F8 = Color(0xFFFAF9F8);
  static const colorCDCDCD = Color(0xFFCDCDCD);
  static const colorD9DEED = Color(0xFFD9DEED);
  static const colorFDFFFD = Color(0xFFFDFFFD);
  static const colorEBEDF0 = Color(0xFFEBEDF0);
  static const colorF8FAFB = Color(0xFFF8FAFB);
  static const colorFFEAEA = Color(0xFFFFEAEA);
  static const colorEAECF0 = Color(0xFFEAECF0);
  static const colorFFE2D0 = Color(0xFFFFE2D0);

  // ===========================================================================
  // BACKGROUND
  // ===========================================================================
  static const Color background = white;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundDisabled = Color(0xFFE5E5E5);
  static const Color backgroundOverlay = Color(0x80000000);

  // ===========================================================================
  // BORDER
  // ===========================================================================
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color borderDark = Color(0xFFBDBDBD);

  // ===========================================================================
  // GRADIENTS
  // ===========================================================================
  static LinearGradient primaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static LinearGradient secondaryGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary1],
  );

  static LinearGradient primaryTextGradient() =>
      const LinearGradient(colors: [primary, primaryLight]);

  static LinearGradient fadeGradient() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [black.withOpacityX(0.3), black],
  );

  static LinearGradient disabledGradient() =>
      const LinearGradient(colors: [border, borderDark]);

  static LinearGradient primaryBackgroundGradient() => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F7FA), Color(0xFFF2F1EC)],
  );

  // ===========================================================================
  // UTIL
  // ===========================================================================
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
