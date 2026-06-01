import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/joinable_room.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/room_browser/bloc/room_browser_bloc.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
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
                const _RoomBrowserHeader(),
                22.height,
                _CreateRoomCard(
                  modeLabel: _modeLabel(state.mode),
                  isLoading: state.isCreatingRoom,
                  onTap: _bloc.createRoom,
                ),
                28.height,
                _RoomListSection(state: state, onJoin: _bloc.joinRoom),
              ],
            ),
          );
        },
      ),
    );
  }

  String _modeLabel(RoomMode mode) {
    switch (mode) {
      case RoomMode.coop:
        return 'Co-op';
      case RoomMode.versus:
        return 'Solo';
    }
  }
}

class _RoomBrowserHeader extends StatelessWidget {
  const _RoomBrowserHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PlayfulIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: Get.back<void>,
          size: 52,
        ),
        20.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKey.roomLobby.tr,
                textAlign: TextAlign.left,
                style: AppStyles.h3(
                  color: PlayfulColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              4.height,
              Text(
                'Invite friends with room code',
                textAlign: TextAlign.left,
                style: AppStyles.bodyMedium(
                  color: PlayfulColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateRoomCard extends StatelessWidget {
  const _CreateRoomCard({
    required this.modeLabel,
    required this.isLoading,
    required this.onTap,
  });

  final String modeLabel;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PlayfulCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Row(
        children: [
          const PlayfulIconTile(
            icon: Icons.add_rounded,
            size: 58,
            background: Color(0xFFE9F5FF),
            color: PlayfulColors.blue,
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKey.createRoom.tr,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                4.height,
                Text(
                  '${LocaleKey.startNewSession.tr}\n$modeLabel',
                  style: AppStyles.bodyMedium(
                    color: PlayfulColors.muted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.chevron_right_rounded,
                color: isLoading ? PlayfulColors.muted : PlayfulColors.blue,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomListSection extends StatelessWidget {
  const _RoomListSection({required this.state, required this.onJoin});

  final RoomBrowserState state;
  final ValueChanged<String> onJoin;

  @override
  Widget build(BuildContext context) {
    if (state.pageState == PageState.loading && state.rooms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 56),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.rooms.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const _OpenRoomsTitle(), 12.height, const _EmptyRoomsCard()],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OpenRoomsTitle(),
        12.height,
        for (final room in state.rooms) ...[
          _JoinableRoomCard(
            room: room,
            joining: state.joiningRoomId == room.room.id,
            actionsDisabled: state.isJoiningRoom || state.isCreatingRoom,
            onJoin: () => onJoin(room.room.id),
          ),
          12.height,
        ],
      ],
    );
  }
}

class _OpenRoomsTitle extends StatelessWidget {
  const _OpenRoomsTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKey.openRooms.tr.toUpperCase(),
      style: AppStyles.bodySmall(
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
    return PlayfulCard(
      padding: 24.paddingAll,
      child: Column(
        children: [
          const PlayfulIconTile(
            icon: Icons.search_off_rounded,
            size: 74,
            background: Color(0xFFFFF2D8),
            color: PlayfulColors.yellow,
          ),
          16.height,
          Text(
            LocaleKey.noRoomsAvailable.tr,
            textAlign: TextAlign.center,
            style: AppStyles.h4(
              color: PlayfulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          8.height,
          Text(
            LocaleKey.noRoomsAvailableHint.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodyLarge(color: PlayfulColors.muted),
          ),
        ],
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
    final minutesLeft = room.room.expiresAt
        .difference(DateTime.now().toUtc())
        .inMinutes
        .clamp(0, 60);
    final countdownLabel = minutesLeft <= 0
        ? '< 1m left'
        : '${minutesLeft}m left';

    return PlayfulCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PlayfulIconTile(
                icon: Icons.group_rounded,
                size: 42,
                background: Color(0xFFE9F0FF),
                color: PlayfulColors.blue,
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.room.code,
                      style: AppStyles.h5(
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
                            color: const Color(0xFFFF9F1C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          18.height,
          const Divider(height: 1, color: Color(0xFFE4EBF5)),
          14.height,
          GestureDetector(
            onTap: actionsDisabled ? null : onJoin,
            child: Row(
              children: [
                Text(
                  joining ? LocaleKey.saving.tr : LocaleKey.enterRoom.tr,
                  style: AppStyles.bodyMedium(
                    color: actionsDisabled
                        ? PlayfulColors.muted
                        : PlayfulColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: actionsDisabled
                      ? PlayfulColors.muted
                      : PlayfulColors.blue,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
