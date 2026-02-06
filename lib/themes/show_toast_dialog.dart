import 'package:flutter_easyloading/flutter_easyloading.dart';

class ShowToastDialog {
  /// Show a toast message with customizable position.
  static void showToast(
    String? message, {
    EasyLoadingToastPosition position = EasyLoadingToastPosition.top,
  }) {
    if (message == null || message.isEmpty) return;
    EasyLoading.showToast(message, toastPosition: position);
  }

  /// Show a loading indicator with a status message.
  static void showLoader(String message) {
    EasyLoading.show(
      status: message,
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );
  }

  /// Dismiss any active loading indicator.
  static void closeLoader() {
    EasyLoading.dismiss();
  }
}
