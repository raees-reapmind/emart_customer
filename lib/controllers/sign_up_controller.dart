import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/screen_ui/location_enable_screens/location_permission_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../constant/constant.dart';
import '../models/referral_model.dart';
import '../screen_ui/service_home_screen/service_list_screen.dart';
import '../service/fire_store_utils.dart';
import '../themes/show_toast_dialog.dart';
import '../utils/notification_service.dart';

class SignUpController extends GetxController {
  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> mobileController = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController = TextEditingController(text: Constant.defaultCountryCode).obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<TextEditingController> confirmPasswordController = TextEditingController().obs;
  Rx<TextEditingController> referralController = TextEditingController().obs;

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // State
  final RxBool isLoading = false.obs;
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;

  RxString type = "email".obs;
  Rx<UserModel> userModel = UserModel().obs;

  RxBool passwordVisible = true.obs;
  RxBool conformPasswordVisible = true.obs;

  @override
  void onInit() {
    super.onInit();
    getArgument();
  }

  void getArgument() {
    final args = Get.arguments;
    type.value = args?['type'] ?? 'email';
    userModel.value = args?['userModel'] ?? UserModel();

    //Pre-fill fields for Google/Apple signup
    if (type.value == "google" || type.value == "apple") {
      firstNameController.value.text = userModel.value.firstName ?? "";
      lastNameController.value.text = userModel.value.lastName ?? "";
      emailController.value.text = userModel.value.email ?? "";
    }

    //mobile number signup
    if (type.value == "mobileNumber") {
      mobileController.value.text = userModel.value.phoneNumber ?? "";
      countryCodeController.value.text = userModel.value.countryCode ?? "";
    }
  }

  /// Main Sign-Up Trigger
  void signUp() async {
    debugPrint("SIGNUP CALLED!");
    try {
      if (!_validateInputs()) return;

      ShowToastDialog.showLoader("Creating account...".tr);

      if (type.value == "mobileNumber") {
        await _signUpWithMobile();
      } else {
        await _signUpWithEmail();
      }

      ShowToastDialog.closeLoader();
    } catch (e, st) {
      ShowToastDialog.closeLoader();
      debugPrint("SIGNUP OUTER EXCEPTION: $e\n$st");
      ShowToastDialog.showToast("${'signup_failed'.tr}: $e");
    }
  }

  /// Validation Logic
  bool _validateInputs() {
    if (firstNameController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter first name".tr);
      return false;
    } else if (lastNameController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter last name".tr);
      return false;
    } else if (emailController.value.text.isEmpty || !emailController.value.text.isEmail) {
      ShowToastDialog.showToast("Please enter a valid email address".tr);
      return false;
    } else if (mobileController.value.text.isEmpty) {
      ShowToastDialog.showToast("Please enter a valid phone number".tr);
      return false;
    } else if (passwordController.value.text.length < 6) {
      ShowToastDialog.showToast("Password must be at least 6 characters".tr);
      return false;
    } else if (passwordController.value.text != confirmPasswordController.value.text) {
      ShowToastDialog.showToast("Password and Confirm password do not match".tr);
      return false;
    }
    return true;
  }

  /// Email Sign-up Flow
  Future<void> _signUpWithEmail() async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: emailController.value.text.trim(), password: passwordController.value.text.trim());

      if (credential.user != null) {
        final newUser = await _buildUserModel(credential.user?.uid ?? '');
        await _handleReferral(newUser.id ?? '');
        await FireStoreUtils.updateUser(newUser);
        // appController.currentUser.value = newUser;
        _navigateBasedOnAddress(newUser);
      }
    } on auth.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException caught: code=${e.code}, message=${e.message}");
      if (e.code == 'email-already-in-use') {
        ShowToastDialog.showToast("Email already in use".tr);
      } else if (e.code == 'weak-password') {
        ShowToastDialog.showToast("Password is too weak".tr);
      } else if (e.code == 'invalid-email') {
        ShowToastDialog.showToast("Invalid email address".tr);
      } else {
        ShowToastDialog.showToast(e.message ?? "signup_failed".tr);
      }
    } catch (e) {
      debugPrint("Something went wrong: ${e.toString()}");
      ShowToastDialog.showToast("${'something_went_wrong'.tr}: ${e.toString()}");
    }
  }

  /// Mobile Sign-up Flow
  Future<void> _signUpWithMobile() async {
    debugPrint("Signup with mobile called...");
    try {
      final uid = FireStoreUtils.getCurrentUid();

      userModel.value = await _buildUserModel(uid);

      await _handleReferral(uid);
      await FireStoreUtils.updateUser(userModel.value);

      _navigateBasedOnAddress(userModel.value);
    } catch (e) {
      ShowToastDialog.showToast("${'signup_failed'.tr}: $e");
    }
  }

  /// Construct UserModel
  Future<UserModel> _buildUserModel(String uid) async {
    final fcmToken = await NotificationService.getToken();

    return UserModel(
      id: uid,
      firstName: firstNameController.value.text.trim(),
      lastName: lastNameController.value.text.trim(),
      email: emailController.value.text.trim().toLowerCase(),
      phoneNumber: mobileController.value.text.trim(),
      countryCode: countryCodeController.value.text.trim(),
      fcmToken: fcmToken,
      active: true,
      createdAt: Timestamp.now(),
      role: Constant.userRoleCustomer,
    );
  }

  /// Handle Referral Logic
  Future<void> _handleReferral(String userId) async {
    final referralCode = referralController.value.text.trim();
    final referralBy = referralCode.isNotEmpty ? (await FireStoreUtils.getReferralUserByCode(referralCode))?.id ?? '' : '';

    final referral = ReferralModel(id: userId, referralBy: referralBy, referralCode: Constant.getReferralCode());

    await FireStoreUtils.referralAdd(referral);
  }

  /// Navigate Based on Shipping Address
  void _navigateBasedOnAddress(UserModel user) {
    if (user.shippingAddress?.isNotEmpty == true) {
      final defaultAddress = user.shippingAddress!.firstWhere((e) => e.isDefault == true, orElse: () => user.shippingAddress!.first);

      /// Save the default address to global constant
      Constant.selectedLocation = defaultAddress;

      Get.offAll(() => const ServiceListScreen());
    } else {
      Get.offAll(() => const LocationPermissionScreen());
    }
  }
}
