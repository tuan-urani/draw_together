import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/home/bloc/home_bloc.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeBloc _bloc;
  late final TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _bloc = Get.find<HomeBloc>();
    _displayNameController = TextEditingController();
    _bloc.loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulScaffold(
      child: BlocConsumer<HomeBloc, HomeState>(
        bloc: _bloc,
        listenWhen: (previous, current) {
          return previous.errorMessage != current.errorMessage ||
              previous.profile?.displayName != current.profile?.displayName ||
              previous.activeRoom?.id != current.activeRoom?.id;
        },
        listener: (context, state) {
          final errorMessage = state.errorMessage;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            showErrorToast(errorMessage);
          }

          final displayName = state.profile?.displayName;
          if (displayName != null &&
              displayName != _displayNameController.text) {
            _displayNameController.text = displayName;
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
          if (state.pageState == PageState.loading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PlayfulAvatar(size: 74),
                    _NotificationButton(onTap: () {}),
                  ],
                ),
                28.height,
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Draw\n',
                        style: AppStyles.h40(
                          color: PlayfulColors.ink,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                      ),
                      TextSpan(
                        text: 'Together!',
                        style: AppStyles.h40(
                          color: PlayfulColors.blue,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                Text(
                  'Draw, guess, have fun!',
                  textAlign: TextAlign.center,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                36.height,
                _ProfileSummary(
                  state: state,
                  onEdit: state.isSaving ? null : _showDisplayNameDialog,
                ),
                24.height,
                Row(
                  children: [
                    Expanded(
                      child: _ModeActionCard(
                        backgroundAsset: AppAssets.card1Png,
                        onTap: state.isRoomActionLoading
                            ? null
                            : () => _openRoomBrowser(RoomMode.coop),
                      ),
                    ),
                    16.width,
                    Expanded(
                      child: _ModeActionCard(
                        backgroundAsset: AppAssets.card2Png,
                        onTap: state.isRoomActionLoading
                            ? null
                            : () => _openRoomBrowser(RoomMode.versus),
                      ),
                    ),
                  ],
                ),
                22.height,
                _JoinRoomCard(
                  enabled: !state.isRoomActionLoading,
                  onTap: _showJoinRoomDialog,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showJoinRoomDialog() async {
    final roomCode = await Get.dialog<String>(
      _HomeTextInputDialog(
        title: LocaleKey.joinRoom.tr,
        hintText: LocaleKey.roomCodeHint.tr,
        submitLabel: LocaleKey.joinRoom.tr,
        textCapitalization: TextCapitalization.characters,
      ),
    );

    if (!mounted || roomCode == null) return;
    await _bloc.joinRoom(roomCode);
  }

  Future<void> _showDisplayNameDialog() async {
    final displayName = await Get.dialog<String>(
      _HomeTextInputDialog(
        title: LocaleKey.displayName.tr,
        hintText: LocaleKey.displayNameHint.tr,
        submitLabel: LocaleKey.save.tr,
        initialText: _displayNameController.text,
        maxLength: 40,
      ),
    );

    if (!mounted || displayName == null) return;
    await _bloc.updateDisplayName(displayName);
  }

  void _openRoomBrowser(RoomMode mode) {
    Get.toNamed(AppPages.roomBrowser, arguments: {'mode': mode});
  }
}

class _HomeTextInputDialog extends StatefulWidget {
  const _HomeTextInputDialog({
    required this.title,
    required this.hintText,
    required this.submitLabel,
    this.initialText = '',
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final String title;
  final String hintText;
  final String submitLabel;
  final String initialText;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  State<_HomeTextInputDialog> createState() => _HomeTextInputDialogState();
}

class _HomeTextInputDialogState extends State<_HomeTextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: Text(LocaleKey.cancel.tr),
        ),
        TextButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }

  void _submit() => Get.back<String>(result: _controller.text);
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.96),
              borderRadius: 26.borderRadiusAll,
              boxShadow: playfulShadow,
            ),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                Icons.notifications_none_rounded,
                color: PlayfulColors.ink,
                size: 32,
              ),
            ),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D45),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              child: const SizedBox(width: 14, height: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.state, required this.onEdit});

  final HomeState state;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return PlayfulCard(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        children: [
          const PlayfulAvatar(size: 82),
          22.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                8.height,
                const _OnlinePill(),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: 20.borderRadiusAll,
              ),
              child: const SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.edit_outlined,
                  color: PlayfulColors.ink,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: 99.borderRadiusAll,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF87A6C8).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: PlayfulColors.green,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 12, height: 12),
            ),
            8.width,
            Text(
              LocaleKey.online.tr,
              style: AppStyles.bodyLarge(
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

class _ModeActionCard extends StatelessWidget {
  const _ModeActionCard({required this.backgroundAsset, required this.onTap});

  final String backgroundAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.contain,
          ),
          borderRadius: 28.borderRadiusAll,
          boxShadow: playfulShadow,
        ),
        child: SizedBox(height: 206),
      ),
    );
  }
}

class _JoinRoomCard extends StatelessWidget {
  const _JoinRoomCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC63F), Color(0xFFFFD967)],
          ),
          borderRadius: 32.borderRadiusAll,
          boxShadow: playfulShadow,
        ),
        child: SizedBox(
          height: 104,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(
                  Icons.login_rounded,
                  color: AppColors.black,
                  size: 36,
                ),
                22.width,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKey.joinRoom.tr,
                        style: AppStyles.h4(
                          color: PlayfulColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      4.height,
                      Text(
                        'Enter a code and start playing',
                        style: AppStyles.bodyMedium(
                          color: PlayfulColors.ink.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF8600),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
