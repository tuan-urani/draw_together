import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/history/bloc/history_bloc.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryBloc _bloc;
  RoomMode _selectedMode = RoomMode.coop;

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<HistoryBloc>()..load();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulScaffold(
      child: BlocConsumer<HistoryBloc, HistoryState>(
        bloc: _bloc,
        listener: (context, state) {
          final error = state.errorMessage;
          if (error != null && error.isNotEmpty) showErrorToast(error);
        },
        builder: (context, state) {
          return Column(
            children: [
              PlayfulHeader(
                title: LocaleKey.history.tr,
                subtitle: LocaleKey.historySubtitle.tr,
                leading: PlayfulIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: Get.back<void>,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _HistoryModeTabs(
                  selectedMode: _selectedMode,
                  onChanged: (mode) => setState(() => _selectedMode = mode),
                ),
              ),
              Expanded(child: _body(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(HistoryState state) {
    if (state.pageState == PageState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = state.entries
        .where((entry) => entry.room.mode == _selectedMode)
        .toList(growable: false);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: 24.paddingAll,
          child: PlayfulCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 56,
                  color: PlayfulColors.blue,
                ),
                14.height,
                Text(
                  LocaleKey.noHistoryYet.tr,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                6.height,
                Text(
                  LocaleKey.noHistoryHint.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium(color: PlayfulColors.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _bloc.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _HistoryItemCard(
            entry: entry,
            onTap: () {
              Get.toNamed(AppPages.historyDetail, arguments: {'entry': entry});
            },
          );
        },
        separatorBuilder: (_, _) => 14.height,
        itemCount: entries.length,
      ),
    );
  }
}

class _HistoryModeTabs extends StatelessWidget {
  const _HistoryModeTabs({required this.selectedMode, required this.onChanged});

  final RoomMode selectedMode;
  final ValueChanged<RoomMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.52),
        borderRadius: 18.borderRadiusAll,
      ),
      child: Padding(
        padding: 4.paddingAll,
        child: Row(
          children: [
            Expanded(
              child: _HistoryModeTab(
                label: LocaleKey.coopModeTitle.tr,
                icon: Icons.groups_rounded,
                color: PlayfulColors.blue,
                selected: selectedMode == RoomMode.coop,
                onTap: () => onChanged(RoomMode.coop),
              ),
            ),
            Expanded(
              child: _HistoryModeTab(
                label: LocaleKey.soloModeTitle.tr,
                icon: Icons.person_rounded,
                color: PlayfulColors.purpleDark,
                selected: selectedMode == RoomMode.versus,
                onTap: () => onChanged(RoomMode.versus),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryModeTab extends StatelessWidget {
  const _HistoryModeTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.white : AppColors.transparent,
          borderRadius: 16.borderRadiusAll,
          boxShadow: selected ? playfulShadow : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? color : PlayfulColors.muted,
              ),
              8.width,
              Text(
                label,
                style: AppStyles.bodyMedium(
                  color: selected ? color : PlayfulColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({required this.entry, required this.onTap});

  final GameHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = entry.displayScore;
    final partnerName = entry.partnerName.isEmpty
        ? LocaleKey.unknownPlayer.tr
        : entry.partnerName;
    final modeColor = entry.room.mode == RoomMode.coop
        ? PlayfulColors.blue
        : PlayfulColors.purpleDark;
    final partnerLabel =
        (entry.room.mode == RoomMode.coop
                ? LocaleKey.historyCoopWith
                : LocaleKey.historySoloWith)
            .trParams({'name': partnerName});

    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: PlayfulCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: 18.borderRadiusAll,
              child: SizedBox(
                width: 82,
                height: 82,
                child: ColoredBox(
                  color: const Color(0xFFF8FBFF),
                  child: Image.network(entry.targetUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            14.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ModeChip(
                        label: entry.room.mode == RoomMode.coop
                            ? LocaleKey.coopModeTitle.tr
                            : LocaleKey.soloModeTitle.tr,
                        color: modeColor,
                      ),
                      8.width,
                      Text(
                        _dateLabel(entry.round.createdAt),
                        style: AppStyles.bodySmall(
                          color: PlayfulColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  8.height,
                  Text(
                    entry.target.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.h4(
                      color: PlayfulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  6.height,
                  Text(
                    partnerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodySmall(
                      color: PlayfulColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  6.height,
                  Text(
                    '${LocaleKey.score.tr}: ${score ?? '-'} / 100',
                    style: AppStyles.bodyLarge(
                      color: PlayfulColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: PlayfulColors.blue,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date.toLocal());
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
