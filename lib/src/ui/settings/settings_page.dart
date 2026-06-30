import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/audio/app_audio_manager.dart';
import 'package:draw_together/src/core/repository/auth_repository.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/ui/settings/components/settings_cards.dart';
import 'package:draw_together/src/ui/widgets/app_playful_dialog.dart';
import 'package:draw_together/src/ui/widgets/base/toast/app_toast.dart';
import 'package:draw_together/src/ui/widgets/loading_full_screen.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_shared.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _privacyPolicyUrl =
      'https://show.urani.tech/drawtogether/privacy-policy.html';
  static const String _termsOfUseUrl =
      'https://show.urani.tech/drawtogether/terms-of-use.html';

  late bool _backgroundMusicEnabled;
  late bool _soundEffectsEnabled;
  late String _selectedLanguageCode;
  bool _isDeletingAccount = false;

  AppAudioManager? get _audioManager {
    if (!Get.isRegistered<AppAudioManager>()) return null;
    return Get.find<AppAudioManager>();
  }

  @override
  void initState() {
    super.initState();
    final audioManager = _audioManager;
    _backgroundMusicEnabled = audioManager?.backgroundMusicEnabled ?? true;
    _soundEffectsEnabled = audioManager?.soundEffectsEnabled ?? true;
    _selectedLanguageCode =
        Get.locale?.languageCode ??
        TranslationManager.defaultLocale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingFullScreen(
      loading: _isDeletingAccount,
      child: PlayfulScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 34),
          children: [
            PlayfulHeader(
              title: LocaleKey.settingsTitle.tr,
              subtitle: LocaleKey.settingsSubtitle.tr,
              leading: PlayfulIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: _isDeletingAccount ? null : Get.back<void>,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsSectionCard(
                    title: LocaleKey.settingsAudio.tr,
                    icon: Icons.volume_up_rounded,
                    iconColor: AppColors.white,
                    iconBackground: PlayfulColors.blue,
                    children: [
                      SettingsToggleRow(
                        label: LocaleKey.settingsBackgroundMusic.tr,
                        icon: Icons.music_note_rounded,
                        iconColor: PlayfulColors.blue,
                        iconBackground: PlayfulColors.settingsBlueSoft,
                        value: _backgroundMusicEnabled,
                        onChanged: _setBackgroundMusicEnabled,
                        onLabel: LocaleKey.settingsToggleOn.tr,
                      ),
                      SettingsToggleRow(
                        label: LocaleKey.settingsSoundEffects.tr,
                        icon: Icons.graphic_eq_rounded,
                        iconColor: PlayfulColors.settingsPurple,
                        iconBackground: PlayfulColors.settingsPurpleSoft,
                        value: _soundEffectsEnabled,
                        onChanged: _setSoundEffectsEnabled,
                        onLabel: LocaleKey.settingsToggleOn.tr,
                        showDivider: false,
                      ),
                    ],
                  ),
                  26.height,
                  SettingsSectionCard(
                    title: LocaleKey.settingsSupport.tr,
                    icon: Icons.description_rounded,
                    iconColor: AppColors.white,
                    iconBackground: PlayfulColors.settingsGold,
                    children: [
                      SettingsLanguageRow(
                        label: LocaleKey.settingsLanguage.tr,
                        value: _selectedLanguageCode,
                        options: <String, String>{
                          'en': LocaleKey.languageEnglish.tr,
                          'vi': LocaleKey.languageVietnamese.tr,
                          'ja': LocaleKey.languageJapanese.tr,
                        },
                        onChanged: _setLanguage,
                      ),
                      SettingsLinkRow(
                        label: LocaleKey.settingsPrivacyPolicy.tr,
                        icon: Icons.shield_outlined,
                        iconColor: PlayfulColors.settingsGold,
                        iconBackground: PlayfulColors.settingsGoldSoft,
                        onTap: () => _openWebView(
                          title: LocaleKey.settingsPrivacyPolicy.tr,
                          url: _privacyPolicyUrl,
                        ),
                        showDivider: true,
                      ),
                      SettingsLinkRow(
                        label: LocaleKey.settingsTermsOfUse.tr,
                        icon: Icons.article_rounded,
                        iconColor: PlayfulColors.settingsGold,
                        iconBackground: PlayfulColors.settingsGoldSoft,
                        onTap: () => _openWebView(
                          title: LocaleKey.settingsTermsOfUse.tr,
                          url: _termsOfUseUrl,
                        ),
                        showDivider: false,
                      ),
                    ],
                  ),
                  30.height,
                  SettingsDeleteCard(
                    title: LocaleKey.settingsDeleteAccount.tr,
                    subtitle: LocaleKey.settingsDeleteAccountSubtitle.tr,
                    onTap: _isDeletingAccount ? null : _handleDeleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setBackgroundMusicEnabled(bool enabled) async {
    setState(() => _backgroundMusicEnabled = enabled);
    await _audioManager?.setBackgroundMusicEnabled(enabled);
  }

  Future<void> _setSoundEffectsEnabled(bool enabled) async {
    setState(() => _soundEffectsEnabled = enabled);
    await _audioManager?.setSoundEffectsEnabled(enabled);
  }

  void _setLanguage(String languageCode) {
    final locale = TranslationManager.resolveLocale(languageCode);
    setState(() => _selectedLanguageCode = locale.languageCode);
    Get.locale = locale;
    Get.appUpdate();

    if (Get.isRegistered<AppShared>()) {
      unawaited(Get.find<AppShared>().setLanguageCode(locale.languageCode));
    }
  }

  void _openWebView({required String title, required String url}) {
    Get.toNamed(
      AppPages.settingsWebView,
      arguments: {'title': title, 'url': url},
    );
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;

    final shouldDelete = await _confirmDeleteAccount();
    if (!mounted || !shouldDelete) return;

    setState(() => _isDeletingAccount = true);

    try {
      await Get.find<AuthRepository>().deleteCurrentAccount();
      if (!mounted) return;
      Get.offAllNamed(AppPages.splash);
    } on AuthException catch (error) {
      _showDeleteAccountError(error.message);
    } catch (_) {
      _showDeleteAccountError(LocaleKey.settingsDeleteAccountFailed.tr);
    }
  }

  Future<bool> _confirmDeleteAccount() async {
    final result = await Get.dialog<bool>(
      AppPlayfulDialog(
        title: LocaleKey.settingsDeleteAccountConfirmTitle.tr,
        subtitle: LocaleKey.settingsDeleteAccountConfirmMessage.tr,
        tone: AppPlayfulDialogTone.danger,
        actions: [
          AppPlayfulDialogButton(
            label: LocaleKey.cancel.tr,
            style: AppPlayfulDialogButtonStyle.soft,
            onTap: () => Get.back<bool>(result: false),
          ),
          AppPlayfulDialogButton(
            label: LocaleKey.settingsDeleteAccountConfirmAction.tr,
            style: AppPlayfulDialogButtonStyle.danger,
            onTap: () => Get.back<bool>(result: true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showDeleteAccountError(String message) {
    if (!mounted) return;
    setState(() => _isDeletingAccount = false);
    showErrorToast(message);
  }
}
