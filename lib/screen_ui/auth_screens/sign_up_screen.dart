import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/screen_ui/location_enable_screens/location_permission_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import '../../constant/constant.dart';
import '../../controllers/sign_up_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/text_field_widget.dart';
import 'package:get/get.dart';
import 'login_screen.dart';
import 'mobile_login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<SignUpController>(
      init: SignUpController(),
      builder: (controller) {
        final themeController = Get.find<ThemeController>();
        final isDark = themeController.isDark.value;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () {
                  Get.to(() => LocationPermissionScreen());
                },
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 40), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Skip".tr, style: AppThemeData.mediumTextStyle(color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sign up to explore all our services and start shopping, riding, and more.".tr,
                      style: AppThemeData.boldTextStyle(fontSize: 24, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: TextFieldWidget(title: "First Name*".tr, hintText: "Jerome".tr, controller: controller.firstNameController.value)),
                        const SizedBox(width: 10),
                        Expanded(child: TextFieldWidget(title: "Last Name*".tr, hintText: "Bell".tr, controller: controller.lastNameController.value)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextFieldWidget(
                      title: "Email Address*".tr,
                      hintText: "jerome014@gmail.com",
                      controller: controller.emailController.value,
                      focusNode: controller.emailFocusNode,
                    ),
                    const SizedBox(height: 15),
                    TextFieldWidget(
                      title: "Mobile Number*".tr,
                      hintText: "Enter Mobile number".tr,
                      enable: controller.type.value == "mobileNumber" ? false : true,
                      controller: controller.mobileController.value,
                      textInputType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]')), LengthLimitingTextInputFormatter(10)],
                      prefix: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountryCodePicker(
                            onChanged: (value) {
                              controller.countryCodeController.value.text = value.dialCode ?? Constant.defaultCountryCode;
                            },
                            initialSelection: controller.countryCodeController.value.text.isNotEmpty ? controller.countryCodeController.value.text : Constant.defaultCountryCode,
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            enabled: controller.type.value != "mobileNumber",
                            textStyle: TextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : Colors.black),
                            dialogTextStyle: TextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                            searchStyle: TextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                            dialogBackgroundColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
                            padding: EdgeInsets.zero,
                          ),
                          // const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AppThemeData.grey400),
                          Container(height: 24, width: 1, color: AppThemeData.grey400),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
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
                                  ? SvgPicture.asset(
                                    "assets/icons/ic_password_show.svg",
                                    colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn),
                                  )
                                  : SvgPicture.asset(
                                    "assets/icons/ic_password_close.svg",
                                    colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFieldWidget(
                      title: "Confirm Password*".tr,
                      hintText: "Enter confirm password".tr,
                      controller: controller.confirmPasswordController.value,
                      obscureText: controller.conformPasswordVisible.value,
                      suffix: Padding(
                        padding: const EdgeInsets.all(12),
                        child: InkWell(
                          onTap: () {
                            controller.conformPasswordVisible.value = !controller.conformPasswordVisible.value;
                          },
                          child:
                              controller.conformPasswordVisible.value
                                  ? SvgPicture.asset(
                                    "assets/icons/ic_password_show.svg",
                                    colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn),
                                  )
                                  : SvgPicture.asset(
                                    "assets/icons/ic_password_close.svg",
                                    colorFilter: ColorFilter.mode(isDark ? AppThemeData.grey300 : AppThemeData.grey600, BlendMode.srcIn),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFieldWidget(title: "Referral Code".tr, hintText: "Enter referral code".tr, controller: controller.referralController.value),
                    const SizedBox(height: 40),
                    RoundedButtonFill(
                      title: "Sign up".tr,
                      onPress: () => controller.signUp(),
                      color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                      textColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 52, height: 1, color: isDark ? AppThemeData.greyDark400 : AppThemeData.grey300),
                        const SizedBox(width: 15),
                        Text("or continue with".tr, style: AppThemeData.regularTextStyle(color: isDark ? AppThemeData.greyDark400 : AppThemeData.grey400)),
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
                      color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200,
                      textColor: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account?".tr,
                            style: AppThemeData.mediumTextStyle(color: isDark ? AppThemeData.greyDark800 : AppThemeData.grey800),
                            children: [
                              TextSpan(
                                text: "Log in".tr,
                                style: AppThemeData.mediumTextStyle(
                                  color: AppThemeData.ecommerce300,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppThemeData.ecommerce300,
                                  decorationStyle: TextDecorationStyle.solid,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Get.offAll(() => const LoginScreen());
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
          ),
        );
      },
    );
  }
}
