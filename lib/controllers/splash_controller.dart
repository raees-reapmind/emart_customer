import 'dart:async';
import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/screen_ui/maintenance_mode_screen/maintenance_mode_screen.dart';
import 'package:customer/screen_ui/service_home_screen/service_list_screen.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../screen_ui/auth_screens/login_screen.dart';
import '../screen_ui/location_enable_screens/location_permission_screen.dart';
import '../screen_ui/on_boarding_screen/on_boarding_screen.dart';
import '../service/fire_store_utils.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  Future<void> redirectScreen() async {
    if (Constant.isMaintenanceModeForCustomer == true) {
      Get.offAll(const MaintenanceModeScreen());
      return;
    }
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(const OnboardingScreen());
    } else {
      bool isLogin = await FireStoreUtils.isLogin();
      if (isLogin == true) {
        await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
          if (value != null) {
            UserModel userModel = value;
            log(userModel.toJson().toString());
            if (userModel.role == Constant.userRoleCustomer) {
              if (userModel.active == true) {
                userModel.fcmToken = await NotificationService.getToken();
                await FireStoreUtils.updateUser(userModel);
                if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                  if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                    Constant.selectedLocation = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                  } else {
                    Constant.selectedLocation = userModel.shippingAddress!.first;
                  }
                  Get.offAll(const ServiceListScreen());
                } else {
                  Get.offAll(const LocationPermissionScreen());
                }
              } else {
                await FirebaseAuth.instance.signOut();
                Get.offAll(const LoginScreen());
              }
            } else {
              await FirebaseAuth.instance.signOut();
              Get.offAll(const LoginScreen());
            }
          }
        });
      } else {
        await FirebaseAuth.instance.signOut();
        Get.offAll(const LoginScreen());
      }
    }
  }
}
