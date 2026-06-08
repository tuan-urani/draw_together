import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/room_presence.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/room/bloc/room_lobby_bloc.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class RoomLobbyPage extends StatefulWidget {
  const RoomLobbyPage({super.key});

  @override
  State<RoomLobbyPage> createState() => _RoomLobbyPageState();
}

class _RoomLobbyPageState extends State<RoomLobbyPage> {
  late final RoomLobbyBloc _bloc;
  late final String _roomId;
  String? _enteredRoundId;
  bool _isLeavingRoom = false;
  bool _handledRoomEnd = false;

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<RoomLobbyBloc>();
    final args = Get.arguments;
    _roomId = args is Map ? args['roomId'] as String : '';
    if (_roomId.isNotEmpty) {
      _bloc.loadRoom(_roomId);
    }
  }

  @override
  void dispose() {
    _bloc.disconnectPresence();
    _bloc.stopRoundTimer();
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
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.lobbyBackgroundPng),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: BlocConsumer<RoomLobbyBloc, RoomLobbyState>(
              bloc: _bloc,
              listener: (context, state) {
                final errorMessage = state.errorMessage;
                if (errorMessage != null && errorMessage.isNotEmpty) {
                  showErrorToast(errorMessage);
                }

                final roomEndMessage = state.roomEndMessage;
                if (!_handledRoomEnd &&
                    roomEndMessage != null &&
                    roomEndMessage.isNotEmpty) {
                  _handledRoomEnd = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _showRoomEndedDialog(state.room?.mode);
                  });
                }

                final activeRound = state.activeRound;
                if (activeRound != null &&
                    state.remainingMs > 0 &&
                    _enteredRoundId != activeRound.id) {
                  _enteredRoundId = activeRound.id;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;

                    Get.toNamed(
                      AppPages.drawingBoard,
                      arguments: {'roomId': activeRound.roomId},
                    );
                  });
                }
              },
              builder: (context, state) {
                if (_roomId.isEmpty) {
                  return Center(child: Text(LocaleKey.roomNotFound.tr));
                }

                if (state.pageState == PageState.loading &&
                    state.room == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final room = state.room;
                if (room == null) {
                  return Center(
                    child: PlayfulGradientButton(
                      title: LocaleKey.retry.tr,
                      onTap: () => _bloc.loadRoom(_roomId),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _bloc.loadRoom(_roomId),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
                    children: [
                      _LobbyHeader(onBack: _handleBack),
                      12.height,
                      _RoomSummaryCard(room: room),
                      32.height,
                      _PlayersTitle(count: state.players.length),
                      16.height,
                      _PlayersCard(
                        firstPlayer: _playerAtSeat(state.players, 1),
                        firstPresence: _presenceAtSeat(state.presences, 1),
                        secondPlayer: _playerAtSeat(state.players, 2),
                        secondPresence: _presenceAtSeat(state.presences, 2),
                      ),
                      30.height,
                      if (state.activeRound != null) ...[
                        _RoundStatusCard(
                          targetTitle:
                              state.target?.title ??
                              state.activeRound!.targetImageId,
                          targetUrl: state.targetUrl,
                          remainingMs: state.remainingMs,
                          onEnter: () {
                            Get.toNamed(
                              AppPages.drawingBoard,
                              arguments: {'roomId': room.id},
                            );
                          },
                        ),
                        12.height,
                      ] else ...[
                        // _LobbyNoticeCard(
                        //   canStartRound: state.canStartRound,
                        //   isStartingRound: state.isStartingRound,
                        //   helperText: _startHelperText(state),
                        //   onStart: _bloc.startRound,
                        // ),
                        if (state.hasTwoPlayers) ...[
                          24.height,
                          if (state.isHost)
                            _LobbyPrimaryButton(
                              title: state.isStartingRound
                                  ? LocaleKey.startingRound.tr
                                  : LocaleKey.startRound.tr,
                              icon: Icons.play_arrow_rounded,
                              onTap: state.canStartRound
                                  ? _bloc.startRound
                                  : null,
                            )
                          else
                            _LobbyPrimaryButton(
                              title: state.isReady
                                  ? LocaleKey.ready.tr
                                  : LocaleKey.markReady.tr,
                              icon: Icons.send_rounded,
                              onTap: () => _bloc.setReady(!state.isReady),
                            ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  RoomPlayer? _playerAtSeat(List<RoomPlayer> players, int seat) {
    for (final player in players) {
      if (player.seat == seat) return player;
    }
    return null;
  }

  RoomPresence? _presenceAtSeat(List<RoomPresence> presences, int seat) {
    for (final presence in presences) {
      if (presence.seat == seat) return presence;
    }
    return null;
  }

  // ignore: unused_element
  String _startHelperText(RoomLobbyState state) {
    if (!state.isHost) return LocaleKey.waitingForHost.tr;
    if (!state.hasTwoPlayers) return LocaleKey.needTwoPlayers.tr;
    if (!state.allPlayersReady) return LocaleKey.waitingForReady.tr;
    return LocaleKey.readyToStart.tr;
  }

  Future<void> _handleBack() async {
    if (_isLeavingRoom) return;
    _isLeavingRoom = true;

    final mode = _bloc.state.room?.mode ?? RoomMode.coop;
    await _bloc.leaveRoomFromBack();
    if (!mounted) return;
    _goToRoomBrowser(mode);
  }

  Future<void> _showRoomEndedDialog(RoomMode? mode) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(LocaleKey.roomClosed.tr),
        content: Text(LocaleKey.hostLeftRoom.tr),
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
    _goToRoomBrowser(mode ?? RoomMode.coop);
  }

  void _goToRoomBrowser(RoomMode mode) {
    Get.offNamedUntil(
      AppPages.roomBrowser,
      (route) =>
          route.settings.name == AppPages.home ||
          route.settings.name == AppPages.main,
      arguments: {'mode': mode},
    );
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -36,
            top: -8,
            width: 144,
            height: 96,
            child: IgnorePointer(
              child: Image.asset(
                AppAssets.lobbyGameStickerPng,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          boxShadow: _lobbyShadow,
        ),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: PlayfulColors.lobbyPurple, size: 24),
        ),
      ),
    );
  }
}

class _RoomSummaryCard extends StatelessWidget {
  const _RoomSummaryCard({required this.room});

  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    return _LobbySurface(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKey.roomCode.tr.toUpperCase(),
                      style: AppStyles.bodyLarge(
                        color: PlayfulColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    12.height,
                    SelectableText(
                      room.code,
                      style: AppStyles.headlineLarge(
                        color: PlayfulColors.ink,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              _CopyButton(code: room.code),
            ],
          ),
          24.height,
          const Divider(height: 1, color: PlayfulColors.lobbyDivider),
          20.height,
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.group_rounded,
                  iconBackground: PlayfulColors.lobbySoftPurple,
                  iconColor: PlayfulColors.lobbyPurple,
                  label: LocaleKey.mode.tr,
                  value: _modeLabel(room.mode),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  icon: Icons.wifi_rounded,
                  iconBackground: PlayfulColors.lobbySoftGreen,
                  iconColor: PlayfulColors.green,
                  label: LocaleKey.status.tr,
                  value: _statusLabel(room.status),
                  valueColor: PlayfulColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _modeLabel(RoomMode mode) {
    return mode == RoomMode.coop
        ? LocaleKey.coopModeTitle.tr
        : LocaleKey.soloModeTitle.tr;
  }

  static String _statusLabel(RoomStatus status) {
    if (status == RoomStatus.waiting) return LocaleKey.waitingStatus.tr;
    return status.value.capitalizeFirst ?? status.value;
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        showSuccessToast(LocaleKey.copied.tr);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: 20.borderRadiusAll,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87A6C8).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: 70,
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.copy_rounded,
                color: PlayfulColors.lobbyPurple,
                size: 28,
              ),
              6.height,
              Text(
                LocaleKey.copy.tr,
                style: AppStyles.bodyLarge(
                  color: PlayfulColors.lobbyPurple,
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor = PlayfulColors.ink,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: 15.borderRadiusAll,
          ),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: iconColor, size: 29),
          ),
        ),
        12.width,
        Expanded(
          child: _MetricText(
            label: label,
            value: value,
            valueColor: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PlayersTitle extends StatelessWidget {
  const _PlayersTitle({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.group_rounded,
          color: PlayfulColors.lobbyPurple,
          size: 28,
        ),
        10.width,
        Text(
          '${LocaleKey.players.tr} ($count/2)',
          style: AppStyles.h3(
            color: PlayfulColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({
    required this.label,
    required this.value,
    this.valueColor = PlayfulColors.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyLarge(
            color: PlayfulColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        6.height,
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.h5(color: valueColor, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _LobbySurface extends StatelessWidget {
  const _LobbySurface({
    required this.child,
    required this.padding,
    this.radius = 26,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: _lobbyShadow,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

final List<BoxShadow> _lobbyShadow = [
  BoxShadow(
    color: PlayfulColors.muted.withValues(alpha: 0.12),
    blurRadius: 26,
    offset: const Offset(0, 12),
  ),
];

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppStyles.bodyMedium(color: AppColors.color667394)),
        const Spacer(),
        Text(
          value,
          style: AppStyles.bodyMedium(
            color: AppColors.color333333,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({
    required this.firstPlayer,
    required this.firstPresence,
    required this.secondPlayer,
    required this.secondPresence,
  });

  final RoomPlayer? firstPlayer;
  final RoomPresence? firstPresence;
  final RoomPlayer? secondPlayer;
  final RoomPresence? secondPresence;

  @override
  Widget build(BuildContext context) {
    return _LobbySurface(
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _PlayerRow(seat: 1, player: firstPlayer, presence: firstPresence),
          12.height,
          _PlayerRow(seat: 2, player: secondPlayer, presence: secondPresence),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.seat,
    required this.player,
    required this.presence,
  });

  final int seat;
  final RoomPlayer? player;
  final RoomPresence? presence;

  @override
  Widget build(BuildContext context) {
    final isWaiting = player == null && presence == null;
    final isOnline = presence != null;
    final isReady = presence?.ready ?? false;
    final name =
        player?.displayName ??
        presence?.displayName ??
        LocaleKey.waitingForPlayer.tr;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: PlayfulColors.lobbyPlayerRow.withValues(alpha: 0.82),
        borderRadius: 18.borderRadiusAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            _SeatBadge(seat: seat, active: !isWaiting),
            12.width,
            isWaiting
                ? const _WaitingAvatar()
                : PlayfulAvatar(size: 52, online: isOnline),
            14.width,
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.h4(
                  color: isWaiting ? PlayfulColors.muted : PlayfulColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            10.width,
            _ReadyStatusIcon(visible: !isWaiting, ready: isReady),
          ],
        ),
      ),
    );
  }
}

class _ReadyStatusIcon extends StatelessWidget {
  const _ReadyStatusIcon({required this.visible, required this.ready});

  final bool visible;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 30, height: 30);

    if (!ready) {
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PlayfulColors.muted, width: 2.2),
        ),
        child: const SizedBox(width: 30, height: 30),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PlayfulColors.green,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 30,
        height: 30,
        child: Icon(Icons.check_rounded, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.seat, required this.active});

  final int seat;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: active ? PlayfulColors.coopCardGradient : null,
        color: active ? null : PlayfulColors.lobbySeatInactive,
        borderRadius: 10.borderRadiusAll,
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            '$seat',
            style: AppStyles.h5(
              color: active ? AppColors.white : PlayfulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingAvatar extends StatelessWidget {
  const _WaitingAvatar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: PlayfulColors.muted.withValues(alpha: 0.45),
          width: 1.4,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: const SizedBox(
        width: 56,
        height: 56,
        child: Icon(
          Icons.person_outline_rounded,
          color: PlayfulColors.muted,
          size: 28,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LobbyNoticeCard extends StatelessWidget {
  const _LobbyNoticeCard({
    required this.canStartRound,
    required this.isStartingRound,
    required this.helperText,
    required this.onStart,
  });

  final bool canStartRound;
  final bool isStartingRound;
  final String helperText;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canStartRound ? onStart : null,
      child: _LobbySurface(
        radius: 20,
        padding: EdgeInsets.zero,
        border: Border.all(color: PlayfulColors.lobbyBorder, width: 1.2),
        child: SizedBox(
          height: 116,
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -8,
                width: 142,
                height: 108,
                child: IgnorePointer(
                  child: Image.asset(
                    AppAssets.lobbyBottomCharactersPng,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 108, 18),
                child: Row(
                  children: [
                    const _AlertIcon(),
                    14.width,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            canStartRound
                                ? (isStartingRound
                                      ? LocaleKey.startingRound.tr
                                      : LocaleKey.readyToStart.tr)
                                : helperText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyLarge(
                              color: PlayfulColors.ink,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          if (!canStartRound &&
                              helperText == LocaleKey.needTwoPlayers.tr) ...[
                            5.height,
                            Text(
                              LocaleKey.inviteFriendToStartGame.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.bodySmall(
                                color: PlayfulColors.muted,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  const _AlertIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PlayfulColors.lobbyWarningSoft,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: PlayfulColors.lobbyWarning, width: 2),
            ),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  '!',
                  style: AppStyles.h4(
                    color: PlayfulColors.lobbyWarning,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyPrimaryButton extends StatelessWidget {
  const _LobbyPrimaryButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF167BFF), Color(0xFF007AFF)],
                )
              : null,
          color: enabled ? null : PlayfulColors.muted.withValues(alpha: 0.28),
          borderRadius: 34.borderRadiusAll,
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: PlayfulColors.blue.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 32),
              16.width,
              Text(
                title,
                style: AppStyles.h3(
                  color: AppColors.white,
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

class _RoundStatusCard extends StatelessWidget {
  const _RoundStatusCard({
    required this.targetTitle,
    required this.targetUrl,
    required this.remainingMs,
    required this.onEnter,
  });

  final String targetTitle;
  final String? targetUrl;
  final int remainingMs;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = (remainingMs / 1000).ceil();

    return PlayfulCard(
      radius: 24,
      padding: 18.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKey.roundStarted.tr,
            style: AppStyles.bodyLarge(
              color: AppColors.color333333,
              fontWeight: FontWeight.w700,
            ),
          ),
          12.height,
          _InfoRow(label: LocaleKey.target.tr, value: targetTitle),
          8.height,
          _InfoRow(
            label: LocaleKey.timeRemaining.tr,
            value: '${remainingSeconds}s',
          ),
          if (targetUrl != null) ...[
            14.height,
            ClipRRect(
              borderRadius: 12.borderRadiusAll,
              child: Container(
                height: 180,
                width: double.infinity,
                color: AppColors.white,
                child: Image.network(targetUrl!, fit: BoxFit.contain),
              ),
            ),
          ],
          14.height,
          PlayfulGradientButton(
            title: LocaleKey.enterDrawing.tr,
            onTap: onEnter,
          ),
        ],
      ),
    );
  }
}
