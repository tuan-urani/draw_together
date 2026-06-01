import 'package:get/get.dart';

import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/core/repository/scoring_repository.dart';
import 'package:draw_together/src/core/repository/submission_repository.dart';
import 'package:draw_together/src/core/repository/target_repository.dart';
import 'package:draw_together/src/ui/drawing/bloc/drawing_board_bloc.dart';

class DrawingBoardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DrawingBoardBloc>()) {
      Get.lazyPut<DrawingBoardBloc>(
        () => DrawingBoardBloc(
          Get.find<RoomRepository>(),
          Get.find<TargetRepository>(),
          Get.find<SubmissionRepository>(),
          Get.find<ScoringRepository>(),
        ),
      );
    }
  }
}
