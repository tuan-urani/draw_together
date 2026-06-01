import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:draw_together/src/locale/locale_key.dart';
import 'package:draw_together/src/extensions/int_extensions.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_styles.dart';

/// Hiển thị Cupertino Date Picker trong bottom sheet iOS-style bằng GetX.
///
/// [initialDateTime] - ngày giờ ban đầu hiển thị.
/// [onDateTimeChanged] - callback trả về giá trị người dùng chọn.
/// [minimumDate], [maximumDate] - tùy chọn giới hạn ngày.
Future<void> showCupertinoDatePickerBottomSheet({
  required DateTime initialDateTime,
  required ValueChanged<DateTime> onDateTimeChanged,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) async {
  DateTime tempPickedDate = initialDateTime;

  await Get.bottomSheet(
    Container(
      height: 300,
      color: AppColors.white,
      child: Column(
        children: [
          // Thanh nút Cancel / Done
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: 16.paddingHorizontal,
                  child: Text(LocaleKey.widgetCancel.tr),
                  onPressed: () => Get.back(),
                ),
                CupertinoButton(
                  padding: 16.paddingHorizontal,
                  child: Text(
                    LocaleKey.widgetConfirm.tr,
                    style: AppStyles.buttonMedium(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Get.back();
                    onDateTimeChanged(tempPickedDate);
                  },
                ),
              ],
            ),
          ),
          // Picker chính
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDateTime,
              minimumDate: minimumDate,
              maximumDate: maximumDate,
              onDateTimeChanged: (DateTime newDate) {
                tempPickedDate = newDate;
              },
            ),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}
