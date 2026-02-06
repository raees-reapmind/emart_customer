import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/theme_controller.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/screen_ui/location_enable_screens/address_list_screen.dart';
import 'package:customer/screen_ui/service_home_screen/service_list_screen.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/widget/osm_map/map_picker_page.dart';
import 'package:customer/widget/place_picker/location_picker_screen.dart';
import 'package:customer/widget/place_picker/selected_location_model.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../constant/assets.dart';
import '../../utils/utils.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Image.asset(AppAssets.icLocation),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    "Enable Location for a Personalized Experience".tr,
                    style: AppThemeData.boldTextStyle(fontSize: 24, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: Text(
                    "Allow location access to discover beauty stores and services near you.".tr,
                    style: AppThemeData.mediumTextStyle(fontSize: 14, color: isDark ? AppThemeData.greyDark600 : AppThemeData.grey600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                RoundedButtonFill(
                  title: "Use current location".tr,
                  onPress: () async {
                    Constant.checkPermission(
                      context: context,
                      onTap: () async {
                        ShowToastDialog.showLoader("Please wait...".tr);
                        ShippingAddress addressModel = ShippingAddress();
                        try {
                          await Geolocator.requestPermission();
                          Position newLocalData = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                          await placemarkFromCoordinates(newLocalData.latitude, newLocalData.longitude).then((valuePlaceMaker) {
                            Placemark placeMark = valuePlaceMaker[0];
                            addressModel.addressAs = "Home";
                            addressModel.location = UserLocation(latitude: newLocalData.latitude, longitude: newLocalData.longitude);
                            String currentLocation =
                                "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                            addressModel.locality = currentLocation;
                          });

                          Constant.selectedLocation = addressModel;
                          Constant.currentLocation = await Utils.getCurrentLocation();

                          ShowToastDialog.closeLoader();

                          Get.offAll(const ServiceListScreen());
                        } catch (e) {
                          await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                            Placemark placeMark = valuePlaceMaker[0];
                            addressModel.addressAs = "Home";
                            addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                            String currentLocation =
                                "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                            addressModel.locality = currentLocation;
                          });

                          Constant.selectedLocation = addressModel;
                          Constant.currentLocation = await Utils.getCurrentLocation();

                          ShowToastDialog.closeLoader();

                          Get.offAll(const ServiceListScreen());
                        }
                      },
                    );
                  },
                  color: AppThemeData.grey900,
                  textColor: AppThemeData.grey50,
                ),
                const SizedBox(height: 10),
                RoundedButtonFill(
                  title: "Set from map".tr,
                  onPress: () async {
                    Constant.checkPermission(
                      context: context,
                      onTap: () async {
                        ShowToastDialog.showLoader("Please wait...".tr);
                        ShippingAddress addressModel = ShippingAddress();
                        try {
                          await Geolocator.requestPermission();
                          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                          ShowToastDialog.closeLoader();
                          if (Constant.selectedMapType == 'osm') {
                            final result = await Get.to(() => MapPickerPage());
                            if (result != null) {
                              final firstPlace = result;
                              final lat = firstPlace.coordinates.latitude;
                              final lng = firstPlace.coordinates.longitude;
                              final address = firstPlace.address;

                              addressModel.addressAs = "Home";
                              addressModel.locality = address.toString();
                              addressModel.location = UserLocation(latitude: lat, longitude: lng);
                              Constant.selectedLocation = addressModel;
                              Get.offAll(const ServiceListScreen());
                            }
                          } else {
                            Get.to(LocationPickerScreen())!.then((value) async {
                              if (value != null) {
                                SelectedLocationModel selectedLocationModel = value;

                                addressModel.addressAs = "Home";
                                addressModel.locality = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                addressModel.location = UserLocation(latitude: selectedLocationModel.latLng!.latitude, longitude: selectedLocationModel.latLng!.longitude);
                                Constant.selectedLocation = addressModel;

                                Get.offAll(const ServiceListScreen());
                              }
                            });
                          }
                        } catch (e) {
                          await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                            Placemark placeMark = valuePlaceMaker[0];
                            addressModel.addressAs = "Home";
                            addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                            String currentLocation =
                                "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                            addressModel.locality = currentLocation;
                          });

                          Constant.selectedLocation = addressModel;
                          ShowToastDialog.closeLoader();

                          Get.offAll(const ServiceListScreen());
                        }
                      },
                    );
                  },
                  color: AppThemeData.grey50,
                  textColor: AppThemeData.grey900,
                ),
                const SizedBox(height: 20),
                Constant.userModel == null
                    ? const SizedBox()
                    : GestureDetector(
                      onTap: () async {
                        Get.to(AddressListScreen())!.then((value) {
                          if (value != null) {
                            ShippingAddress addressModel = value;
                            Constant.selectedLocation = addressModel;
                            Get.offAll(const ServiceListScreen());
                          }
                        });
                      },
                      child: Text("Enter Manually location".tr, style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
