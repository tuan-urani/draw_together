import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/ui/widgets/app_inapp_webview.dart';
import 'package:draw_together/src/ui/widgets/playful_ui.dart';

class SettingsWebViewPage extends StatelessWidget {
  const SettingsWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final title = args is Map ? args['title'] as String? : null;
    final url = args is Map ? args['url'] as String? : null;

    return PlayfulScaffold(
      child: Column(
        children: [
          PlayfulHeader(
            title: title ?? '',
            leading: PlayfulIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: Get.back<void>,
            ),
          ),
          Expanded(child: AppInAppWebView(url: url ?? 'about:blank')),
        ],
      ),
    );
  }
}
