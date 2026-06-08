import 'dart:math';

import 'package:flutter/material.dart';

import 'package:draw_together/src/core/model/drawing_stroke_segment.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class SlowDrawingCanvas extends StatefulWidget {
  const SlowDrawingCanvas({
    required this.roomId,
    required this.roundId,
    required this.playerId,
    required this.colorHex,
    required this.segments,
    required this.enabled,
    required this.onSegment,
    this.repaintBoundaryKey,
    this.lockedOverlay,
    super.key,
  });

  final String roomId;
  final String roundId;
  final String playerId;
  final String colorHex;
  final List<DrawingStrokeSegment> segments;
  final bool enabled;
  final ValueChanged<DrawingStrokeSegment> onSegment;
  final GlobalKey? repaintBoundaryKey;
  final Widget? lockedOverlay;

  @override
  State<SlowDrawingCanvas> createState() => _SlowDrawingCanvasState();
}

class _SlowDrawingCanvasState extends State<SlowDrawingCanvas> {
  final Stopwatch _strokeClock = Stopwatch();
  final List<DrawingPoint> _buffer = <DrawingPoint>[];

  String? _strokeId;
  int _seq = 0;
  int _skipCounter = 0;
  Offset? _lastLocalPoint;
  DateTime? _lastMoveAt;
  double _segmentWidth = 5;
  double _segmentOpacity = 1;

  @override
  void didUpdateWidget(covariant SlowDrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _finishStroke();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            RepaintBoundary(
              key: widget.repaintBoundaryKey,
              child: ClipRRect(
                borderRadius: 18.borderRadiusAll,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: widget.enabled
                      ? (details) => _startStroke(details, canvasSize)
                      : null,
                  onPanUpdate: widget.enabled
                      ? (details) => _updateStroke(details, canvasSize)
                      : null,
                  onPanEnd: widget.enabled ? (_) => _finishStroke() : null,
                  onPanCancel: widget.enabled ? _finishStroke : null,
                  child: SizedBox.expand(
                    child: CustomPaint(
                      foregroundPainter: _SlowDrawingPainter(widget.segments),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: AppColors.white),
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(painter: _DotGridPainter()),
                            ),
                            if (widget.enabled && widget.segments.isEmpty)
                              const Center(child: _CanvasEmptyHint()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.enabled && widget.lockedOverlay != null)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.black.withValues(alpha: 0.22),
                  child: widget.lockedOverlay!,
                ),
              ),
          ],
        );
      },
    );
  }

  void _startStroke(DragStartDetails details, Size canvasSize) {
    _strokeId = '${widget.playerId}-${DateTime.now().microsecondsSinceEpoch}';
    _seq = 0;
    _skipCounter = 0;
    _buffer.clear();
    _strokeClock
      ..reset()
      ..start();

    final localPoint = _clampToCanvas(details.localPosition, canvasSize);
    _lastLocalPoint = localPoint;
    _lastMoveAt = DateTime.now();
    _segmentWidth = 5;
    _segmentOpacity = 1;
    _buffer.add(_normalizedPoint(localPoint, canvasSize));
  }

  void _updateStroke(DragUpdateDetails details, Size canvasSize) {
    final strokeId = _strokeId;
    if (strokeId == null) return;

    final now = DateTime.now();
    final localPoint = _clampToCanvas(details.localPosition, canvasSize);
    final previousPoint = _lastLocalPoint ?? localPoint;
    final previousMoveAt = _lastMoveAt ?? now;
    final deltaMs = max(1, now.difference(previousMoveAt).inMilliseconds);
    final distance = (localPoint - previousPoint).distance;
    final speed = distance / deltaMs * 1000;

    final isSeverelyFast = speed > 1100;
    if (isSeverelyFast) {
      _skipCounter += 1;
      if (_skipCounter.isOdd) {
        _lastLocalPoint = localPoint;
        _lastMoveAt = now;
        return;
      }
    }

    _segmentOpacity = speed > 720 ? 0.28 : (speed > 430 ? 0.48 : 1);
    _segmentWidth = speed > 720 ? 2.4 : (speed > 430 ? 3.4 : 5);
    _buffer.add(_normalizedPoint(localPoint, canvasSize));
    _lastLocalPoint = localPoint;
    _lastMoveAt = now;

    if (_buffer.length >= 8) {
      _flushSegment(keepTail: true);
    }
  }

  void _finishStroke() {
    _flushSegment(keepTail: false);
    _strokeClock.stop();
    _strokeId = null;
    _buffer.clear();
    _lastLocalPoint = null;
    _lastMoveAt = null;
  }

  void _flushSegment({required bool keepTail}) {
    final strokeId = _strokeId;
    if (strokeId == null || _buffer.length < 2) return;

    final segment = DrawingStrokeSegment(
      roomId: widget.roomId,
      roundId: widget.roundId,
      playerId: widget.playerId,
      strokeId: strokeId,
      seq: _seq,
      colorHex: widget.colorHex,
      width: _segmentWidth,
      opacity: _segmentOpacity,
      points: List<DrawingPoint>.unmodifiable(_buffer),
    );

    widget.onSegment(segment);
    _seq += 1;

    final tail = _buffer.last;
    _buffer.clear();
    if (keepTail) {
      _buffer.add(tail);
    }
  }

  Offset _clampToCanvas(Offset point, Size canvasSize) {
    return Offset(
      point.dx.clamp(0, canvasSize.width).toDouble(),
      point.dy.clamp(0, canvasSize.height).toDouble(),
    );
  }

  DrawingPoint _normalizedPoint(Offset point, Size canvasSize) {
    final width = canvasSize.width == 0 ? 1 : canvasSize.width;
    final height = canvasSize.height == 0 ? 1 : canvasSize.height;

    return DrawingPoint(
      x: point.dx / width,
      y: point.dy / height,
      dtMs: _strokeClock.elapsedMilliseconds,
    );
  }
}

class _CanvasEmptyHint extends StatelessWidget {
  const _CanvasEmptyHint();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.draw_rounded,
            size: 84,
            color: const Color(0xFF2F84FF).withValues(alpha: 0.48),
          ),
          18.height,
          Text(
            'Start drawing!',
            style: AppStyles.h4(
              color: const Color(0xFF5D91E8),
              fontWeight: FontWeight.w900,
            ),
          ),
          8.height,
          Text(
            "Your teammates can't see\nuntil time runs out.",
            textAlign: TextAlign.center,
            style: AppStyles.bodyLarge(
              color: const Color(0xFF5D91E8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF88A9D8).withValues(alpha: 0.16)
      ..strokeWidth = 1;
    const step = 14.0;
    for (var x = step; x < size.width; x += step) {
      for (var y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlowDrawingPainter extends CustomPainter {
  const _SlowDrawingPainter(this.segments);

  final List<DrawingStrokeSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    for (final segment in segments) {
      if (segment.points.length < 2) continue;

      final paint = Paint()
        ..color = _colorFromHex(
          segment.colorHex,
        ).withValues(alpha: segment.opacity.clamp(0.05, 1))
        ..strokeWidth = segment.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = segment.points.first;
      path.moveTo(first.x * size.width, first.y * size.height);

      for (final point in segment.points.skip(1)) {
        path.lineTo(point.x * size.width, point.y * size.height);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SlowDrawingPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }

  Color _colorFromHex(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}
