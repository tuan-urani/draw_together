import 'package:flutter/material.dart';

import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class PlayfulColors {
  const PlayfulColors._();

  static const Color background = Color(0xFFF1F8FF);
  static const Color ink = Color(0xFF0F2244);
  static const Color muted = Color(0xFF7D89A8);
  static const Color blue = Color(0xFF227BFF);
  static const Color cyan = Color(0xFF18B7F3);
  static const Color purple = Color(0xFF9B55F3);
  static const Color purpleDark = Color(0xFF6B2DE5);
  static const Color yellow = Color(0xFFFFC84D);
  static const Color green = Color(0xFF33C75A);
  static const Color softBlue = Color(0xFFE9F5FF);
  static const Color lobbyPurple = Color(0xFF6849E8);
  static const Color lobbySoftPurple = Color(0xFFF0E9FF);
  static const Color lobbySoftGreen = Color(0xFFE7F8EC);
  static const Color lobbyDivider = Color(0xFFE1E8F3);
  static const Color lobbyPlayerRow = Color(0xFFF8FAFF);
  static const Color lobbySeatInactive = Color(0xFFEAF1FB);
  static const Color lobbyBorder = Color(0xFFDCE8F8);
  static const Color lobbyWarning = Color(0xFFFFB62D);
  static const Color lobbyWarningSoft = Color(0xFFFFEBC0);

  static const LinearGradient coopCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, blue],
  );

  static const LinearGradient soloCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, purpleDark],
  );
}

class PlayfulScaffold extends StatelessWidget {
  const PlayfulScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlayfulColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _PlayfulBackground()),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class PlayfulHeader extends StatelessWidget {
  const PlayfulHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact
          ? const EdgeInsets.fromLTRB(6, 4, 6, 4)
          : const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          leading ?? SizedBox(width: compact ? 44 : 54),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: compact
                      ? AppStyles.h3(
                          color: PlayfulColors.ink,
                          fontWeight: FontWeight.w800,
                        )
                      : AppStyles.h1(
                          color: PlayfulColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                ),
                if (subtitle != null) ...[
                  (compact ? 4 : 8).height,
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: compact
                        ? AppStyles.bodyMedium(color: PlayfulColors.muted)
                        : AppStyles.bodyLarge(color: PlayfulColors.muted),
                  ),
                ],
              ],
            ),
          ),
          trailing ?? SizedBox(width: compact ? 44 : 54),
        ],
      ),
    );
  }
}

class PlayfulIconButton extends StatelessWidget {
  const PlayfulIconButton({
    required this.icon,
    required this.onTap,
    this.size = 54,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: playfulShadow,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: PlayfulColors.ink, size: size * 0.42),
        ),
      ),
    );
  }
}

class PlayfulCard extends StatelessWidget {
  const PlayfulCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.color = AppColors.white,
    this.border,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: playfulShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PlayfulGradientButton extends StatelessWidget {
  const PlayfulGradientButton({
    required this.title,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.gradient,
    this.height = 58,
    super.key,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Gradient? gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = enabled
        ? gradient ??
              const LinearGradient(
                colors: [PlayfulColors.cyan, PlayfulColors.blue],
              )
        : const LinearGradient(colors: [Color(0xFFEAEAEA), Color(0xFFE0E0E0)]);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: colors,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: enabled ? playfulBlueShadow : null,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.white, size: 25),
                10.width,
              ],
              Text(
                title,
                style: AppStyles.h4(
                  color: enabled ? AppColors.white : AppColors.textDisabled,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayfulAvatar extends StatelessWidget {
  const PlayfulAvatar({this.size = 78, this.online = true, super.key});

  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDFF1FF),
            border: Border.all(color: AppColors.white, width: size * 0.07),
            boxShadow: playfulShadow,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _DinoPainter()),
          ),
        ),
        if (online)
          Positioned(
            right: size * 0.02,
            bottom: size * 0.04,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PlayfulColors.green,
                border: Border.all(color: AppColors.white, width: 3),
              ),
              child: SizedBox(width: size * 0.2, height: size * 0.2),
            ),
          ),
      ],
    );
  }
}

class PlayfulChip extends StatelessWidget {
  const PlayfulChip({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: 99.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: color, size: 16), 6.width],
            Text(
              label,
              style: AppStyles.bodyMedium(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayfulIconTile extends StatelessWidget {
  const PlayfulIconTile({
    required this.icon,
    this.size = 76,
    this.background = const Color(0xFFE9F5FF),
    this.color = PlayfulColors.blue,
    super.key,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: size * 0.48, color: color),
        ),
      ),
    );
  }
}

final List<BoxShadow> playfulShadow = [
  BoxShadow(
    color: const Color(0xFF87A6C8).withValues(alpha: 0.16),
    blurRadius: 22,
    offset: const Offset(0, 10),
  ),
];

final List<BoxShadow> playfulBlueShadow = [
  BoxShadow(
    color: PlayfulColors.blue.withValues(alpha: 0.24),
    blurRadius: 16,
    offset: const Offset(0, 7),
  ),
];

class _PlayfulBackground extends StatelessWidget {
  const _PlayfulBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DoodleBackgroundPainter());
  }
}

class _DoodleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = PlayfulColors.blue.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final yellow = Paint()
      ..color = PlayfulColors.yellow.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void star(Offset center, double r, Paint paint) {
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r * 0.24, center.dy - r * 0.24)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx + r * 0.24, center.dy + r * 0.24)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r * 0.24, center.dy + r * 0.24)
        ..lineTo(center.dx - r, center.dy)
        ..lineTo(center.dx - r * 0.24, center.dy - r * 0.24)
        ..close();
      canvas.drawPath(path, paint);
    }

    star(Offset(size.width * 0.16, size.height * 0.15), 14, blue);
    star(Offset(size.width * 0.9, size.height * 0.52), 10, blue);
    star(Offset(size.width * 0.08, size.height * 0.72), 17, yellow);

    final path = Path()
      ..moveTo(size.width * 0.02, size.height * 0.22)
      ..cubicTo(
        size.width * 0.1,
        size.height * 0.18,
        size.width * 0.12,
        size.height * 0.27,
        size.width * 0.2,
        size.height * 0.22,
      );
    canvas.drawPath(path, blue);

    final squiggle = Path()
      ..moveTo(size.width * 0.88, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.09,
        size.width * 0.9,
        size.height * 0.17,
      )
      ..quadraticBezierTo(
        size.width * 0.96,
        size.height * 0.15,
        size.width * 0.93,
        size.height * 0.22,
      );
    canvas.drawPath(squiggle, blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DinoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale);

    final body = Paint()..color = const Color(0xFF2FA8FF);
    final shadow = Paint()..color = const Color(0xFF1785E8);
    final spike = Paint()..color = const Color(0xFFFFC544);
    final cheek = Paint()..color = const Color(0xFFFF86B6);
    final ink = Paint()..color = PlayfulColors.ink;

    final bodyPath = Path()
      ..moveTo(51, 20)
      ..cubicTo(28, 20, 20, 39, 24, 62)
      ..cubicTo(27, 83, 43, 91, 62, 88)
      ..cubicTo(79, 85, 87, 72, 83, 52)
      ..cubicTo(80, 33, 68, 20, 51, 20)
      ..close();
    canvas.drawPath(bodyPath, body);

    canvas.drawCircle(const Offset(66, 54), 17, shadow..color = shadow.color);
    canvas.drawCircle(const Offset(62, 50), 17, body);

    final spikes = [
      const Offset(25, 42),
      const Offset(25, 55),
      const Offset(28, 68),
    ];
    for (final point in spikes) {
      final path = Path()
        ..moveTo(point.dx, point.dy)
        ..lineTo(point.dx - 13, point.dy - 8)
        ..lineTo(point.dx - 12, point.dy + 8)
        ..close();
      canvas.drawPath(path, spike);
    }

    canvas.drawCircle(const Offset(56, 46), 5, AppColors.white.paint);
    canvas.drawCircle(const Offset(57, 47), 2.4, ink);
    canvas.drawCircle(const Offset(74, 47), 3.2, ink);
    canvas.drawCircle(const Offset(48, 60), 4, cheek);
    canvas.drawArc(
      const Rect.fromLTWH(61, 57, 15, 11),
      0.2,
      2.2,
      false,
      Paint()
        ..color = PlayfulColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension on Color {
  Paint get paint => Paint()..color = this;
}
