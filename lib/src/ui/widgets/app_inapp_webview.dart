import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AppInAppWebView extends StatefulWidget {
  final String url;
  final Function(List<dynamic>)? callback;

  const AppInAppWebView({super.key, required this.url, this.callback});

  @override
  State<AppInAppWebView> createState() => _AppInAppWebViewState();
}

class _AppInAppWebViewState extends State<AppInAppWebView> {
  // InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      gestureRecognizers: {Factory(() => EagerGestureRecognizer())},
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: InAppWebViewSettings(
        useShouldOverrideUrlLoading: false,
        transparentBackground: true,
        javaScriptEnabled: true,
      ),
      onWebViewCreated: (controller) {
        // _webViewController = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (_, _) {},
      onReceivedError: (_, _, _) {
        // TODO: Show error alert message (Error in receive data from server)
      },
      onReceivedHttpError: (_, _, _) {
        // TODO: Show error alert message (Error in receive data from server)
      },
      onConsoleMessage: (controller, consoleMessage) {},
    );
  }
}
