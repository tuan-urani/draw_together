import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/joinable_room.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/room_browser/bloc/room_browser_bloc.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class RoomBrowserPage extends StatefulWidget {
  const RoomBrowserPage({super.key});

  @override
  State<RoomBrowserPage> createState() => _RoomBrowserPageState();
}

class _RoomBrowserPageState extends State<RoomBrowserPage> {
  late final RoomBrowserBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<RoomBrowserBloc>();
    _bloc.loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulScaffold(
      child: BlocConsumer<RoomBrowserBloc, RoomBrowserState>(
        bloc: _bloc,
        listenWhen: (previous, current) {
          return previous.errorMessage != current.errorMessage ||
              previous.activeRoom?.id != current.activeRoom?.id;
        },
        listener: (context, state) {
          final errorMessage = state.errorMessage;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            showErrorToast(errorMessage);
          }

          final activeRoom = state.activeRoom;
          if (activeRoom != null) {
            final roomId = activeRoom.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _bloc.clearActiveRoom();
              Get.toNamed(AppPages.roomLobby, arguments: {'roomId': roomId});
            });
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _bloc.loadRooms,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: [
                _RoomBrowserHeader(
                  isLoading: state.isCreatingRoom,
                  onTap: _showCreateRoomSheet,
                ),
                28.height,
                _RoomListSection(
                  state: state,
                  onModeSelected: _bloc.selectMode,
                  onJoin: _bloc.joinRoom,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateRoomSheet() async {
    final mode = await showModalBottomSheet<RoomMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          _CreateRoomModeSheet(initialMode: _bloc.state.selectedMode),
    );

    if (!mounted || mode == null) return;
    await _bloc.createRoom(mode);
  }
}

class _RoomBrowserHeader extends StatelessWidget {
  const _RoomBrowserHeader({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PlayfulIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: Get.back<void>,
            ),
          ],
        ),
        12.height,
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKey.roomLobby.tr,
                textAlign: TextAlign.left,
                style: AppStyles.h4(
                  color: PlayfulColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            12.width,
            _HeaderCreateButton(isLoading: isLoading, onTap: onTap),
          ],
        ),
        4.height,
        Text(
          LocaleKey.inviteFriendsWithRoomCode.tr,
          textAlign: TextAlign.left,
          style: AppStyles.bodyMedium(
            color: PlayfulColors.muted,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _HeaderCreateButton extends StatelessWidget {
  const _HeaderCreateButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.94),
          borderRadius: 20.borderRadiusAll,
          boxShadow: playfulShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                color: isLoading ? PlayfulColors.muted : PlayfulColors.blue,
                size: 18,
              ),
              6.width,
              Text(
                LocaleKey.create.tr,
                style: AppStyles.bodyMedium(
                  color: isLoading ? PlayfulColors.muted : PlayfulColors.blue,
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

class _RoomListSection extends StatelessWidget {
  const _RoomListSection({
    required this.state,
    required this.onModeSelected,
    required this.onJoin,
  });

  final RoomBrowserState state;
  final ValueChanged<RoomMode> onModeSelected;
  final ValueChanged<String> onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RoomModeTabs(
          selectedMode: state.selectedMode,
          onSelected: onModeSelected,
        ),
        24.height,
        const _AvailableRoomsTitle(),
        16.height,
        if (state.pageState == PageState.loading && state.rooms.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 48),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.rooms.isEmpty)
          const _EmptyRoomsCard()
        else
          PlayfulCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            radius: 18,
            child: Column(
              children: [
                for (var index = 0; index < state.rooms.length; index++) ...[
                  _JoinableRoomCard(
                    room: state.rooms[index],
                    joining: state.joiningRoomId == state.rooms[index].room.id,
                    actionsDisabled:
                        state.isJoiningRoom || state.isCreatingRoom,
                    onJoin: () => onJoin(state.rooms[index].room.id),
                  ),
                  if (index != state.rooms.length - 1)
                    const Divider(height: 1, color: Color(0xFFE4EBF5)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RoomModeTabs extends StatelessWidget {
  const _RoomModeTabs({required this.selectedMode, required this.onSelected});

  final RoomMode selectedMode;
  final ValueChanged<RoomMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.64),
        borderRadius: 16.borderRadiusAll,
        border: Border.all(
          color: PlayfulColors.lobbyDivider.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _RoomModeTab(
                title: LocaleKey.coopRooms.tr,
                icon: Icons.group_rounded,
                selected: selectedMode == RoomMode.coop,
                color: PlayfulColors.blue,
                onTap: () => onSelected(RoomMode.coop),
              ),
            ),
            8.width,
            Expanded(
              child: _RoomModeTab(
                title: LocaleKey.soloRooms.tr,
                icon: Icons.person_rounded,
                selected: selectedMode == RoomMode.versus,
                color: PlayfulColors.lobbyPurple,
                onTap: () => onSelected(RoomMode.versus),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomModeTab extends StatelessWidget {
  const _RoomModeTab({
    required this.title,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? color : PlayfulColors.muted;

    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.white : AppColors.transparent,
          borderRadius: 14.borderRadiusAll,
          boxShadow: selected ? _softTabShadow : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: activeColor, size: 24),
              8.width,
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyMedium(
                    color: activeColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableRoomsTitle extends StatelessWidget {
  const _AvailableRoomsTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKey.availableRooms.tr.toUpperCase(),
      style: AppStyles.bodyMedium(
        color: PlayfulColors.muted,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyRoomsCard extends StatelessWidget {
  const _EmptyRoomsCard();

  @override
  Widget build(BuildContext context) {
    final emptyStateHeight = math.max(
      320.0,
      MediaQuery.sizeOf(context).height * 0.42,
    );

    return SizedBox(
      height: emptyStateHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 126,
              child: Image.asset(AppAssets.emptyRoomPng, fit: BoxFit.contain),
            ),
            2.height,
            Text(
              LocaleKey.noRoomsAvailable.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodyLarge(
                color: PlayfulColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            2.height,
            Text(
              LocaleKey.noRoomsAvailableHint.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium(
                color: PlayfulColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinableRoomCard extends StatelessWidget {
  const _JoinableRoomCard({
    required this.room,
    required this.joining,
    required this.actionsDisabled,
    required this.onJoin,
  });

  final JoinableRoom room;
  final bool joining;
  final bool actionsDisabled;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final isCoop = room.room.mode == RoomMode.coop;
    final minutesLeft = room.room.expiresAt
        .difference(DateTime.now().toUtc())
        .inMinutes
        .clamp(0, 60);
    final countdownLabel = minutesLeft <= 0
        ? '< 1m left'
        : '${minutesLeft}m left';

    return GestureDetector(
      onTap: actionsDisabled ? null : AppAudioTap.wrap(onJoin),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            PlayfulIconTile(
              icon: isCoop ? Icons.group_rounded : Icons.person_rounded,
              size: 46,
              background: isCoop
                  ? PlayfulColors.softBlue
                  : PlayfulColors.lobbySoftPurple,
              color: isCoop ? PlayfulColors.blue : PlayfulColors.lobbyPurple,
            ),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.room.code,
                    style: AppStyles.h4(
                      color: PlayfulColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  6.height,
                  Row(
                    children: [
                      const Icon(
                        Icons.group_rounded,
                        color: PlayfulColors.muted,
                        size: 15,
                      ),
                      4.width,
                      Text(
                        '${room.playerCount} / ${room.room.maxPlayers} players',
                        style: AppStyles.bodySmall(
                          color: PlayfulColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      18.width,
                      const Icon(
                        Icons.timer_outlined,
                        color: PlayfulColors.yellow,
                        size: 15,
                      ),
                      4.width,
                      Text(
                        countdownLabel,
                        style: AppStyles.bodySmall(
                          color: PlayfulColors.lobbyWarning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: actionsDisabled ? PlayfulColors.muted : PlayfulColors.blue,
              size: 34,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateRoomModeSheet extends StatefulWidget {
  const _CreateRoomModeSheet({required this.initialMode});

  final RoomMode initialMode;

  @override
  State<_CreateRoomModeSheet> createState() => _CreateRoomModeSheetState();
}

class _CreateRoomModeSheetState extends State<_CreateRoomModeSheet> {
  late RoomMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: PlayfulColors.muted.withValues(alpha: 0.24),
                borderRadius: 8.borderRadiusAll,
              ),
              child: const SizedBox(width: 28, height: 4),
            ),
            18.height,
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  LocaleKey.chooseGameMode.tr,
                  style: AppStyles.h5(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: AppAudioTap.wrap(() => Navigator.of(context).pop()),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PlayfulColors.lobbySeatInactive,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.close_rounded,
                          color: PlayfulColors.muted,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            18.height,
            Column(
              children: [
                _CreateRoomModeOption(
                  title: LocaleKey.coopMode.tr,
                  description: LocaleKey.coopModeDescription.tr,
                  imageAsset: AppAssets.coOpRoomModePng,
                  selected: _selectedMode == RoomMode.coop,
                  accentColor: PlayfulColors.blue,
                  onTap: () => setState(() => _selectedMode = RoomMode.coop),
                ),
                10.height,
                _CreateRoomModeOption(
                  title: LocaleKey.soloMode.tr,
                  description: LocaleKey.soloModeDescription.tr,
                  imageAsset: AppAssets.soloRoomModePng,
                  selected: _selectedMode == RoomMode.versus,
                  accentColor: PlayfulColors.lobbyPurple,
                  onTap: () => setState(() => _selectedMode = RoomMode.versus),
                ),
              ],
            ),
            22.height,
            GestureDetector(
              onTap: AppAudioTap.wrap(
                () => Navigator.of(context).pop(_selectedMode),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: PlayfulColors.coopCardGradient,
                  borderRadius: 14.borderRadiusAll,
                  boxShadow: [
                    BoxShadow(
                      color: PlayfulColors.blue.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      LocaleKey.createRoom.tr,
                      style: AppStyles.bodyLarge(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _CreateRoomModeOption extends StatelessWidget {
  const _CreateRoomModeOption({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final String imageAsset;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: 14.borderRadiusAll,
          border: Border.all(
            color: selected ? accentColor : PlayfulColors.lobbyDivider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? PlayfulColors.softBlue
                      : PlayfulColors.lobbySoftPurple,
                  borderRadius: 10.borderRadiusAll,
                ),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(imageAsset, fit: BoxFit.cover),
                  ),
                ),
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodyMedium(
                        color: PlayfulColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    6.height,
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodySmall(
                        color: PlayfulColors.muted,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              12.width,
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accentColor : PlayfulColors.lobbyDivider,
                    width: selected ? 3 : 2,
                  ),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: selected
                      ? Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 12, height: 12),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<BoxShadow> _softTabShadow = [
  BoxShadow(
    color: PlayfulColors.muted.withValues(alpha: 0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];
