import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/repository/auth_repository.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = Get.find<AuthRepository>();
      final profileRepository = Get.find<ProfileRepository>();

      await authRepository.ensureAnonymousSession();
      await profileRepository.ensureCurrentProfile();

      if (!mounted) return;
      Get.offNamed(AppPages.main);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAEEBFA),
      body: SafeArea(
        child: Padding(
          padding: 24.paddingAll,
          child: Center(
            child: _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.white),
                      24.height,
                      Text(
                        LocaleKey.preparingSession.tr,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyLarge(color: AppColors.white),
                      ),
                    ],
                  )
                : _SplashError(
                    message: _errorMessage ?? LocaleKey.unknownError.tr,
                    onRetry: _bootstrap,
                  ),
          ),
        ),
      ),
    );
  }
}

class _SplashError extends StatelessWidget {
  const _SplashError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LocaleKey.sessionSetupFailed.tr,
          textAlign: TextAlign.center,
          style: AppStyles.h4(
            color: AppColors.color333333,
            fontWeight: FontWeight.w700,
          ),
        ),
        12.height,
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppStyles.bodyMedium(color: AppColors.color667394),
        ),
        24.height,
        ElevatedButton(onPressed: onRetry, child: Text(LocaleKey.retry.tr)),
      ],
    );
  }
}
