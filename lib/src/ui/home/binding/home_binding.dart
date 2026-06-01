import 'package:get/get.dart';

import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/ui/home/bloc/home_bloc.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeBloc>()) {
      Get.lazyPut<HomeBloc>(
        () =>
            HomeBloc(Get.find<ProfileRepository>(), Get.find<RoomRepository>()),
      );
    }
  }
}
