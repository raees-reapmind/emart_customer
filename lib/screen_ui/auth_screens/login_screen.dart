import 'dart:io';

import 'package:customer/screen_ui/auth_screens/sign_up_screen.dart';
import 'package:customer/screen_ui/location_enable_screens/location_permission_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../controllers/login_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/text_field_widget.dart';
import 'package:get/get.dart';
import 'forgot_password_screen.dart';
import 'mobile_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<LoginController>(
      init: LoginController(),
      builder: (controller) {
        final themeController = Get.find<ThemeController>();
        final isDark = themeController.isDark.value;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () {
                  Get.to(() => LocationPermissionScreen());
                },
                child: Row(
                  children: [
                    Text("Skip".tr, style: AppThemeData.mediumTextStyle(color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                    Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            "Log in to explore your all in one vendor app favourites and shop effortlessly.".tr,
                            style: AppThemeData.boldTextStyle(fontSize: 24, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                          ),
                          const SizedBox(height: 24),
                          TextFieldWidget(title: "Email Address*".tr, hintText: "jerome014@gmail.com", controller: controller.emailController.value, focusNode: controller.emailFocusNode),
                          const SizedBox(height: 15),
                          TextFieldWidget(
                            title: "Password*".tr,
                            hintText: "Enter password".tr,
                            controller: controller.passwordController.value,
                            obscureText: controller.passwordVisible.value,
                            focusNode: controller.passwordFocusNode,
                            suffix: Padding(
                              padding: const EdgeInsets.all(12),
                              child: InkWell(
                                onTap: () {
                                  controller.passwordVisible.value = !controller.passwordVisible.value;
                                },
                                child:
                                    controller.passwordVisible.value
                                        ? SvgPicture.asset("assets/icons/ic_password_show.svg", colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn))
                                        : SvgPicture.asset("assets/icons/ic_password_close.svg", colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn)),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Get.to(() => const ForgotPasswordScreen()),
                              child: Text("Forgot Password".tr, style: AppThemeData.semiBoldTextStyle(color: AppThemeData.info400)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RoundedButtonFill(
                            title: "Log in".tr,
                            onPress: controller.loginWithEmail,
                            color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                            textColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 52, height: 1, color: isDark ? AppThemeData.greyDark400 : AppThemeData.grey300),
                              const SizedBox(width: 15),
                              Text("or continue with".tr, style: AppThemeData.regularTextStyle(color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900.withOpacity(0.6))),
                              const SizedBox(width: 15),
                              Container(width: 52, height: 1, color: isDark ? AppThemeData.greyDark400 : AppThemeData.grey300),
                            ],
                          ),
                          const SizedBox(height: 25),
                          RoundedButtonFill(
                            title: "Mobile number".tr,
                            onPress: () => Get.to(() => const MobileLoginScreen()),
                            isRight: false,
                            isCenter: true,
                            icon: Icon(Icons.mobile_friendly_outlined, size: 20, color: isDark ? AppThemeData.greyDark900 : null),
                            //Image.asset(AppAssets.icMessage, width: 20, height: 18, color: isDark ? AppThemeData.greyDark900 : null),
                            color: isDark ? AppThemeData.greyDark400 : AppThemeData.grey300,
                            textColor: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RoundedButtonFill(
                                  title: "with Google".tr,
                                  textColor: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                                  color: isDark ? AppThemeData.grey900 : AppThemeData.grey100,
                                  icon: SvgPicture.asset("assets/icons/ic_google.svg"),
                                  isRight: false,
                                  isCenter: true,
                                  onPress: () async {
                                    controller.loginWithGoogle();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Platform.isIOS
                                  ? Expanded(
                                    child: RoundedButtonFill(
                                      title: "with Apple".tr,
                                      isCenter: true,
                                      textColor: isDark ? AppThemeData.grey100 : AppThemeData.grey900,
                                      color: isDark ? AppThemeData.grey900 : AppThemeData.grey100,
                                      icon: SvgPicture.asset("assets/icons/ic_apple.svg"),
                                      isRight: false,
                                      onPress: () async {
                                        controller.loginWithApple();
                                      },
                                    ),
                                  )
                                  : const SizedBox(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Didn't have an account?".tr,
                          style: AppThemeData.mediumTextStyle(color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                          children: [
                            TextSpan(
                              text: "Sign up".tr,
                              style: AppThemeData.mediumTextStyle(color: AppThemeData.ecommerce300, decoration: TextDecoration.underline),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.offAll(() => const SignUpScreen());
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
