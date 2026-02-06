import 'package:customer/constant/constant.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../controllers/theme_controller.dart';

class TermsAndConditionScreen extends StatelessWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return Scaffold(
      backgroundColor: isDark ? AppThemeData.grey50 : AppThemeData.grey50,
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(Icons.chevron_left_outlined, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
        ),
        title: Text(
          type == "privacy" ? "Privacy Policy".tr : "Terms & Conditions".tr,
          style: TextStyle(color: isDark ? AppThemeData.grey100 : AppThemeData.grey800, fontFamily: AppThemeData.bold, fontSize: 18),
        ),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4.0), child: Container(color: isDark ? AppThemeData.grey700 : AppThemeData.grey200, height: 4.0)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SingleChildScrollView(child: Html(shrinkWrap: true, data: type == "privacy" ? Constant.privacyPolicy : Constant.termsAndConditions)),
      ),
    );
  }
}
