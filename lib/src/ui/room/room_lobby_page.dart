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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.lobbyRoomPng),
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

              if (state.pageState == PageState.loading && state.room == null) {
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
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                  children: [
                    _LobbyHeader(onBack: Get.back<void>),
                    44.height,
                    _RoomSummaryCard(room: room),
                    28.height,
                    _PlayersTitle(count: state.players.length),
                    14.height,
                    _PlayersCard(
                      firstPlayer: _playerAtSeat(state.players, 1),
                      firstPresence: _presenceAtSeat(state.presences, 1),
                      secondPlayer: _playerAtSeat(state.players, 2),
                      secondPresence: _presenceAtSeat(state.presences, 2),
                    ),
                    26.height,
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
                      _LobbyNoticeCard(
                        isHost: state.isHost,
                        canStartRound: state.canStartRound,
                        isStartingRound: state.isStartingRound,
                        helperText: _startHelperText(state),
                        onStart: _bloc.startRound,
                      ),
                      28.height,
                    ],
                    _LobbyPrimaryButton(
                      title: state.canStartRound
                          ? (state.isStartingRound
                                ? LocaleKey.startingRound.tr
                                : LocaleKey.startRound.tr)
                          : (state.isReady
                                ? LocaleKey.ready.tr
                                : LocaleKey.markReady.tr),
                      icon: state.canStartRound
                          ? Icons.play_arrow_rounded
                          : Icons.send_rounded,
                      onTap: state.canStartRound
                          ? _bloc.startRound
                          : () => _bloc.setReady(!state.isReady),
                    ),
                  ],
                ),
              );
            },
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

  String _startHelperText(RoomLobbyState state) {
    if (!state.isHost) return LocaleKey.waitingForHost.tr;
    if (!state.hasTwoPlayers) return LocaleKey.needTwoPlayers.tr;
    if (!state.allPlayersReady) return LocaleKey.waitingForReady.tr;
    return LocaleKey.readyToStart.tr;
  }
}

class _LobbyHeader extends StatelessWidget {
  const _LobbyHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CircleActionButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        20.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKey.roomLobby.tr,
                style: AppStyles.h1(
                  color: PlayfulColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              6.height,
              Text(
                'Invite friends with room code',
                style: AppStyles.bodyLarge(
                  color: PlayfulColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
          width: 56,
          height: 56,
          child: Icon(icon, color: PlayfulColors.ink, size: 24),
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
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 26, 20, 24),
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
                    14.height,
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
          30.height,
          const Divider(height: 1, color: Color(0xFFE1E8F3)),
          24.height,
          Row(
            children: [
              const _SoftIconBox(
                icon: Icons.games_rounded,
                background: Color(0xFFF0DFFF),
                color: PlayfulColors.purple,
              ),
              16.width,
              Expanded(
                child: _MetricText(
                  label: LocaleKey.mode.tr,
                  value: room.mode.label,
                ),
              ),
              const SizedBox(
                height: 48,
                child: VerticalDivider(width: 1, color: Color(0xFFE1E8F3)),
              ),
              22.width,
              const _SoftIconBox(
                icon: Icons.wifi_rounded,
                background: Color(0xFFE5F8EA),
                color: PlayfulColors.green,
              ),
              16.width,
              Expanded(
                child: _MetricText(
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

  static String _statusLabel(RoomStatus status) {
    if (status == RoomStatus.waiting) return 'Waiting';
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
          borderRadius: 22.borderRadiusAll,
          border: Border.all(color: const Color(0xFFE1E8F3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87A6C8).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          width: 72,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.copy_rounded,
                color: PlayfulColors.ink,
                size: 30,
              ),
              8.height,
              Text(
                'Copy',
                style: AppStyles.bodyLarge(
                  color: PlayfulColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftIconBox extends StatelessWidget {
  const _SoftIconBox({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: 16.borderRadiusAll,
      ),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Icon(icon, color: color, size: 32),
      ),
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
        const Icon(Icons.group_rounded, color: PlayfulColors.blue, size: 28),
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
          style: AppStyles.h4(color: valueColor, fontWeight: FontWeight.w900),
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
    color: const Color(0xFF87A6C8).withValues(alpha: 0.12),
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
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        children: [
          _PlayerRow(seat: 1, player: firstPlayer, presence: firstPresence),
          20.height,
          const Divider(height: 1, color: Color(0xFFE1E8F3)),
          20.height,
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
    final isWaiting = player == null;
    final isOnline = presence != null;
    final name = player?.displayName ?? LocaleKey.waitingForPlayer.tr;

    return Row(
      children: [
        _SeatBadge(seat: seat, active: !isWaiting),
        14.width,
        isWaiting
            ? const _WaitingAvatar()
            : PlayfulAvatar(size: 56, online: isOnline),
        18.width,
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
        if (!isWaiting)
          _OnlineLabel(
            label: isOnline ? LocaleKey.online.tr : LocaleKey.offline.tr,
            color: isOnline ? PlayfulColors.green : PlayfulColors.muted,
          ),
        if (presence?.ready ?? false) ...[
          8.width,
          _OnlineLabel(label: LocaleKey.ready.tr, color: PlayfulColors.blue),
        ],
      ],
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
        color: active ? PlayfulColors.blue : const Color(0xFFEAF1FB),
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
          color: const Color(0xFFB8C6DE),
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

class _OnlineLabel extends StatelessWidget {
  const _OnlineLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 10, height: 10),
        ),
        8.width,
        Text(
          label,
          style: AppStyles.bodyLarge(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _LobbyNoticeCard extends StatelessWidget {
  const _LobbyNoticeCard({
    required this.isHost,
    required this.canStartRound,
    required this.isStartingRound,
    required this.helperText,
    required this.onStart,
  });

  final bool isHost;
  final bool canStartRound;
  final bool isStartingRound;
  final String helperText;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canStartRound ? onStart : null,
      child: _LobbySurface(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: Border.all(color: const Color(0xFFDCE8F8), width: 1.2),
        child: Row(
          children: [
            const _AlertIcon(),
            18.width,
            Expanded(
              child: Text(
                canStartRound
                    ? (isStartingRound
                          ? LocaleKey.startingRound.tr
                          : LocaleKey.readyToStart.tr)
                    : helperText,
                style: AppStyles.bodyLarge(
                  color: PlayfulColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
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
        color: Color(0xFFFFEBC0),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFB62D), width: 2),
            ),
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(
                child: Text(
                  '!',
                  style: AppStyles.h4(
                    color: const Color(0xFFFFB62D),
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF167BFF), Color(0xFF007AFF)],
          ),
          borderRadius: 34.borderRadiusAll,
          boxShadow: [
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
