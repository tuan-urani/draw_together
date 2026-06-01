import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/drawing/bloc/drawing_board_bloc.dart';
import 'package:draw_together/src/ui/drawing/components/slow_drawing_canvas.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class DrawingBoardPage extends StatefulWidget {
  const DrawingBoardPage({super.key});

  @override
  State<DrawingBoardPage> createState() => _DrawingBoardPageState();
}

class _DrawingBoardPageState extends State<DrawingBoardPage> {
  late final DrawingBoardBloc _bloc;
  late final String _roomId;
  final GlobalKey _canvasBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<DrawingBoardBloc>();
    final args = Get.arguments;
    _roomId = args is Map ? args['roomId'] as String? ?? '' : '';
    if (_roomId.isNotEmpty) {
      _bloc.load(_roomId);
    }
  }

  @override
  void dispose() {
    _bloc.stopRoundTimer();
    _bloc.disconnectRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulScaffold(
      child: BlocConsumer<DrawingBoardBloc, DrawingBoardState>(
        bloc: _bloc,
        listener: (context, state) {
          final errorMessage = state.errorMessage;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            showErrorToast(errorMessage);
          }
        },
        builder: (context, state) {
          if (_roomId.isEmpty) {
            return Center(child: Text(LocaleKey.roomNotFound.tr));
          }

          if (state.pageState == PageState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final room = state.room;
          final round = state.round;
          final playerId = state.currentUserId;
          if (room == null || round == null || playerId == null) {
            return Center(
              child: PlayfulGradientButton(
                title: LocaleKey.retry.tr,
                onTap: () => _bloc.load(_roomId),
              ),
            );
          }

          final header = _RoundHeader(
            targetTitle: state.target?.title ?? round.targetImageId,
            targetUrl: state.targetUrl,
            remainingMs: state.remainingMs,
            isRealtimeConnected: state.isRealtimeConnected,
            colorHex: state.currentColorHex,
          );
          final board = SlowDrawingCanvas(
            repaintBoundaryKey: _canvasBoundaryKey,
            roomId: room.id,
            roundId: round.id,
            playerId: playerId,
            colorHex: state.currentColorHex,
            segments: state.segments,
            enabled: state.canDraw,
            onSegment: _bloc.addLocalSegment,
          );

          if (state.canDraw) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                children: [
                  PlayfulHeader(
                    title: LocaleKey.drawingBoard.tr,
                    compact: true,
                    leading: PlayfulIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: Get.back<void>,
                      size: 44,
                    ),
                    trailing: PlayfulIconButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: () {},
                      size: 44,
                    ),
                  ),
                  8.height,
                  header,
                  10.height,
                  Expanded(child: Center(child: board)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
            children: [
              PlayfulHeader(
                title: LocaleKey.drawingBoard.tr,
                compact: true,
                leading: PlayfulIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: Get.back<void>,
                  size: 44,
                ),
                trailing: PlayfulIconButton(
                  icon: Icons.more_horiz_rounded,
                  onTap: () {},
                  size: 44,
                ),
              ),
              8.height,
              header,
              10.height,
              board,
              10.height,
              _RoundStatusBar(text: _footerText(state)),
              ..._resultActions(state),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _resultActions(DrawingBoardState state) {
    return <Widget>[
      if (state.teamScore != null) ...[
        14.height,
        _ScoreCard(
          title: LocaleKey.teamScore.tr,
          score: state.teamScore!.teamScore ?? state.teamScore!.similarityScore,
        ),
      ],
      if (state.scores.isNotEmpty && state.isVersus) ...[
        14.height,
        _VersusScoreCard(state: state),
      ],
      if (state.canSubmitTeamCanvas ||
          state.canSubmitPlayerCanvas ||
          state.isSubmitting) ...[
        14.height,
        PlayfulGradientButton(
          title: state.isSubmitting
              ? LocaleKey.submittingDrawing.tr
              : LocaleKey.submitDrawing.tr,
          icon: Icons.upload_rounded,
          enabled: !state.isSubmitting,
          onTap: _exportAndSubmitCanvas,
        ),
      ],
      if (state.canScoreRound || state.isScoring) ...[
        14.height,
        PlayfulGradientButton(
          title: state.isScoring
              ? LocaleKey.scoringDrawing.tr
              : LocaleKey.scoreDrawing.tr,
          icon: Icons.auto_awesome_rounded,
          enabled: !state.isScoring,
          onTap: _bloc.scoreRound,
        ),
      ],
    ];
  }

  String _footerText(DrawingBoardState state) {
    if (state.canDraw) return LocaleKey.slowStrokeHint.tr;
    if (state.isScoring) return LocaleKey.scoringDrawing.tr;
    if (state.isVersus && state.scores.isNotEmpty) {
      return LocaleKey.scoreReady.tr;
    }
    if (state.isVersus && state.hasCurrentPlayerSubmitted) {
      if (state.hasBothVersusSubmissions) return LocaleKey.waitingForScore.tr;
      return LocaleKey.waitingForOpponentSubmit.tr;
    }
    if (state.teamScore != null) return LocaleKey.scoreReady.tr;
    if (state.teamSubmission != null) return LocaleKey.submissionSaved.tr;
    if (state.isHost) return LocaleKey.canvasLocked.tr;
    return LocaleKey.waitingForHostSubmit.tr;
  }

  Future<void> _exportAndSubmitCanvas() async {
    final renderObject = _canvasBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      showErrorToast(LocaleKey.unknownError.tr);
      return;
    }

    final size = renderObject.size;
    final pixelRatio = max(1.0, 1024 / size.width);
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final width = image.width;
    final height = image.height;
    image.dispose();

    if (byteData == null) {
      showErrorToast(LocaleKey.unknownError.tr);
      return;
    }

    if (_bloc.state.isVersus) {
      await _bloc.submitCurrentPlayerCanvas(
        pngBytes: byteData.buffer.asUint8List(),
        width: width,
        height: height,
      );
      return;
    }

    await _bloc.submitTeamCanvas(
      pngBytes: byteData.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }
}

class _RoundStatusBar extends StatelessWidget {
  const _RoundStatusBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      color: const Color(0xFFE8F5FF),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: PlayfulColors.blue,
          ),
          8.width,
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium(
                color: PlayfulColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.title, required this.score});

  final String title;
  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.82),
        borderRadius: 18.borderRadiusAll,
      ),
      child: Padding(
        padding: 18.paddingAll,
        child: Column(
          children: [
            Text(
              title,
              style: AppStyles.bodyMedium(
                color: AppColors.color667394,
                fontWeight: FontWeight.w700,
              ),
            ),
            8.height,
            Text(
              '$score',
              style: AppStyles.h1(
                color: const Color(0xFF08BCE8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersusScoreCard extends StatelessWidget {
  const _VersusScoreCard({required this.state});

  final DrawingBoardState state;

  @override
  Widget build(BuildContext context) {
    final playerScore = state.currentPlayerScore;
    final opponentScore = state.opponentScore;
    final isWinner = playerScore?.winner ?? false;
    final title = state.isTie
        ? LocaleKey.tie.tr
        : isWinner
        ? LocaleKey.youWin.tr
        : LocaleKey.youLose.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.82),
        borderRadius: 18.borderRadiusAll,
      ),
      child: Padding(
        padding: 18.paddingAll,
        child: Column(
          children: [
            Text(
              title,
              style: AppStyles.bodyLarge(
                color: AppColors.color333333,
                fontWeight: FontWeight.w700,
              ),
            ),
            12.height,
            Row(
              children: [
                Expanded(
                  child: _ScoreValue(
                    label: LocaleKey.yourScore.tr,
                    score: playerScore?.similarityScore,
                  ),
                ),
                12.width,
                Expanded(
                  child: _ScoreValue(
                    label: LocaleKey.opponentScore.tr,
                    score: opponentScore?.similarityScore,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreValue extends StatelessWidget {
  const _ScoreValue({required this.label, required this.score});

  final String label;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: 14.borderRadiusAll,
      ),
      child: Padding(
        padding: 12.paddingAll,
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppStyles.caption(
                color: AppColors.color667394,
                fontWeight: FontWeight.w700,
              ),
            ),
            6.height,
            Text(
              score?.toString() ?? '-',
              style: AppStyles.h2(
                color: const Color(0xFF08BCE8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({
    required this.targetTitle,
    required this.targetUrl,
    required this.remainingMs,
    required this.isRealtimeConnected,
    required this.colorHex,
  });

  final String targetTitle;
  final String? targetUrl;
  final int remainingMs;
  final bool isRealtimeConnected;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (remainingMs / 1000).ceil();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: 20.borderRadiusAll,
        boxShadow: playfulShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: 14.borderRadiusAll,
              child: SizedBox(
                width: 58,
                height: 58,
                child: ColoredBox(
                  color: const Color(0xFFF9FCFF),
                  child: targetUrl == null
                      ? const SizedBox.shrink()
                      : Image.network(targetUrl!, fit: BoxFit.contain),
                ),
              ),
            ),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.h5(
                      color: PlayfulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  3.height,
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: PlayfulColors.blue,
                        size: 16,
                      ),
                      4.width,
                      Expanded(
                        child: Text(
                          '${LocaleKey.timeRemaining.tr}: ${_timeLabel(remainingSeconds)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodyMedium(
                            color: PlayfulColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  5.height,
                  ClipRRect(
                    borderRadius: 99.borderRadiusAll,
                    child: LinearProgressIndicator(
                      value: (remainingMs / 60000).clamp(0, 1).toDouble(),
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE3EAF5),
                      color: PlayfulColors.blue,
                    ),
                  ),
                  5.height,
                  Row(
                    children: [
                      Icon(
                        isRealtimeConnected
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        size: 15,
                        color: isRealtimeConnected
                            ? AppColors.success
                            : AppColors.colorB8BCC6,
                      ),
                      4.width,
                      Text(
                        isRealtimeConnected
                            ? LocaleKey.online.tr
                            : LocaleKey.offline.tr,
                        style: AppStyles.bodySmall(
                          color: isRealtimeConnected
                              ? AppColors.success
                              : AppColors.colorB8BCC6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      12.width,
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: _colorFromHex(colorHex),
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 12, height: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  Color _colorFromHex(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}
