import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:draw_together/src/core/model/drawing_stroke_segment.dart';
import 'package:draw_together/src/ui/drawing/components/slow_drawing_canvas.dart';

void main() {
  testWidgets('SlowDrawingCanvas emits a segment when dragged', (tester) async {
    final segments = <DrawingStrokeSegment>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 420,
              child: SlowDrawingCanvas(
                roomId: 'room-1',
                roundId: 'round-1',
                playerId: 'player-1',
                colorHex: '#0095FF',
                segments: const <DrawingStrokeSegment>[],
                enabled: true,
                onSegment: segments.add,
              ),
            ),
          ),
        ),
      ),
    );

    final canvas = find.byType(SlowDrawingCanvas);
    await tester.drag(canvas, const Offset(80, 40));
    await tester.pump();

    expect(segments, isNotEmpty);
    expect(segments.first.points.length, greaterThanOrEqualTo(2));
  });

  testWidgets('SlowDrawingCanvas paints strokes above the white background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 420,
            child: SlowDrawingCanvas(
              roomId: 'room-1',
              roundId: 'round-1',
              playerId: 'player-1',
              colorHex: '#0095FF',
              segments: <DrawingStrokeSegment>[],
              enabled: true,
              onSegment: _noopSegment,
            ),
          ),
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(SlowDrawingCanvas),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.foregroundPainter != null,
        ),
      ),
    );

    expect(customPaint.painter, isNull);
    expect(customPaint.foregroundPainter, isNotNull);
  });

  testWidgets('SlowDrawingCanvas fills rectangular constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 420,
            child: SlowDrawingCanvas(
              roomId: 'room-1',
              roundId: 'round-1',
              playerId: 'player-1',
              colorHex: '#0095FF',
              segments: <DrawingStrokeSegment>[],
              enabled: true,
              onSegment: _noopSegment,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(SlowDrawingCanvas));
    expect(size, const Size(300, 420));
  });
}

void _noopSegment(DrawingStrokeSegment segment) {}
