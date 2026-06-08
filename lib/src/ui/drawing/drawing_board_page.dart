import 'dart:async';
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
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_pages.dart';
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
  Timer? _autoSubmitTimer;
  String? _scheduledAutoSubmitRoundId;
  bool _handledMatchEnd = false;
  bool _isLeavingMatch = false;

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
    _autoSubmitTimer?.cancel();
    _bloc.stopRoundTimer();
    _bloc.disconnectRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: PlayfulScaffold(
        child: BlocConsumer<DrawingBoardBloc, DrawingBoardState>(
          bloc: _bloc,
          listener: (context, state) {
            final errorMessage = state.errorMessage;
            if (errorMessage != null && errorMessage.isNotEmpty) {
              showErrorToast(errorMessage);
            }

            final matchEndMessage = state.matchEndMessage;
            if (!_isLeavingMatch &&
                !_handledMatchEnd &&
                matchEndMessage != null &&
                matchEndMessage.isNotEmpty) {
              _handledMatchEnd = true;
              _autoSubmitTimer?.cancel();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _showMatchEndedDialog(state);
              });
            }

            _scheduleAutoSubmit(state);
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
              state: state,
              targetTitle: state.target?.title ?? round.targetImageId,
              targetUrl: state.targetUrl,
              remainingMs: state.remainingMs,
              colorHex: state.currentColorHex,
              onViewReason: () => _showScoreReasonDialog(state),
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
              lockedOverlay: state.matchEndMessage == null
                  ? _ResultReviewPanel(
                      isVersus: state.isVersus,
                      score: state.isVersus
                          ? state.currentPlayerScore?.similarityScore
                          : state.teamScore?.teamScore ??
                                state.teamScore?.similarityScore,
                      opponentScore: state.opponentScore?.similarityScore,
                      isWinner: state.currentPlayerScore?.winner ?? false,
                      isTie: state.isTie,
                      onViewReason: () => _showScoreReasonDialog(state),
                    )
                  : null,
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
                        onTap: _handleBack,
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
                    Expanded(child: board),
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
                    onTap: _handleBack,
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
                if (state.matchEndMessage != null) ...[
                  10.height,
                  _RoundStatusBar(text: _footerText(state)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _footerText(DrawingBoardState state) {
    if (state.canDraw) return LocaleKey.slowStrokeHint.tr;
    if (state.matchEndMessage != null) return LocaleKey.opponentDisconnected.tr;
    if (state.isSubmitting) return LocaleKey.submittingDrawing.tr;
    if (state.canSubmitTeamCanvas || state.canSubmitPlayerCanvas) {
      return LocaleKey.autoSubmittingDrawing.tr;
    }
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

  void _scheduleAutoSubmit(DrawingBoardState state) {
    final roundId = state.round?.id;
    final canAutoSubmit =
        state.canSubmitTeamCanvas || state.canSubmitPlayerCanvas;
    if (roundId == null || !canAutoSubmit || state.matchEndMessage != null) {
      return;
    }

    if (_scheduledAutoSubmitRoundId == roundId) return;
    _scheduledAutoSubmitRoundId = roundId;
    _autoSubmitTimer?.cancel();
    _autoSubmitTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final currentState = _bloc.state;
      if (!currentState.canSubmitTeamCanvas &&
          !currentState.canSubmitPlayerCanvas) {
        return;
      }
      await _exportAndSubmitCanvas();
    });
  }

  Future<void> _showMatchEndedDialog(DrawingBoardState state) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(LocaleKey.matchEnded.tr),
        content: Text(LocaleKey.opponentDisconnected.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text(LocaleKey.ok.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (!mounted) return;
    _goToRoomBrowser(state.room?.mode);
  }

  Future<void> _showScoreReasonDialog(DrawingBoardState state) async {
    final score = state.displayScore;
    final submission = state.displaySubmission;
    if (score == null || submission == null) return;

    final submissionUrl = await _bloc.signedSubmissionUrlFor(submission);
    if (!mounted) return;

    await Get.dialog<void>(
      AlertDialog(
        title: Text(LocaleKey.scoreReason.tr),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ReasonImageCard(
                      title: LocaleKey.target.tr,
                      imageUrl: state.targetUrl,
                    ),
                  ),
                  10.width,
                  Expanded(
                    child: _ReasonImageCard(
                      title: LocaleKey.yourDrawing.tr,
                      imageUrl: submissionUrl,
                    ),
                  ),
                ],
              ),
              16.height,
              Text(
                score.rationale?.trim().isNotEmpty == true
                    ? score.rationale!.trim()
                    : LocaleKey.scoreReady.tr,
                style: AppStyles.bodyMedium(
                  color: PlayfulColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text(LocaleKey.ok.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBack() async {
    if (_isLeavingMatch) return;
    _isLeavingMatch = true;
    _autoSubmitTimer?.cancel();

    final state = _bloc.state;
    final mode = state.room?.mode;
    if (state.canDraw) {
      await _bloc.endMatch(
        message: 'A player left the match.',
        broadcast: true,
      );
    }

    if (!mounted) return;
    _goToRoomBrowser(mode);
  }

  void _goToRoomBrowser(Object? mode) {
    Get.offNamedUntil(
      AppPages.roomBrowser,
      (route) =>
          route.settings.name == AppPages.home ||
          route.settings.name == AppPages.main,
      arguments: {'mode': mode},
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

class _ResultReviewPanel extends StatelessWidget {
  const _ResultReviewPanel({
    required this.isVersus,
    required this.score,
    required this.opponentScore,
    required this.isWinner,
    required this.isTie,
    required this.onViewReason,
  });

  final bool isVersus;
  final int? score;
  final int? opponentScore;
  final bool isWinner;
  final bool isTie;
  final VoidCallback onViewReason;

  @override
  Widget build(BuildContext context) {
    final isReady = score != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.transparent,
        borderRadius: 22.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          mainAxisAlignment: isReady
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (!isReady) ...[
              10.height,
              Image.asset(
                AppAssets.aiBotWaitingGif,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: 18.borderRadiusAll,
                  boxShadow: [
                    BoxShadow(
                      color: PlayfulColors.ink.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: PlayfulColors.blue,
                            size: 22,
                          ),
                          8.width,
                          Text(
                            LocaleKey.aiReviewingArtwork.tr,
                            textAlign: TextAlign.center,
                            style: AppStyles.h4(
                              color: PlayfulColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          8.width,
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: PlayfulColors.blue,
                            size: 22,
                          ),
                        ],
                      ),
                      6.height,
                      Text(
                        LocaleKey.comparingShapes.tr,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium(
                          color: PlayfulColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 16.height,
              // Image.asset(
              //   AppAssets.resultLoadingGif,
              //   width: 120,
              //   height: 38,
              //   fit: BoxFit.contain,
              // ),
            ] else ...[
              if (isVersus)
                _VersusScorePanel(
                  score: score ?? 0,
                  opponentScore: opponentScore ?? 0,
                  isWinner: isWinner,
                  isTie: isTie,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: 28.borderRadiusAll,
                    boxShadow: [
                      BoxShadow(
                        color: PlayfulColors.ink.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    child: Column(
                      children: [
                        Image.asset(
                          AppAssets.starScorePng,
                          width: 62,
                          height: 62,
                          fit: BoxFit.contain,
                        ),
                        8.height,
                        Text(
                          LocaleKey.scoreReady.tr,
                          textAlign: TextAlign.center,
                          style: AppStyles.h2(
                            color: PlayfulColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        10.height,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${score! * 10}',
                              style: AppStyles.h1(
                                color: const Color(0xFF58D96C),
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            8.width,
                            Text(
                              '/ 1000',
                              style: AppStyles.h3(
                                color: const Color(0xFFA8B0C2),
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              16.height,
              InkWell(
                borderRadius: 999.borderRadiusAll,
                onTap: onViewReason,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.96),
                    borderRadius: 999.borderRadiusAll,
                    boxShadow: [
                      BoxShadow(
                        color: PlayfulColors.ink.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: PlayfulColors.blue,
                          size: 24,
                        ),
                        12.width,
                        Text(
                          LocaleKey.tapToSeeWhy.tr,
                          style: AppStyles.h4(
                            color: PlayfulColors.blue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        12.width,
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: PlayfulColors.blue,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersusScorePanel extends StatelessWidget {
  const _VersusScorePanel({
    required this.score,
    required this.opponentScore,
    required this.isWinner,
    required this.isTie,
  });

  final int score;
  final int opponentScore;
  final bool isWinner;
  final bool isTie;

  @override
  Widget build(BuildContext context) {
    final resultTitle = isTie
        ? LocaleKey.tie.tr.toUpperCase()
        : isWinner
        ? LocaleKey.youWin.tr.toUpperCase()
        : LocaleKey.youLose.tr.toUpperCase();
    final resultSubtitle = isTie
        ? LocaleKey.bothDrawingsAreClose.tr
        : isWinner
        ? LocaleKey.betterThanOpponent.tr
        : LocaleKey.tryAgainNextRound.tr;
    final resultColor = isTie
        ? PlayfulColors.blue
        : isWinner
        ? const Color(0xFF35C759)
        : const Color(0xFFFF4D4F);
    final diff = (score - opponentScore).abs() * 10;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: 28.borderRadiusAll,
        boxShadow: [
          BoxShadow(
            color: PlayfulColors.ink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            Image.asset(
              AppAssets.starScorePng,
              width: 54,
              height: 54,
              fit: BoxFit.contain,
            ),
            8.height,
            Text(
              resultTitle,
              textAlign: TextAlign.center,
              style: AppStyles.h2(
                color: resultColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            4.height,
            Text(
              resultSubtitle,
              textAlign: TextAlign.center,
              style: AppStyles.bodySmall(
                color: PlayfulColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            14.height,
            Row(
              children: [
                Expanded(
                  child: _VersusMiniScoreCard(
                    label: 'YOU',
                    score: score,
                    scoreColor: const Color(0xFF35C759),
                    background: const Color(0xFFEFFAF1),
                    border: const Color(0xFFD7F2DE),
                  ),
                ),
                10.width,
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: PlayfulColors.ink.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: PlayfulColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                10.width,
                Expanded(
                  child: _VersusMiniScoreCard(
                    label: 'OPPONENT',
                    score: opponentScore,
                    scoreColor: const Color(0xFFFF4D4F),
                    background: const Color(0xFFFFF1F1),
                    border: const Color(0xFFF7D7D7),
                  ),
                ),
              ],
            ),
            12.height,
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEFFAF1),
                borderRadius: 999.borderRadiusAll,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  isTie ? 'Tie' : '+$diff points',
                  style: AppStyles.bodyMedium(
                    color: const Color(0xFF35C759),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersusMiniScoreCard extends StatelessWidget {
  const _VersusMiniScoreCard({
    required this.label,
    required this.score,
    required this.scoreColor,
    required this.background,
    required this.border,
  });

  final String label;
  final int score;
  final Color scoreColor;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: 18.borderRadiusAll,
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Text(
              label,
              style: AppStyles.caption(
                color: scoreColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            8.height,
            Text(
              '$score',
              style: AppStyles.h1(
                color: scoreColor,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            4.height,
            Text(
              '/ 1000',
              style: AppStyles.bodySmall(
                color: PlayfulColors.muted,
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
    required this.state,
    required this.targetTitle,
    required this.targetUrl,
    required this.remainingMs,
    required this.colorHex,
    required this.onViewReason,
  });

  final DrawingBoardState state;
  final String targetTitle;
  final String? targetUrl;
  final int remainingMs;
  final String colorHex;
  final VoidCallback onViewReason;

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (remainingMs / 1000).ceil();
    final displayScore = state.displayScore;
    final isResultMode = state.isWaitingForScore || displayScore != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: 20.borderRadiusAll,
        boxShadow: playfulShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: SizedBox(
          height: 140,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = 12.0;
              final columnWidth = (constraints.maxWidth - gap) / 2;

              return Row(
                children: [
                  SizedBox(
                    width: columnWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          spacing: 4,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: 99.borderRadiusAll,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  (isResultMode
                                          ? LocaleKey.yourResult.tr
                                          : LocaleKey.yourTarget.tr)
                                      .toUpperCase(),
                                  style: AppStyles.caption(
                                    color: PlayfulColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              targetTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.h4(
                                color: PlayfulColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isResultMode)
                              _ScoreSummaryRow(
                                score:
                                    displayScore?.teamScore ??
                                    displayScore?.similarityScore,
                                isCalculating: displayScore == null,
                                onViewReason: onViewReason,
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: PlayfulColors.blue,
                                    size: 22,
                                  ),
                                  8.width,
                                  Text(
                                    _timeLabel(remainingSeconds),
                                    style: AppStyles.h3(
                                      color: PlayfulColors.blue,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            Text(
                              LocaleKey.yourColor.tr,
                              style: AppStyles.bodySmall(
                                color: PlayfulColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: _colorFromHex(colorHex),
                                borderRadius: 99.borderRadiusAll,
                                boxShadow: [
                                  BoxShadow(
                                    color: _colorFromHex(
                                      colorHex,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const SizedBox(width: 82, height: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: gap),
                  SizedBox(
                    width: columnWidth,
                    height: constraints.maxHeight,
                    child: targetUrl == null
                        ? Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 58,
                              color: PlayfulColors.muted.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          )
                        : Image.network(
                            targetUrl!,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                  ),
                ],
              );
            },
          ),
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

class _ScoreSummaryRow extends StatelessWidget {
  const _ScoreSummaryRow({
    required this.score,
    required this.isCalculating,
    required this.onViewReason,
  });

  final int? score;
  final bool isCalculating;
  final VoidCallback onViewReason;

  @override
  Widget build(BuildContext context) {
    if (isCalculating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${LocaleKey.score.tr}:',
            style: AppStyles.bodySmall(
              color: PlayfulColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          2.height,
          Text(
            LocaleKey.calculatingScore.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.bodyMedium(
              color: PlayfulColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${LocaleKey.score.tr}: ${score ?? '-'}',
          style: AppStyles.h4(
            color: PlayfulColors.blue,
            fontWeight: FontWeight.w900,
          ),
        ),
        8.width,
        InkWell(
          borderRadius: 99.borderRadiusAll,
          onTap: onViewReason,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: 99.borderRadiusAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: PlayfulColors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonImageCard extends StatelessWidget {
  const _ReasonImageCard({required this.title, required this.imageUrl});

  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: 14.borderRadiusAll,
        border: Border.all(color: const Color(0xFFE4ECF8)),
      ),
      child: Padding(
        padding: 8.paddingAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.caption(
                color: PlayfulColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            8.height,
            AspectRatio(
              aspectRatio: 1,
              child: imageUrl == null
                  ? Icon(
                      Icons.image_outlined,
                      color: PlayfulColors.muted.withValues(alpha: 0.45),
                    )
                  : Image.network(imageUrl!, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
