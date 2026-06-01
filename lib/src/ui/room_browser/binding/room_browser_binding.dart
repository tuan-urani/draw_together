import 'package:get/get.dart';

import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/ui/room_browser/bloc/room_browser_bloc.dart';

class RoomBrowserBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final mode = args is Map && args['mode'] is RoomMode
        ? args['mode'] as RoomMode
        : RoomMode.coop;

    Get.lazyPut<RoomBrowserBloc>(
      () => RoomBrowserBloc(Get.find<RoomRepository>(), mode),
    );
  }
}
