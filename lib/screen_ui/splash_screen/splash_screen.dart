import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constant/assets.dart';
import '../../controllers/splash_controller.dart';
import '../../themes/app_them_data.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(backgroundColor: AppThemeData.surface, body: Center(child: Image.asset(AppAssets.icAppLogo, width: 120, height: 120)));
      },
    );
  }
}
