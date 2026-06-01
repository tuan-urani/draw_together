import 'package:flutter/material.dart';

import 'package:draw_together/src/ui/home/home_page.dart';

Route<dynamic> homeRouter(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const HomePage(),
  );
}
