import 'package:get/get.dart';

import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/core/repository/target_repository.dart';
import 'package:draw_together/src/ui/room/bloc/room_lobby_bloc.dart';

class RoomLobbyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoomLobbyBloc>(
      () => RoomLobbyBloc(
        Get.find<RoomRepository>(),
        Get.find<TargetRepository>(),
      ),
    );
  }
}
