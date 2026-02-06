import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cab_home_controller.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/models/banner_model.dart';
import 'package:customer/screen_ui/auth_screens/login_screen.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'Intercity_home_screen.dart';
import 'cab_booking_screen.dart';

class CabHomeScreen extends StatelessWidget {
  const CabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: CabHomeController(),
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppThemeData.primary300,
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppThemeData.grey50),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Icon(Icons.arrow_back_ios, color: AppThemeData.grey900, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Constant.userModel == null
                            ? InkWell(
                              onTap: () {
                                Get.offAll(const LoginScreen());
                              },
                              child: Text(
                                "Login".tr,
                                textAlign: TextAlign.center,
                                style: AppThemeData.boldTextStyle(color: AppThemeData.grey900, fontSize: 12),
                              ),
                            )
                            : Text(
                              Constant.userModel!.fullName(),
                              textAlign: TextAlign.center,
                              style: AppThemeData.boldTextStyle(color: AppThemeData.grey900, fontSize: 12),
                            ),
                        Text(
                          Constant.selectedLocation.getFullAddress(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemeData.boldTextStyle(fontSize: 18, color: AppThemeData.grey900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BannerView(bannerList: controller.bannerTopHome),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20),
                            Text(
                              "Where are you going for?".tr,
                              style: AppThemeData.mediumTextStyle(
                                color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Constant.sectionConstantModel!.rideType == "both" || Constant.sectionConstantModel!.rideType == "ride"
                                    ? GestureDetector(
                                      onTap: () {
                                        Get.to(() => CabBookingScreen());
                                      },
                                      child: Container(
                                        width: Responsive.width(40, context),
                                        decoration: BoxDecoration(
                                          color: AppThemeData.warning50,
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: AppThemeData.warning200),
                                        ),
                                        padding: EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset("assets/icons/ic_ride.svg", height: 38, width: 38),
                                            SizedBox(height: 20),
                                            Text(
                                              "Ride".tr,
                                              style: AppThemeData.semiBoldTextStyle(color: AppThemeData.taxiBooking500, fontSize: 16),
                                            ),
                                            Text(
                                              "City rides, 24x7 availability".tr,
                                              style: AppThemeData.mediumTextStyle(color: AppThemeData.taxiBooking600, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    : SizedBox(),
                                SizedBox(width: 20),
                                Constant.sectionConstantModel!.rideType == "both" || Constant.sectionConstantModel!.rideType == "intercity"
                                    ? GestureDetector(
                                      onTap: () {
                                        Get.to(() => IntercityHomeScreen());
                                      },
                                      child: Container(
                                        width: Responsive.width(44, context),
                                        decoration: BoxDecoration(
                                          color: AppThemeData.carRent50,
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: AppThemeData.carRent200),
                                        ),
                                        padding: EdgeInsets.all(15),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset("assets/icons/ic_intercity.svg", height: 38, width: 38),
                                            SizedBox(height: 20),
                                            Text(
                                              "Intercity/Outstation".tr,
                                              style: AppThemeData.semiBoldTextStyle(color: AppThemeData.carRent500, fontSize: 16),
                                            ),
                                            Text(
                                              "Long trips, prepaid options".tr,
                                              style: AppThemeData.mediumTextStyle(color: AppThemeData.parcelService600, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    : SizedBox(),
                              ],
                            ),
                            SizedBox(height: 30),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Every Ride. Every Driver. Verified.".tr,
                                        style: AppThemeData.boldTextStyle(
                                          color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900,
                                          fontSize: 22,
                                        ),
                                      ),
                                      Text(
                                        "All drivers go through ID checks and background verification for your safety.".tr,
                                        style: AppThemeData.mediumTextStyle(
                                          color: isDark ? AppThemeData.greyDark700 : AppThemeData.grey700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(child: Image.asset("assets/images/img_ride_driver.png", height: 118, width: 68)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}

class BannerView extends StatelessWidget {
  final List<BannerModel> bannerList;
  final RxInt currentPage = 0.obs;
  final ScrollController scrollController = ScrollController();

  BannerView({super.key, required this.bannerList});

  /// Computes the visible item index from scroll offset
  void onScroll(BuildContext context) {
    if (scrollController.hasClients && bannerList.isNotEmpty) {
      final screenWidth = MediaQuery.of(context).size.width;
      final itemWidth = screenWidth * 0.8 + 10; // banner width + spacing
      final offset = scrollController.offset;
      final index = (offset / itemWidth).round();

      if (index != currentPage.value && index < bannerList.length) {
        currentPage.value = index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    scrollController.addListener(() {
      onScroll(context);
    });

    return bannerList.isEmpty
        ? SizedBox()
        : Column(
          children: [
            SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: bannerList.length,
                separatorBuilder: (context, index) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final banner = bannerList[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: NetworkImageWidget(imageUrl: banner.photo ?? '', fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              return Row(
                children: List.generate(bannerList.length, (index) {
                  bool isSelected = currentPage.value == index;
                  return Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? AppThemeData.grey300 : AppThemeData.grey100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        );
  }
}
