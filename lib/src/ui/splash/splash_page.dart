import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/audio/app_audio_manager.dart';
import 'package:draw_together/src/core/repository/auth_repository.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/di/di_graph_setup.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/utils/app_assets.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static bool _didReleaseFirstFrame = false;

  late final AnimationController _loadingController;
  late final Animation<double> _progressAnimation;
  bool _didPrepareFirstFrame = false;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrepareFirstFrame) return;
    _didPrepareFirstFrame = true;
    _prepareFirstFrame();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _prepareFirstFrame() async {
    try {
      await precacheImage(const AssetImage(AppAssets.splashScreenPng), context);
    } finally {
      if (!_didReleaseFirstFrame) {
        WidgetsBinding.instance.allowFirstFrame();
        _didReleaseFirstFrame = true;
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final minimumSplashDuration = Future<void>.delayed(
        const Duration(seconds: 2),
      );

      await setupDependenciesGraph();
      Get.find<AppAudioManager>().startBackgroundMusic();
      final preloadResources = _preloadSplashResources();

      final authRepository = Get.find<AuthRepository>();
      final profileRepository = Get.find<ProfileRepository>();

      await authRepository.ensureAnonymousSession();
      await profileRepository.ensureCurrentProfile();
      await Future.wait([minimumSplashDuration, preloadResources]);

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

  Future<void> _preloadSplashResources() async {
    final imagePreloads = AppAssets.splashPreloadImageAssets.map(
      (asset) => precacheImage(AssetImage(asset), context),
    );
    final audioPreloads = AppAssets.splashPreloadAudioAssets.map(
      (asset) async => rootBundle.load(asset),
    );

    await Future.wait([...imagePreloads, ...audioPreloads]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorF7FBFF,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.splashScreenPng, fit: BoxFit.cover),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
                child: _isLoading
                    ? _SplashLoading(progressAnimation: _progressAnimation)
                    : _SplashError(
                        message: _errorMessage ?? LocaleKey.unknownError.tr,
                        onRetry: _bootstrap,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading({required this.progressAnimation});

  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKey.preparingSession.tr,
            textAlign: TextAlign.center,
            style: AppStyles.bodyLarge(
              color: AppColors.color143A72,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          14.height,
          _SplashProgressBar(progressAnimation: progressAnimation),
        ],
      ),
    );
  }
}

class _SplashProgressBar extends StatelessWidget {
  const _SplashProgressBar({required this.progressAnimation});

  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.colorE4F0FF,
        borderRadius: 9.borderRadiusAll,
        border: Border.all(color: AppColors.colorD8E8FA),
        boxShadow: const [
          BoxShadow(
            color: AppColors.color1A0095FF,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: 8.borderRadiusAll,
        child: SizedBox(
          height: 18,
          child: AnimatedBuilder(
            animation: progressAnimation,
            builder: (context, child) {
              return Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progressAnimation.value,
                  child: child,
                ),
              );
            },
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.color46B7FF, AppColors.color1E72F2],
                  ),
                  borderRadius: 8.borderRadiusAll,
                ),
              ),
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
