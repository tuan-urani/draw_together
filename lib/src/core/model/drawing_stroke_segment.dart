class DrawingPoint {
  const DrawingPoint({required this.x, required this.y, required this.dtMs});

  final double x;
  final double y;
  final int dtMs;

  factory DrawingPoint.fromJson(Object value) {
    final point = value as List<dynamic>;
    return DrawingPoint(
      x: (point[0] as num).toDouble(),
      y: (point[1] as num).toDouble(),
      dtMs: (point[2] as num).round(),
    );
  }

  List<num> toJson() => <num>[x, y, dtMs];
}

class DrawingStrokeSegment {
  const DrawingStrokeSegment({
    required this.roomId,
    required this.roundId,
    required this.playerId,
    required this.strokeId,
    required this.seq,
    required this.colorHex,
    required this.width,
    required this.opacity,
    required this.points,
  });

  final String roomId;
  final String roundId;
  final String playerId;
  final String strokeId;
  final int seq;
  final String colorHex;
  final double width;
  final double opacity;
  final List<DrawingPoint> points;

  String get dedupeKey => '$strokeId:$seq';

  factory DrawingStrokeSegment.fromBroadcastPayload(
    Map<String, dynamic> payload,
  ) {
    final rawPoints = payload['points'] as List<dynamic>? ?? <dynamic>[];

    return DrawingStrokeSegment(
      roomId: payload['roomId'] as String? ?? '',
      roundId: payload['roundId'] as String? ?? '',
      playerId: payload['playerId'] as String? ?? '',
      strokeId: payload['strokeId'] as String? ?? '',
      seq: payload['seq'] as int? ?? 0,
      colorHex: payload['color'] as String? ?? '#333333',
      width: (payload['width'] as num?)?.toDouble() ?? 4,
      opacity: (payload['opacity'] as num?)?.toDouble() ?? 1,
      points: rawPoints
          .map((point) => DrawingPoint.fromJson(point))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toBroadcastPayload() {
    return <String, dynamic>{
      'type': 'stroke_segment',
      'roomId': roomId,
      'roundId': roundId,
      'playerId': playerId,
      'strokeId': strokeId,
      'seq': seq,
      'color': colorHex,
      'width': width,
      'opacity': opacity,
      'points': points.map((point) => point.toJson()).toList(),
    };
  }
}
