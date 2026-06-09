import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/audio/app_audio_tap.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/base/interactor/page_states.dart';
import 'package:draw_together/src/ui/home/bloc/home_bloc.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';
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
              previous.profile?.avatarUrl != current.profile?.avatarUrl ||
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
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
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
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            button: true,
                            label: LocaleKey.history.tr,
                            child: PlayfulIconButton(
                              icon: Icons.history_rounded,
                              onTap: () => Get.toNamed(AppPages.history),
                            ),
                          ),
                          4.width,
                          Semantics(
                            button: true,
                            label: LocaleKey.settingsTitle.tr,
                            child: PlayfulIconButton(
                              icon: Icons.settings_rounded,
                              onTap: () => Get.toNamed(AppPages.settings),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                16.height,
                Text(
                  'Draw, challenge, have fun!',
                  textAlign: TextAlign.center,
                  style: AppStyles.h4(
                    color: PlayfulColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                36.height,
                _ProfileSummary(
                  state: state,
                  avatarAsset: _profileAvatarAsset(state.profile?.avatarUrl),
                  onAvatarTap: state.isSaving
                      ? null
                      : () => _showAvatarPickerDialog(
                          _profileAvatarAsset(state.profile?.avatarUrl),
                        ),
                  onEdit: state.isSaving ? null : _showDisplayNameDialog,
                ),
                24.height,
                Row(
                  children: [
                    Expanded(
                      child: _ModeActionCard(
                        title: LocaleKey.coopModeTitle.tr,
                        characterAsset: AppAssets.characterCardLeftPng,
                        icon: Icons.groups_rounded,
                        gradient: PlayfulColors.coopCardGradient,
                        accentColor: PlayfulColors.blue,
                        onTap: state.isRoomActionLoading
                            ? null
                            : () => _openRoomBrowser(RoomMode.coop),
                      ),
                    ),
                    16.width,
                    Expanded(
                      child: _ModeActionCard(
                        title: LocaleKey.soloModeTitle.tr,
                        characterAsset: AppAssets.characterCardRightPng,
                        icon: Icons.bolt_rounded,
                        gradient: PlayfulColors.soloCardGradient,
                        accentColor: PlayfulColors.purpleDark,
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
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
          UpperCaseTextFormatter(),
        ],
      ),
    );

    if (!mounted || roomCode == null) return;
    await _bloc.joinRoom(roomCode);
  }

  Future<void> _showDisplayNameDialog() async {
    final displayName = await Get.dialog<String>(
      _HomeTextInputDialog(
        title: LocaleKey.editName.tr,
        hintText: LocaleKey.displayNameHint.tr,
        submitLabel: LocaleKey.save.tr,
        initialText: _displayNameController.text,
        maxLength: 40,
      ),
    );

    if (!mounted || displayName == null) return;
    await _bloc.updateDisplayName(displayName);
  }

  Future<void> _showAvatarPickerDialog(String selectedAvatar) async {
    final avatarAsset = await Get.dialog<String>(
      AppPlayfulDialog(
        title: LocaleKey.chooseAvatar.tr,
        tone: AppPlayfulDialogTone.info,
        content: _AvatarPickerGrid(selectedAvatar: selectedAvatar),
        actions: [
          AppPlayfulDialogButton(
            label: LocaleKey.cancel.tr,
            style: AppPlayfulDialogButtonStyle.soft,
            onTap: () => Get.back<String>(),
          ),
        ],
      ),
    );

    if (!mounted || avatarAsset == null || avatarAsset == selectedAvatar) {
      return;
    }
    await _bloc.updateAvatar(avatarAsset);
  }

  void _openRoomBrowser(RoomMode mode) {
    Get.toNamed(AppPages.roomBrowser, arguments: {'mode': mode});
  }

  String _profileAvatarAsset(String? avatarUrl) {
    if (avatarUrl != null && AppAssets.avatarPngs.contains(avatarUrl)) {
      return avatarUrl;
    }

    return AppAssets.defaultAvatarPng;
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
    this.inputFormatters,
  });

  final String title;
  final String hintText;
  final String submitLabel;
  final String initialText;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

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
    return AppPlayfulDialog(
      title: widget.title,
      tone: AppPlayfulDialogTone.info,
      showCloseButton: false,
      content: _PlayfulTextField(
        controller: _controller,
        hintText: widget.hintText,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        onSubmitted: _submit,
      ),
      actions: [
        AppPlayfulDialogButton(
          label: LocaleKey.cancel.tr,
          style: AppPlayfulDialogButtonStyle.soft,
          onTap: () => Get.back<String>(),
        ),
        AppPlayfulDialogButton(label: widget.submitLabel, onTap: _submit),
      ],
    );
  }

  void _submit() => Get.back<String>(result: _controller.text.trim());
}

class _PlayfulTextField extends StatelessWidget {
  const _PlayfulTextField({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSubmitted;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: maxLength,
      textAlign: maxLength == 6 ? TextAlign.center : TextAlign.start,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: AppStyles.bodyLarge(
        color: PlayfulColors.ink,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterStyle: AppStyles.bodySmall(
          color: PlayfulColors.muted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: AppStyles.bodyMedium(
          color: PlayfulColors.muted.withValues(alpha: 0.72),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: 12.borderRadiusAll,
          borderSide: const BorderSide(color: PlayfulColors.lobbyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: 12.borderRadiusAll,
          borderSide: const BorderSide(color: PlayfulColors.blue, width: 1.4),
        ),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _AvatarPickerGrid extends StatelessWidget {
  const _AvatarPickerGrid({required this.selectedAvatar});

  final String selectedAvatar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final avatarAsset in AppAssets.avatarPngs)
          _AvatarOption(
            avatarAsset: avatarAsset,
            selected: avatarAsset == selectedAvatar,
          ),
      ],
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({required this.avatarAsset, required this.selected});

  final String avatarAsset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(() => Get.back<String>(result: avatarAsset)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? PlayfulColors.softBlue : AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? PlayfulColors.blue : PlayfulColors.lobbyBorder,
            width: selected ? 3 : 1.4,
          ),
          boxShadow: selected ? playfulBlueShadow : playfulShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PlayfulAvatar(size: 62, online: false, imageAsset: avatarAsset),
              if (selected)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: PlayfulColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 16,
                      ),
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

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.state,
    required this.avatarAsset,
    required this.onAvatarTap,
    required this.onEdit,
  });

  final HomeState state;
  final String avatarAsset;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return PlayfulCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppAudioTap.wrap(onAvatarTap),
            child: PlayfulAvatar(size: 58, imageAsset: avatarAsset),
          ),
          16.width,
          Expanded(
            child: Text(
              profile.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.h4(
                color: PlayfulColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: AppAudioTap.wrap(onEdit),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FA),
                borderRadius: 20.borderRadiusAll,
              ),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.edit_outlined,
                  color: PlayfulColors.ink,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeActionCard extends StatelessWidget {
  const _ModeActionCard({
    required this.title,
    required this.characterAsset,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String characterAsset;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AppAudioTap.wrap(onTap),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: 28.borderRadiusAll,
          boxShadow: playfulShadow,
        ),
        child: AspectRatio(
          aspectRatio: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeIconBadge(icon: icon),
                Expanded(
                  child: Image.asset(
                    characterAsset,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.h3(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                    6.width,
                    _ModeArrowButton(color: accentColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeIconBadge extends StatelessWidget {
  const _ModeIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.32),
          width: 2,
        ),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: AppColors.white, size: 24),
      ),
    );
  }
}

class _ModeArrowButton extends StatelessWidget {
  const _ModeArrowButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.arrow_forward_rounded, color: color, size: 24),
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
      onTap: enabled ? AppAudioTap.wrap(onTap) : null,
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
            padding: const EdgeInsets.fromLTRB(28, 0, 24, 0),
            child: Row(
              children: [
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
                        LocaleKey.joinRoomPrompt.tr,
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
                    width: 44,
                    height: 44,
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
