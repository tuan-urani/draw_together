import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/audio/app_audio_manager.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/ui/settings/components/settings_cards.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 34),
        children: [
          PlayfulHeader(
            title: LocaleKey.settingsTitle.tr,
            subtitle: LocaleKey.settingsSubtitle.tr,
            leading: PlayfulIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: Get.back<void>,
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
                ),
              ],
            ),
          ),
        ],
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

  void _openWebView({required String title, required String url}) {
    Get.toNamed(
      AppPages.settingsWebView,
      arguments: {'title': title, 'url': url},
    );
  }
}
