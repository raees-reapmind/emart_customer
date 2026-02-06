import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/dash_board_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../controllers/theme_controller.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDark.value;
      return GetX(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            body: controller.pageList[controller.selectedIndex.value],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              selectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontFamily: AppThemeData.bold),
              unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.bold),
              currentIndex: controller.selectedIndex.value,
              backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
              selectedItemColor: isDark ? AppThemeData.primary300 : AppThemeData.primary300,
              unselectedItemColor: isDark ? AppThemeData.grey300 : AppThemeData.grey600,
              onTap: (int index) {
                if (index == 0) {
                  Get.put(DashBoardController());
                }
                controller.selectedIndex.value = index;
              },
              items:
                  Constant.walletSetting == false
                      ? [
                        navigationBarItem(isDark, index: 0, assetIcon: "assets/icons/ic_home.svg", label: 'Home'.tr, controller: controller),
                        navigationBarItem(isDark, index: 1, assetIcon: "assets/icons/ic_fav.svg", label: 'Favourites'.tr, controller: controller),
                        navigationBarItem(isDark, index: 2, assetIcon: "assets/icons/ic_orders.svg", label: 'Orders'.tr, controller: controller),
                        navigationBarItem(isDark, index: 3, assetIcon: "assets/icons/ic_profile.svg", label: 'Profile'.tr, controller: controller),
                      ]
                      : [
                        navigationBarItem(isDark, index: 0, assetIcon: "assets/icons/ic_home.svg", label: 'Home'.tr, controller: controller),
                        navigationBarItem(isDark, index: 1, assetIcon: "assets/icons/ic_fav.svg", label: 'Favourites'.tr, controller: controller),
                        navigationBarItem(isDark, index: 2, assetIcon: "assets/icons/ic_wallet.svg", label: 'Wallet'.tr, controller: controller),
                        navigationBarItem(isDark, index: 3, assetIcon: "assets/icons/ic_orders.svg", label: 'Orders'.tr, controller: controller),
                        navigationBarItem(isDark, index: 4, assetIcon: "assets/icons/ic_profile.svg", label: 'Profile'.tr, controller: controller),
                      ],
            ),
          );
        },
      );
    });
  }

  BottomNavigationBarItem navigationBarItem(isDark, {required int index, required String label, required String assetIcon, required DashBoardController controller}) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: SvgPicture.asset(
          assetIcon,
          height: 22,
          width: 22,
          color:
              controller.selectedIndex.value == index
                  ? isDark
                      ? AppThemeData.primary300
                      : AppThemeData.primary300
                  : isDark
                  ? AppThemeData.grey300
                  : AppThemeData.grey600,
        ),
      ),
      label: label,
    );
  }
}
