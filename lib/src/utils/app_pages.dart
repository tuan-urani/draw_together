import 'package:get/get.dart';

import 'package:draw_together/src/ui/drawing/binding/drawing_board_binding.dart';
import 'package:draw_together/src/ui/drawing/drawing_board_page.dart';
import 'package:draw_together/src/ui/history/binding/history_binding.dart';
import 'package:draw_together/src/ui/history/history_detail_page.dart';
import 'package:draw_together/src/ui/history/history_page.dart';
import 'package:draw_together/src/ui/home/binding/home_binding.dart';
import 'package:draw_together/src/ui/home/home_page.dart';
import 'package:draw_together/src/ui/main/main_page.dart';
import 'package:draw_together/src/ui/room_browser/binding/room_browser_binding.dart';
import 'package:draw_together/src/ui/room_browser/room_browser_page.dart';
import 'package:draw_together/src/ui/room/binding/room_lobby_binding.dart';
import 'package:draw_together/src/ui/room/room_lobby_page.dart';
import 'package:draw_together/src/ui/settings/settings_page.dart';
import 'package:draw_together/src/ui/settings/settings_web_view_page.dart';
import 'package:draw_together/src/ui/splash/splash_page.dart';

class AppPages {
  AppPages._();

  static const String splash = '/splash';
  static const String main = '/';
  static const String home = '/home';
  static const String roomBrowser = '/room-browser';
  static const String roomLobby = '/room-lobby';
  static const String drawingBoard = '/drawing-board';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String settings = '/settings';
  static const String settingsWebView = '/settings-web-view';

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: main, page: () => const MainPage(), binding: HomeBinding()),
    GetPage(name: home, page: () => const HomePage(), binding: HomeBinding()),
    GetPage(
      name: roomBrowser,
      page: () => const RoomBrowserPage(),
      binding: RoomBrowserBinding(),
    ),
    GetPage(
      name: roomLobby,
      page: () => const RoomLobbyPage(),
      binding: RoomLobbyBinding(),
    ),
    GetPage(
      name: drawingBoard,
      page: () => const DrawingBoardPage(),
      binding: DrawingBoardBinding(),
    ),
    GetPage(
      name: history,
      page: () => const HistoryPage(),
      binding: HistoryBinding(),
    ),
    GetPage(name: historyDetail, page: () => const HistoryDetailPage()),
    GetPage(name: settings, page: () => const SettingsPage()),
    GetPage(name: settingsWebView, page: () => const SettingsWebViewPage()),
  ];
}
