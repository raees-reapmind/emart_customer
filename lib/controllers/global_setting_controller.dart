import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/currency_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../constant/collection_name.dart';
import '../service/fire_store_utils.dart';

class GlobalSettingController extends GetxController {
  @override
  void onInit() {
    notificationInit();
    getCurrentCurrency();

    super.onInit();
  }

  Future<void> getCurrentCurrency() async {
    FireStoreUtils.fireStore.collection(CollectionName.currencies).where("isActive", isEqualTo: true).snapshots().listen((event) {
      if (event.docs.isNotEmpty) {
        Constant.currencyModel = CurrencyModel.fromJson(event.docs.first.data());
      } else {
        Constant.currencyModel = CurrencyModel(id: "", code: "USD", decimal: 2, isactive: true, name: "US Dollar", symbol: "\$", symbolatright: false);
      }
    });
    await FireStoreUtils.getSettings();
  }

  NotificationService notificationService = NotificationService();

  void notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      if (FirebaseAuth.instance.currentUser != null) {
        await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) {
          if (value != null) {
            UserModel driverUserModel = value;
            driverUserModel.fcmToken = token;
            FireStoreUtils.updateUser(driverUserModel);
          }
        });
      }
    });
  }
}
