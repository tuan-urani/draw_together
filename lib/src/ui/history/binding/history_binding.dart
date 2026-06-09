import 'package:get/get.dart';

import 'package:draw_together/src/core/repository/history_repository.dart';
import 'package:draw_together/src/ui/history/bloc/history_bloc.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryBloc>(() => HistoryBloc(Get.find<HistoryRepository>()));
  }
}
