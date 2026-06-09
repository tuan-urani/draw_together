import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/game_submission.dart';
import 'package:draw_together/src/core/repository/history_repository.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final entry = args is Map ? args['entry'] as GameHistoryEntry? : null;
    if (entry == null) {
      return PlayfulScaffold(child: Center(child: Text(LocaleKey.history.tr)));
    }

    return PlayfulScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          PlayfulHeader(
            title: LocaleKey.historyDetail.tr,
            subtitle: DateFormat(
              'MMM d, yyyy - HH:mm',
            ).format(entry.round.createdAt.toLocal()),
            leading: PlayfulIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: Get.back<void>,
            ),
            compact: true,
          ),
          10.height,
          _TargetSummary(entry: entry),
          14.height,
          if (entry.room.mode == RoomMode.coop)
            _CoopHistoryDetail(entry: entry)
          else
            _SoloHistoryDetail(entry: entry),
        ],
      ),
    );
  }
}

class _TargetSummary extends StatelessWidget {
  const _TargetSummary({required this.entry});

  final GameHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKey.target.tr.toUpperCase(),
                  style: AppStyles.caption(
                    color: PlayfulColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                6.height,
                Text(
                  entry.target.title,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                8.height,
                _ModeChip(
                  label: entry.room.mode == RoomMode.coop
                      ? LocaleKey.coopModeTitle.tr
                      : LocaleKey.soloModeTitle.tr,
                  color: entry.room.mode == RoomMode.coop
                      ? PlayfulColors.blue
                      : PlayfulColors.purpleDark,
                ),
              ],
            ),
          ),
          14.width,
          ClipRRect(
            borderRadius: 16.borderRadiusAll,
            child: SizedBox(
              width: 120,
              height: 96,
              child: ColoredBox(
                color: const Color(0xFFF8FBFF),
                child: Image.network(entry.targetUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoopHistoryDetail extends StatelessWidget {
  const _CoopHistoryDetail({required this.entry});

  final GameHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final score = entry.teamScore;
    final submission = entry.teamSubmission;

    return Column(
      children: [
        _ScoreHeroCard(
          title: LocaleKey.teamScore.tr,
          score: (score?.teamScore ?? score?.similarityScore) ?? 0,
          color: PlayfulColors.blue,
          icon: Icons.groups_rounded,
          reasons: score?.rationale ?? const <String>[],
        ),
        14.height,
        _SubmissionImageCard(
          title: LocaleKey.yourDrawing.tr,
          submission: submission,
        ),
      ],
    );
  }
}

class _SoloHistoryDetail extends StatelessWidget {
  const _SoloHistoryDetail({required this.entry});

  final GameHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final playerScore = entry.currentUserScore;
    final opponentScore = entry.opponentScore;
    final isTie =
        entry.isVersus &&
        entry.scores.length >= 2 &&
        !entry.scores.any((score) => score.winner);
    final isWinner = playerScore?.winner ?? false;

    return Column(
      children: [
        PlayfulCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            children: [
              Text(
                isTie
                    ? LocaleKey.tie.tr.toUpperCase()
                    : isWinner
                    ? LocaleKey.youWin.tr.toUpperCase()
                    : LocaleKey.youLose.tr.toUpperCase(),
                style: AppStyles.h2(
                  color: isTie
                      ? PlayfulColors.blue
                      : isWinner
                      ? PlayfulColors.green
                      : AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
              18.height,
              Row(
                children: [
                  Expanded(
                    child: _MiniScoreCard(
                      label: LocaleKey.yourScore.tr,
                      score: playerScore?.similarityScore ?? 0,
                      color: PlayfulColors.blue,
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: _MiniScoreCard(
                      label: LocaleKey.opponentScore.tr,
                      score: opponentScore?.similarityScore ?? 0,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              16.height,
              const Divider(height: 1, color: PlayfulColors.settingsDivider),
              _WhyScoreRow(reasons: playerScore?.rationale ?? const <String>[]),
            ],
          ),
        ),
        14.height,
        Row(
          children: [
            Expanded(
              child: _SubmissionImageCard(
                title: LocaleKey.yourDrawing.tr,
                submission: entry.currentUserSubmission,
              ),
            ),
            12.width,
            Expanded(
              child: _SubmissionImageCard(
                title: LocaleKey.opponentDrawing.tr,
                submission: entry.opponentSubmission,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreHeroCard extends StatelessWidget {
  const _ScoreHeroCard({
    required this.title,
    required this.score,
    required this.color,
    required this.icon,
    required this.reasons,
  });

  final String title;
  final int score;
  final Color color;
  final IconData icon;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                _ScoreIconTile(
                  icon: icon,
                  color: color,
                  background: color.withValues(alpha: 0.12),
                ),
                14.width,
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyLarge(
                      color: PlayfulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                12.width,
                Text(
                  '$score',
                  style: AppStyles.h4(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' / 100',
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: PlayfulColors.settingsDivider),
          _WhyScoreRow(reasons: reasons),
        ],
      ),
    );
  }
}

class _MiniScoreCard extends StatelessWidget {
  const _MiniScoreCard({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: 18.borderRadiusAll,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: 14.paddingAll,
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppStyles.caption(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            8.height,
            Text(
              '$score',
              style: AppStyles.h2(color: color, fontWeight: FontWeight.w900),
            ),
            Text(
              '/ 100',
              style: AppStyles.bodySmall(color: PlayfulColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionImageCard extends StatefulWidget {
  const _SubmissionImageCard({required this.title, required this.submission});

  final String title;
  final GameSubmission? submission;

  @override
  State<_SubmissionImageCard> createState() => _SubmissionImageCardState();
}

class _SubmissionImageCardState extends State<_SubmissionImageCard> {
  String? _url;

  @override
  void initState() {
    super.initState();
    final submission = widget.submission;
    if (submission != null) {
      Get.find<HistoryRepository>().signedSubmissionUrl(submission).then((url) {
        if (mounted) setState(() => _url = url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium(
              color: PlayfulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          10.height,
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: 16.borderRadiusAll,
              ),
              child: _url == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.network(_url!, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyScoreRow extends StatelessWidget {
  const _WhyScoreRow({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: AppAudioTap.wrap(() => _showScoreReasonDialog(context, reasons)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          children: [
            const _ScoreIconTile(
              icon: Icons.auto_awesome_rounded,
              color: PlayfulColors.blue,
              background: Color(0xFFEAF2FF),
            ),
            14.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKey.whyThisScore.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMedium(
                      color: PlayfulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  3.height,
                  Text(
                    LocaleKey.aiAnalysisFeedback.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySmall(
                      color: PlayfulColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            10.width,
            const Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: PlayfulColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreIconTile extends StatelessWidget {
  const _ScoreIconTile({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: 14.borderRadiusAll,
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

Future<void> _showScoreReasonDialog(
  BuildContext context,
  List<String> reasons,
) {
  return Get.dialog<void>(
    AppPlayfulDialog(
      title: LocaleKey.scoreReason.tr,
      subtitle: LocaleKey.aiAnalysisFeedback.tr,
      tone: AppPlayfulDialogTone.info,
      maxWidth: 430,
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.42,
          ),
          child: SingleChildScrollView(child: _ReasonBullets(reasons: reasons)),
        ),
      ),
      actions: [
        AppPlayfulDialogButton(
          label: LocaleKey.ok.tr,
          onTap: () => Get.back<void>(),
        ),
      ],
    ),
  );
}

class _ReasonBullets extends StatelessWidget {
  const _ReasonBullets({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) {
      return Text(
        LocaleKey.scoreReady.tr,
        style: AppStyles.bodyMedium(
          color: PlayfulColors.muted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reasons
          .map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u2022',
                    style: AppStyles.bodyMedium(
                      color: PlayfulColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Text(
                      reason,
                      style: AppStyles.bodyMedium(
                        color: PlayfulColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: 99.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: AppStyles.caption(color: color, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
