import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/controllers/Intercity_home_controller.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/models/vehicle_type.dart';
import 'package:customer/payment/createRazorPayOrderModel.dart';
import 'package:customer/payment/rozorpayConroller.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_coupon_code_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_border.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart' as get_cord_address;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:location/location.dart';
import '../../constant/constant.dart';
import '../../controllers/cab_dashboard_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/user_model.dart';
import '../../service/fire_store_utils.dart';
import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/show_toast_dialog.dart';
import '../../themes/text_field_widget.dart';
import '../../widget/osm_map/map_picker_page.dart';
import '../../widget/place_picker/location_picker_screen.dart';
import '../../widget/place_picker/selected_location_model.dart';

class IntercityHomeScreen extends StatelessWidget {
  const IntercityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return GetX(
      init: IntercityHomeController(),
      builder: (controller) {
        return Scaffold(
          body:
              controller.isLoading.value
                  ? Constant.loader()
                  : Stack(
                    children: [
                      Constant.selectedMapType == "osm"
                          ? flutterMap.FlutterMap(
                            mapController: controller.mapOsmController,
                            options: flutterMap.MapOptions(
                              initialCenter:
                                  Constant.currentLocation != null
                                      ? latlong.LatLng(Constant.currentLocation!.latitude, Constant.currentLocation!.longitude)
                                      : controller.currentOrder.value.id != null
                                      ? latlong.LatLng(
                                        double.parse(controller.currentOrder.value.sourceLocation!.latitude.toString()),
                                        double.parse(controller.currentOrder.value.sourceLocation!.longitude.toString()),
                                      )
                                      : latlong.LatLng(41.4219057, -102.0840772),
                              initialZoom: 14,
                            ),
                            children: [
                              flutterMap.TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: Platform.isAndroid ? "com.emart" : "com.emart.ios"),
                              flutterMap.MarkerLayer(markers: controller.osmMarker),
                              if (controller.routePoints.isNotEmpty) flutterMap.PolylineLayer(polylines: [flutterMap.Polyline(points: controller.routePoints, strokeWidth: 5.0, color: Colors.blue)]),
                            ],
                          )
                          : GoogleMap(
                            onMapCreated: (googleMapController) {
                              controller.mapController = googleMapController;

                              if (Constant.currentLocation != null) {
                                controller.setDepartureMarker(Constant.currentLocation!.latitude, Constant.currentLocation!.longitude);
                                controller.searchPlaceNameGoogle();
                              }
                            },
                            initialCameraPosition: CameraPosition(target: controller.currentPosition.value, zoom: 14),
                            myLocationEnabled: true,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            polylines: Set<Polyline>.of(controller.polyLines.values),
                            markers: controller.markers.toSet(), // reactive marker set
                          ),
                      Positioned(
                        top: 50,
                        left: Constant.isRtl ? null : 20,
                        right: Constant.isRtl ? 20 : null,
                        child: InkWell(
                          onTap: () {
                            if (controller.bottomSheetType.value == "vehicleSelection") {
                              controller.bottomSheetType.value = "location";
                            } else if (controller.bottomSheetType.value == "payment") {
                              controller.bottomSheetType.value = "vehicleSelection";
                            } else if (controller.bottomSheetType.value == "conformRide") {
                              controller.bottomSheetType.value = "payment";
                            } else if (controller.bottomSheetType.value == "waitingDriver" || controller.bottomSheetType.value == "driverDetails") {
                              Get.back(result: true);
                            } else {
                              Get.back();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50, borderRadius: BorderRadius.circular(30)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(child: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? AppThemeData.grey50 : AppThemeData.greyDark50)),
                            ),
                          ),
                        ),
                      ),
                      controller.bottomSheetType.value == "location"
                          ? searchLocationBottomSheet(context, controller, isDark)
                          : controller.bottomSheetType.value == "vehicleSelection"
                          ? vehicleSelection(context, controller, isDark)
                          : controller.bottomSheetType.value == "payment"
                          ? paymentBottomSheet(context, controller, isDark)
                          : controller.bottomSheetType.value == "conformRide"
                          ? conformBottomSheet(context, isDark)
                          : controller.bottomSheetType.value == "waitingForDriver"
                          ? waitingDialog(context, controller, isDark)
                          : controller.bottomSheetType.value == "driverDetails"
                          ? driverDialog(context, controller, isDark)
                          : SizedBox(),
                    ],
                  ),
        );
      },
    );
  }

  Widget searchLocationBottomSheet(BuildContext context, IntercityHomeController controller, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.48,
        minChildSize: 0.48,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.grey400), height: 4, width: 33),
                SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pickup Location
                          InkWell(
                            onTap: () async {
                              if (Constant.selectedMapType == 'osm') {
                                final result = await Get.to(() => MapPickerPage());
                                controller.sourceTextEditController.value.text = '';
                                final firstPlace = result;
                                if (result != null) {
                                  if (Constant.checkZoneCheck(firstPlace.coordinates.latitude, firstPlace.coordinates.longitude) == true) {
                                    final lat = firstPlace.coordinates.latitude;
                                    final lng = firstPlace.coordinates.longitude;
                                    final address = firstPlace.address;
                                    controller.sourceTextEditController.value.text = address.toString();
                                    controller.setDepartureMarker(lat, lng);
                                  } else {
                                    ShowToastDialog.showToast("Service is unavailable at the selected address.".tr);
                                  }
                                }
                              } else {
                                Get.to(LocationPickerScreen())!.then((value) async {
                                  if (value != null) {
                                    SelectedLocationModel selectedLocationModel = value;

                                    if (Constant.checkZoneCheck(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude) == true) {
                                      controller.sourceTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                      controller.setDepartureMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                    } else {
                                      ShowToastDialog.showToast("Service is unavailable at the selected address.".tr);
                                    }
                                  }
                                });
                              }
                            },
                            child: TextFieldWidget(
                              controller: controller.sourceTextEditController.value,
                              hintText: "Pickup Location".tr,
                              enable: false,
                              prefix: Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Image.asset("assets/icons/pickup.png", height: 22, width: 22)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Destination Location
                          InkWell(
                            onTap: () async {
                              if (Constant.selectedMapType == 'osm') {
                                final result = await Get.to(() => MapPickerPage());
                                if (result != null) {
                                  controller.destinationTextEditController.value.text = '';
                                  final firstPlace = result;
                                  final lat = firstPlace.coordinates.latitude;
                                  final lng = firstPlace.coordinates.longitude;
                                  final address = firstPlace.address;
                                  controller.destinationTextEditController.value.text = address.toString();
                                  controller.setDestinationMarker(lat, lng);
                                }
                              } else {
                                Get.to(LocationPickerScreen())!.then((value) async {
                                  if (value != null) {
                                    SelectedLocationModel selectedLocationModel = value;

                                    controller.destinationTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                    controller.setDestinationMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                  }
                                });
                              }
                            },
                            child: TextFieldWidget(
                              controller: controller.destinationTextEditController.value,
                              // backgroundColor: AppThemeData.grey50,
                              // borderColor: AppThemeData.grey50,
                              hintText: "Destination Location".tr,
                              enable: false,
                              prefix: const Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Icon(Icons.radio_button_checked, color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 33,
                      child: DottedBorder(
                        options: CustomPathDottedBorderOptions(
                          color: Colors.grey.shade400,
                          strokeWidth: 2,
                          dashPattern: [4, 4],
                          customPath:
                              (size) =>
                                  Path()
                                    ..moveTo(size.width / 2, 0)
                                    ..lineTo(size.width / 2, size.height),
                        ),
                        child: const SizedBox(width: 20, height: 40),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Align(alignment: Alignment.centerLeft, child: Text("Popular Destinations".tr, style: AppThemeData.boldTextStyle(fontSize: 16, color: AppThemeData.grey900))),
                SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: controller.popularDestination.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () async {
                            if (controller.popularDestination[index].latitude != null || controller.popularDestination[index].longitude != null) {
                              List<get_cord_address.Placemark> placeMarks = await get_cord_address.placemarkFromCoordinates(
                                controller.popularDestination[index].latitude ?? 0.0,
                                controller.popularDestination[index].longitude ?? 0.0,
                              );

                              final address =
                                  (placeMarks.first.subLocality!.isEmpty ? '' : "${placeMarks.first.subLocality}, ") +
                                  (placeMarks.first.street!.isEmpty ? '' : "${placeMarks.first.street}, ") +
                                  (placeMarks.first.name!.isEmpty ? '' : "${placeMarks.first.name}, ") +
                                  (placeMarks.first.subAdministrativeArea!.isEmpty ? '' : "${placeMarks.first.subAdministrativeArea}, ") +
                                  (placeMarks.first.administrativeArea!.isEmpty ? '' : "${placeMarks.first.administrativeArea}, ") +
                                  (placeMarks.first.country!.isEmpty ? '' : "${placeMarks.first.country}, ") +
                                  (placeMarks.first.postalCode!.isEmpty ? '' : "${placeMarks.first.postalCode}, ");
                              controller.destinationTextEditController.value.text = address;
                              controller.setDestinationMarker(controller.popularDestination[index].latitude ?? 0.0, controller.popularDestination[index].longitude ?? 0.0);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      (controller.popularDestination[index].image != null && controller.popularDestination[index].image!.isNotEmpty)
                                          ? controller.popularDestination[index].image!
                                          : Constant.placeHolderImage,
                                  height: 160,
                                  width: 120,
                                  imageBuilder:
                                      (context, imageProvider) =>
                                          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: imageProvider, fit: BoxFit.cover))),
                                  placeholder: (context, url) => Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(AppThemeData.primary300))),
                                  errorWidget:
                                      (context, url, error) =>
                                          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(Constant.placeHolderImage, fit: BoxFit.cover, cacheHeight: 80, cacheWidth: 80)),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  left: 5,
                                  top: 80,
                                  child: Text(controller.popularDestination[index].title.toString(), style: AppThemeData.boldTextStyle(fontSize: 15, color: AppThemeData.surface)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                RoundedButtonFill(
                  title: "Continue".tr,
                  onPress: () {
                    if (controller.sourceTextEditController.value.text.isEmpty) {
                      ShowToastDialog.showToast("Please select source location".tr);
                    } else if (controller.destinationTextEditController.value.text.isEmpty) {
                      ShowToastDialog.showToast("Please select destination location".tr);
                    } else {
                      controller.bottomSheetType.value = "vehicleSelection";
                    }
                  },
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey900,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget vehicleSelection(BuildContext context, IntercityHomeController controller, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.40,
        minChildSize: 0.40,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.grey400), height: 4, width: 33),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Select Your Vehicle Type".tr,
                        style: AppThemeData.boldTextStyle(fontSize: 18, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: controller.vehicleTypes.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: 20),
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        VehicleType vehicleType = controller.vehicleTypes[index];
                        return Obx(
                          () => InkWell(
                            onTap: () {
                              controller.selectedVehicleType.value = controller.vehicleTypes[index];
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? controller.selectedVehicleType.value.id == vehicleType.id
                                                ? Colors.white
                                                : AppThemeData.grey500
                                            : controller.selectedVehicleType.value.id == vehicleType.id
                                            ? AppThemeData.grey300
                                            : Colors.transparent,
                                    width: 1,
                                  ),
                                  color:
                                      controller.selectedVehicleType.value.id == vehicleType.id
                                          ? AppThemeData.grey50
                                          : isDark
                                          ? AppThemeData.grey300
                                          : Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        //borderRadius: BorderRadius.circular(10),
                                        child: CachedNetworkImage(
                                          imageUrl: vehicleType.vehicleIcon.toString(),
                                          height: 60,
                                          width: 60,
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), image: DecorationImage(image: imageProvider, fit: BoxFit.cover))),
                                          placeholder: (context, url) => Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(AppThemeData.primary300))),
                                          errorWidget: (context, url, error) => ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(Constant.userPlaceHolder, fit: BoxFit.cover)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${vehicleType.name} | ${controller.distance.toStringAsFixed(2)}km",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0),
                                                child: Text(controller.duration.value, style: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 1)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(amount: controller.getAmount(vehicleType).toString()),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Obx(
                    () => RoundedButtonFill(
                      title: 'pay_amount'.trParams({
                        'amount':
                            controller.selectedVehicleType.value.id == null
                                ? Constant.amountShow(amount: "0.0")
                                : Constant.amountShow(amount: controller.getAmount(controller.selectedVehicleType.value).toString()),
                      }),
                      // title:
                      // "Pay ${controller.selectedVehicleType.value.id == null ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.getAmount(controller.selectedVehicleType.value).toString())}",
                      onPress: () async {
                        if (controller.selectedVehicleType.value.id != null) {
                          controller.calculateTotalAmount();
                          controller.bottomSheetType.value = "payment";
                        } else {
                          ShowToastDialog.showToast("Please select a vehicle type first.".tr);
                        }
                      },
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget paymentBottomSheet(BuildContext context, IntercityHomeController controller, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.70,
        minChildSize: 0.30,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Select Payment Method".tr, style: AppThemeData.mediumTextStyle(fontSize: 18, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Icon(Icons.close, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    children: [
                      Text("Preferred Payment".tr, textAlign: TextAlign.start, style: AppThemeData.boldTextStyle(fontSize: 15, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500)),
                      const SizedBox(height: 10),
                      if (controller.walletSettingModel.value.isEnabled == true || controller.cashOnDeliverySettingModel.value.isEnabled == true)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AppThemeData.greyDark100 : AppThemeData.grey50,
                            border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Visibility(
                                  visible: controller.walletSettingModel.value.isEnabled == true,
                                  child: cardDecoration(controller, PaymentGateway.wallet, isDark, "assets/images/ic_wallet.png"),
                                ),
                                Visibility(
                                  visible: controller.cashOnDeliverySettingModel.value.isEnabled == true,
                                  child: cardDecoration(controller, PaymentGateway.cod, isDark, "assets/images/ic_cash.png"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (controller.walletSettingModel.value.isEnabled == true || controller.cashOnDeliverySettingModel.value.isEnabled == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Other Payment Options".tr,
                              textAlign: TextAlign.start,
                              style: AppThemeData.boldTextStyle(fontSize: 15, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: isDark ? AppThemeData.greyDark100 : AppThemeData.grey50,
                          border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Visibility(visible: controller.stripeModel.value.isEnabled == true, child: cardDecoration(controller, PaymentGateway.stripe, isDark, "assets/images/stripe.png")),
                              Visibility(visible: controller.payPalModel.value.isEnabled == true, child: cardDecoration(controller, PaymentGateway.paypal, isDark, "assets/images/paypal.png")),
                              Visibility(visible: controller.payStackModel.value.isEnable == true, child: cardDecoration(controller, PaymentGateway.payStack, isDark, "assets/images/paystack.png")),
                              Visibility(
                                visible: controller.mercadoPagoModel.value.isEnabled == true,
                                child: cardDecoration(controller, PaymentGateway.mercadoPago, isDark, "assets/images/mercado-pago.png"),
                              ),
                              Visibility(
                                visible: controller.flutterWaveModel.value.isEnable == true,
                                child: cardDecoration(controller, PaymentGateway.flutterWave, isDark, "assets/images/flutterwave_logo.png"),
                              ),
                              Visibility(visible: controller.payFastModel.value.isEnable == true, child: cardDecoration(controller, PaymentGateway.payFast, isDark, "assets/images/payfast.png")),
                              Visibility(visible: controller.razorPayModel.value.isEnabled == true, child: cardDecoration(controller, PaymentGateway.razorpay, isDark, "assets/images/razorpay.png")),
                              Visibility(visible: controller.midTransModel.value.enable == true, child: cardDecoration(controller, PaymentGateway.midTrans, isDark, "assets/images/midtrans.png")),
                              Visibility(
                                visible: controller.orangeMoneyModel.value.enable == true,
                                child: cardDecoration(controller, PaymentGateway.orangeMoney, isDark, "assets/images/orange_money.png"),
                              ),
                              Visibility(visible: controller.xenditModel.value.enable == true, child: cardDecoration(controller, PaymentGateway.xendit, isDark, "assets/images/xendit.png")),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                RoundedButtonFill(
                  title: "Continue".tr,
                  color: AppThemeData.primary300,
                  textColor: AppThemeData.grey900,
                  onPress: () async {
                    if (controller.selectedPaymentMethod.value.isEmpty) {
                      ShowToastDialog.showToast("Please select a payment method".tr);
                      return;
                    }
                    if (controller.selectedPaymentMethod.value == "wallet") {
                      num walletAmount = controller.userModel.value.walletAmount ?? 0;
                      if (walletAmount <= 0) {
                        ShowToastDialog.showToast("Insufficient wallet balance. Please select another payment method.".tr);
                        return;
                      }
                    }
                    if (controller.currentOrder.value.id != null) {
                      controller.bottomSheetType.value = "driverDetails";
                    } else {
                      controller.bottomSheetType.value = "conformRide";
                    }
                  },
                ),
                // RoundedButtonFill(
                //   title: "Continue".tr,
                //   color: AppThemeData.primary300,
                //   textColor: AppThemeData.grey900,
                //   onPress: () async {
                //     if (controller.selectedPaymentMethod.value.isEmpty) {
                //       ShowToastDialog.showToast("Please select a payment method");
                //     } else {
                //       if (controller.currentOrder.value.id != null) {
                //         controller.bottomSheetType.value = "driverDetails";
                //       } else {
                //         controller.bottomSheetType.value = "conformRide";
                //       }
                //     }
                //   },
                // ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget conformBottomSheet(BuildContext context, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return GetX(
            init: IntercityHomeController(),
            builder: (controller) {
              return Container(
                decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.grey400), height: 4, width: 33),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 10),
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(color: isDark ? Colors.transparent : Colors.white, borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pickup Location
                                      InkWell(
                                        onTap: () async {
                                          if (Constant.selectedMapType == 'osm') {
                                            final result = await Get.to(() => MapPickerPage());
                                            if (result != null) {
                                              controller.sourceTextEditController.value.text = '';
                                              final firstPlace = result;
                                              final lat = firstPlace.coordinates.latitude;
                                              final lng = firstPlace.coordinates.longitude;
                                              final address = firstPlace.address;
                                              controller.sourceTextEditController.value.text = address.toString();
                                              controller.setDepartureMarker(lat, lng);
                                            }
                                          } else {
                                            Get.to(LocationPickerScreen())!.then((value) async {
                                              if (value != null) {
                                                SelectedLocationModel selectedLocationModel = value;

                                                controller.sourceTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                                controller.setDepartureMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                              }
                                            });
                                          }
                                        },
                                        child: TextFieldWidget(
                                          controller: controller.sourceTextEditController.value,
                                          hintText: "Pickup Location".tr,
                                          enable: false,
                                          prefix: const Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Icon(Icons.stop_circle_outlined, color: Colors.green)),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // Destination Location
                                      InkWell(
                                        onTap: () async {
                                          if (Constant.selectedMapType == 'osm') {
                                            final result = await Get.to(() => MapPickerPage());
                                            if (result != null) {
                                              controller.destinationTextEditController.value.text = '';
                                              final firstPlace = result;
                                              final lat = firstPlace.coordinates.latitude;
                                              final lng = firstPlace.coordinates.longitude;
                                              final address = firstPlace.address;
                                              controller.destinationTextEditController.value.text = address.toString();
                                              controller.setDestinationMarker(lat, lng);
                                            }
                                          } else {
                                            Get.to(LocationPickerScreen())!.then((value) async {
                                              if (value != null) {
                                                SelectedLocationModel selectedLocationModel = value;

                                                controller.destinationTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                                controller.setDestinationMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                              }
                                            });
                                          }
                                        },
                                        child: TextFieldWidget(
                                          controller: controller.destinationTextEditController.value,
                                          // backgroundColor: AppThemeData.grey50,
                                          // borderColor: AppThemeData.grey50,
                                          hintText: "Destination Location".tr,
                                          enable: false,
                                          prefix: const Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Icon(Icons.radio_button_checked, color: Colors.red)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  top: 33,
                                  child: DottedBorder(
                                    options: CustomPathDottedBorderOptions(
                                      color: Colors.grey.shade400,
                                      strokeWidth: 2,
                                      dashPattern: [4, 4],
                                      customPath:
                                          (size) =>
                                              Path()
                                                ..moveTo(size.width / 2, 0)
                                                ..lineTo(size.width / 2, size.height),
                                    ),
                                    child: const SizedBox(width: 20, height: 40),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(child: Text("Promo code".tr, style: AppThemeData.boldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900))),
                                InkWell(
                                  onTap: () {
                                    Get.to(CabCouponCodeScreen())!.then((value) {
                                      if (value != null) {
                                        double couponAmount = Constant.calculateDiscount(amount: controller.subTotal.value.toString(), offerModel: value);
                                        if (couponAmount < controller.subTotal.value) {
                                          controller.selectedCouponModel.value = value;
                                          controller.calculateTotalAmount();
                                        } else {
                                          ShowToastDialog.showToast("This offer not eligible for this booking".tr);
                                        }
                                      }
                                    });
                                  },
                                  child: Text(
                                    "View All".tr,
                                    style: AppThemeData.boldTextStyle(decoration: TextDecoration.underline, fontSize: 14, color: isDark ? AppThemeData.primary300 : AppThemeData.primary300),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: Responsive.width(100, context),
                                height: Responsive.height(6, context),
                                color: AppThemeData.carRent50,
                                child: DottedBorder(
                                  options: RectDottedBorderOptions(dashPattern: [10, 5], strokeWidth: 1, padding: EdgeInsets.all(0), color: AppThemeData.carRent400),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset("assets/icons/ic_coupon.svg"),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: TextFormField(
                                              controller: controller.couponCodeTextEditController.value,
                                              style: AppThemeData.semiBoldTextStyle(color: AppThemeData.parcelService500, fontSize: 16),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Write coupon Code'.tr,
                                                contentPadding: EdgeInsets.only(bottom: 10),
                                                hintStyle: AppThemeData.semiBoldTextStyle(color: AppThemeData.parcelService500, fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        RoundedButtonFill(
                                          title: "Redeem now".tr,
                                          width: 27,
                                          borderRadius: 10,
                                          fontSizes: 14,
                                          onPress: () async {
                                            if (controller.cabCouponList
                                                .where((element) => element.code!.toLowerCase() == controller.couponCodeTextEditController.value.text.toLowerCase())
                                                .isNotEmpty) {
                                              CouponModel couponModel = controller.cabCouponList.firstWhere(
                                                (p0) => p0.code!.toLowerCase() == controller.couponCodeTextEditController.value.text.toLowerCase(),
                                              );
                                              if (couponModel.expiresAt!.toDate().isAfter(DateTime.now())) {
                                                double couponAmount = Constant.calculateDiscount(amount: controller.subTotal.value.toString(), offerModel: couponModel);
                                                if (couponAmount < controller.subTotal.value) {
                                                  controller.selectedCouponModel.value = couponModel;
                                                  controller.calculateTotalAmount();
                                                  controller.update();
                                                } else {
                                                  ShowToastDialog.showToast("This offer not eligible for this booking".tr);
                                                }
                                              } else {
                                                ShowToastDialog.showToast("This coupon code has been expired".tr);
                                              }
                                            } else {
                                              ShowToastDialog.showToast("Invalid coupon code".tr);
                                            }
                                          },
                                          color: AppThemeData.parcelService300,
                                          textColor: AppThemeData.grey50,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50,
                                border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Order Summary".tr, style: AppThemeData.boldTextStyle(fontSize: 14, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500)),
                                  const SizedBox(height: 8),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Subtotal".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                        Text(
                                          Constant.amountShow(amount: controller.subTotal.value.toString()),
                                          style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text("Discount".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                            SizedBox(width: 5),
                                            Text(
                                              controller.selectedCouponModel.value.id == null ? "" : "(${controller.selectedCouponModel.value.code})",
                                              style: AppThemeData.mediumTextStyle(fontSize: 16, color: AppThemeData.primary300),
                                            ),
                                          ],
                                        ),
                                        Text(Constant.amountShow(amount: controller.discount.value.toString()), style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: AppThemeData.danger300)),
                                      ],
                                    ),
                                  ),

                                  // Tax List
                                  ListView.builder(
                                    itemCount: Constant.taxList.length,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (context, index) {
                                      TaxModel taxModel = Constant.taxList[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${taxModel.title} (${taxModel.tax} ${taxModel.type == "Fixed" ? Constant.currencyData!.code : "%"})'.tr,
                                                textAlign: TextAlign.start,
                                                style: AppThemeData.mediumTextStyle(fontSize: 14, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                              ),
                                            ),
                                            Text(
                                              Constant.amountShow(
                                                amount: Constant.calculateTax(amount: (controller.subTotal.value - controller.discount.value).toString(), taxModel: taxModel).toString(),
                                              ).tr,
                                              textAlign: TextAlign.start,
                                              style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const Divider(),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Order Total".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                        Text(
                                          Constant.amountShow(amount: controller.totalAmount.value.toString()),
                                          style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50,
                                border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  controller.selectedPaymentMethod.value == ''
                                      ? cardDecorationScreen(controller, PaymentGateway.wallet, isDark, "")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.wallet.name
                                      ? cardDecorationScreen(controller, PaymentGateway.wallet, isDark, "assets/images/ic_wallet.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.cod.name
                                      ? cardDecorationScreen(controller, PaymentGateway.cod, isDark, "assets/images/ic_cash.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.stripe.name
                                      ? cardDecorationScreen(controller, PaymentGateway.stripe, isDark, "assets/images/stripe.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.paypal.name
                                      ? cardDecorationScreen(controller, PaymentGateway.paypal, isDark, "assets/images/paypal.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.payStack.name
                                      ? cardDecorationScreen(controller, PaymentGateway.payStack, isDark, "assets/images/paystack.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.mercadoPago.name
                                      ? cardDecorationScreen(controller, PaymentGateway.mercadoPago, isDark, "assets/images/mercado-pago.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.flutterWave.name
                                      ? cardDecorationScreen(controller, PaymentGateway.flutterWave, isDark, "assets/images/flutterwave_logo.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.payFast.name
                                      ? cardDecorationScreen(controller, PaymentGateway.payFast, isDark, "assets/images/payfast.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.midTrans.name
                                      ? cardDecorationScreen(controller, PaymentGateway.midTrans, isDark, "assets/images/midtrans.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.orangeMoney.name
                                      ? cardDecorationScreen(controller, PaymentGateway.orangeMoney, isDark, "assets/images/orange_money.png")
                                      : controller.selectedPaymentMethod.value == PaymentGateway.xendit.name
                                      ? cardDecorationScreen(controller, PaymentGateway.xendit, isDark, "assets/images/xendit.png")
                                      : cardDecorationScreen(controller, PaymentGateway.razorpay, isDark, "assets/images/razorpay.png"),
                                  SizedBox(width: 22),
                                  Text(
                                    controller.selectedPaymentMethod.value.tr,
                                    textAlign: TextAlign.start,
                                    style: AppThemeData.boldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      RoundedButtonFill(
                        title: "Confirm Booking".tr,
                        onPress: () async {
                          controller.placeOrder();
                        },
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey900,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget waitingDialog(BuildContext context, IntercityHomeController controller, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.4,
        maxChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.grey400), height: 4, width: 33),
                  SizedBox(height: 30),
                  Text("Waiting for driver....".tr, style: AppThemeData.mediumTextStyle(fontSize: 18, color: AppThemeData.grey900)),
                  Image.asset('assets/loader.gif', width: 250),
                  RoundedButtonFill(
                    title: "Cancel Ride".tr,
                    onPress: () async {
                      try {
                        // 1. Update current order status
                        controller.currentOrder.update((order) {
                          if (order != null) {
                            order.status = Constant.orderRejected;
                          }
                        });

                        // 2. Save to Firestore
                        if (controller.currentOrder.value.id != null) {
                          await FireStoreUtils.updateCabOrder(controller.currentOrder.value);
                        }

                        // 3. Reset controller states
                        controller.bottomSheetType.value = "";
                        controller.polyLines.clear();
                        controller.markers.clear();
                        controller.osmMarker.clear();
                        controller.routePoints.clear();
                        controller.sourceTextEditController.value.clear();
                        controller.destinationTextEditController.value.clear();
                        controller.departureLatLong.value = const LatLng(0.0, 0.0);
                        controller.destinationLatLong.value = const LatLng(0.0, 0.0);
                        controller.departureLatLongOsm.value = latlong.LatLng(0.0, 0.0);
                        controller.destinationLatLongOsm.value = latlong.LatLng(0.0, 0.0);

                        // 4. Reset user’s in-progress order
                        if (Constant.userModel != null) {
                          Constant.userModel!.inProgressOrderID = null;
                          await FireStoreUtils.updateUser(Constant.userModel!);
                        }

                        // 5. Optional feedback
                        ShowToastDialog.showToast("Ride cancelled successfully".tr);
                        Get.back();
                        CabDashboardController cabDashboardController = Get.put(CabDashboardController());
                        cabDashboardController.selectedIndex.value = 0;
                      } catch (e) {
                        ShowToastDialog.showToast("Failed to cancel ride".tr);
                      }
                    },
                    color: AppThemeData.danger300,
                    textColor: AppThemeData.surface,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget driverDialog(BuildContext context, IntercityHomeController controller, bool isDark) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.7,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(color: isDark ? AppThemeData.grey700 : Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppThemeData.grey400), height: 4, width: 33),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 10),
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(color: isDark ? Colors.transparent : Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Pickup Location
                                  InkWell(
                                    onTap: () async {
                                      // if (Constant.selectedMapType == 'osm') {
                                      //   final result = await Get.to(() => MapPickerPage());
                                      //   if (result != null) {
                                      //     controller.sourceTextEditController.value.text = '';
                                      //     final firstPlace = result;
                                      //     final lat = firstPlace.coordinates.latitude;
                                      //     final lng = firstPlace.coordinates.longitude;
                                      //     final address = firstPlace.address;
                                      //     controller.sourceTextEditController.value.text = address.toString();
                                      //     controller.setDepartureMarker(lat, lng);
                                      //   }
                                      // } else {
                                      //   Get.to(LocationPickerScreen())!.then((value) async {
                                      //     if (value != null) {
                                      //       SelectedLocationModel selectedLocationModel = value;
                                      //
                                      //       controller.sourceTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                      //       controller.setDepartureMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                      //     }
                                      //   });
                                      // }
                                    },
                                    child: TextFieldWidget(
                                      controller: controller.sourceTextEditController.value,
                                      hintText: "Pickup Location".tr,
                                      enable: false,
                                      readOnly: true,
                                      prefix: const Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Icon(Icons.stop_circle_outlined, color: Colors.green)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Destination Location
                                  InkWell(
                                    onTap: () async {
                                      // if (Constant.selectedMapType == 'osm') {
                                      //   final result = await Get.to(() => MapPickerPage());
                                      //   if (result != null) {
                                      //     controller.destinationTextEditController.value.text = '';
                                      //     final firstPlace = result;
                                      //     final lat = firstPlace.coordinates.latitude;
                                      //     final lng = firstPlace.coordinates.longitude;
                                      //     final address = firstPlace.address;
                                      //     controller.destinationTextEditController.value.text = address.toString();
                                      //     controller.setDestinationMarker(lat, lng);
                                      //   }
                                      // } else {
                                      //   Get.to(LocationPickerScreen())!.then((value) async {
                                      //     if (value != null) {
                                      //       SelectedLocationModel selectedLocationModel = value;
                                      //
                                      //       controller.destinationTextEditController.value.text = Utils.formatAddress(selectedLocation: selectedLocationModel);
                                      //       controller.setDestinationMarker(selectedLocationModel.latLng!.latitude, selectedLocationModel.latLng!.longitude);
                                      //     }
                                      //   });
                                      // }
                                    },
                                    child: TextFieldWidget(
                                      controller: controller.destinationTextEditController.value,
                                      // backgroundColor: AppThemeData.grey50,
                                      // borderColor: AppThemeData.grey50,
                                      hintText: "Destination Location".tr,
                                      enable: false,
                                      readOnly: true,
                                      prefix: const Padding(padding: EdgeInsets.only(left: 10, right: 10), child: Icon(Icons.radio_button_checked, color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 10,
                              top: 33,
                              child: DottedBorder(
                                options: CustomPathDottedBorderOptions(
                                  color: Colors.grey.shade400,
                                  strokeWidth: 2,
                                  dashPattern: [4, 4],
                                  customPath:
                                      (size) =>
                                          Path()
                                            ..moveTo(size.width / 2, 0)
                                            ..lineTo(size.width / 2, size.height),
                                ),
                                child: const SizedBox(width: 20, height: 40),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(10),
                              child: NetworkImageWidget(imageUrl: controller.currentOrder.value.driver?.profilePictureURL ?? '', height: 70, width: 70, borderRadius: 35),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.currentOrder.value.driver?.fullName() ?? '',
                                    style: AppThemeData.boldTextStyle(color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900, fontSize: 18),
                                  ),
                                  Text(
                                    "${controller.currentOrder.value.driver?.vehicleType ?? ''} | ${controller.currentOrder.value.driver?.carMakes ?? ''}",
                                    style: TextStyle(fontFamily: AppThemeData.medium, color: isDark ? AppThemeData.greyDark700 : AppThemeData.grey700, fontSize: 14),
                                  ),
                                  Text(
                                    controller.currentOrder.value.driver?.carNumber ?? '',
                                    style: AppThemeData.boldTextStyle(color: isDark ? AppThemeData.greyDark700 : AppThemeData.grey700, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            RoundedButtonBorder(
                              title: controller.driverModel.value.averageRating.toStringAsFixed(1) ?? '',
                              width: 20,
                              height: 3.5,
                              radius: 10,
                              isRight: false,
                              isCenter: true,
                              textColor: AppThemeData.warning400,
                              borderColor: AppThemeData.warning400,
                              color: AppThemeData.warning50,
                              icon: SvgPicture.asset("assets/icons/ic_start.svg"),
                              onPress: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50,
                            border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Order Summary".tr, style: AppThemeData.boldTextStyle(fontSize: 14, color: isDark ? AppThemeData.greyDark500 : AppThemeData.grey500)),
                              const SizedBox(height: 8),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Subtotal".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                    Text(
                                      Constant.amountShow(amount: controller.subTotal.value.toString()),
                                      style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Discount".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                    Text(Constant.amountShow(amount: controller.discount.value.toString()), style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: AppThemeData.danger300)),
                                  ],
                                ),
                              ),

                              // Tax List
                              ListView.builder(
                                itemCount: Constant.taxList.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  TaxModel taxModel = Constant.taxList[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${taxModel.title} (${taxModel.tax} ${taxModel.type == "Fixed" ? Constant.currencyData!.code : "%"})'.tr,
                                            textAlign: TextAlign.start,
                                            style: AppThemeData.mediumTextStyle(fontSize: 14, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                          ),
                                        ),
                                        Text(
                                          Constant.amountShow(
                                            amount: Constant.calculateTax(amount: (controller.subTotal.value - controller.discount.value).toString(), taxModel: taxModel).toString(),
                                          ).tr,
                                          textAlign: TextAlign.start,
                                          style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Order Total".tr, style: AppThemeData.mediumTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900)),
                                    Text(
                                      Constant.amountShow(amount: controller.totalAmount.value.toString()),
                                      style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isDark ? AppThemeData.greyDark50 : AppThemeData.grey50,
                            border: Border.all(color: isDark ? AppThemeData.greyDark200 : AppThemeData.grey200),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () {
                              controller.bottomSheetType.value = 'payment';
                            },
                            child: Row(
                              children: [
                                controller.selectedPaymentMethod.value == PaymentGateway.wallet.name
                                    ? cardDecorationScreen(controller, PaymentGateway.wallet, isDark, "assets/images/ic_wallet.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.cod.name
                                    ? cardDecorationScreen(controller, PaymentGateway.cod, isDark, "assets/images/ic_cash.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.stripe.name
                                    ? cardDecorationScreen(controller, PaymentGateway.stripe, isDark, "assets/images/stripe.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.paypal.name
                                    ? cardDecorationScreen(controller, PaymentGateway.paypal, isDark, "assets/images/paypal.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.payStack.name
                                    ? cardDecorationScreen(controller, PaymentGateway.payStack, isDark, "assets/images/paystack.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.mercadoPago.name
                                    ? cardDecorationScreen(controller, PaymentGateway.mercadoPago, isDark, "assets/images/mercado-pago.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.flutterWave.name
                                    ? cardDecorationScreen(controller, PaymentGateway.flutterWave, isDark, "assets/images/flutterwave_logo.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.payFast.name
                                    ? cardDecorationScreen(controller, PaymentGateway.payFast, isDark, "assets/images/payfast.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.midTrans.name
                                    ? cardDecorationScreen(controller, PaymentGateway.midTrans, isDark, "assets/images/midtrans.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.orangeMoney.name
                                    ? cardDecorationScreen(controller, PaymentGateway.orangeMoney, isDark, "assets/images/orange_money.png")
                                    : controller.selectedPaymentMethod.value == PaymentGateway.xendit.name
                                    ? cardDecorationScreen(controller, PaymentGateway.xendit, isDark, "assets/images/xendit.png")
                                    : cardDecorationScreen(controller, PaymentGateway.razorpay, isDark, "assets/images/razorpay.png"),
                                SizedBox(width: 22),
                                Text(
                                  controller.selectedPaymentMethod.value.tr,
                                  textAlign: TextAlign.start,
                                  style: AppThemeData.boldTextStyle(fontSize: 16, color: isDark ? AppThemeData.greyDark900 : AppThemeData.grey900),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          if (controller.currentOrder.value.status == Constant.orderInTransit) {
                            return Column(
                              children: [
                                RoundedButtonFill(
                                  title: "SOS".tr,
                                  color: Colors.red.withOpacity(0.50),
                                  textColor: AppThemeData.grey50,
                                  isCenter: true,
                                  icon: Icon(Icons.call, color: Colors.white),
                                  onPress: () async {
                                    ShowToastDialog.showLoader("Please wait...".tr);

                                    LocationData location = await controller.currentLocation.value.getLocation();

                                    await FireStoreUtils.getSOS(controller.currentOrder.value.id ?? '').then((value) async {
                                      if (value == false) {
                                        await FireStoreUtils.setSos(controller.currentOrder.value.id ?? '', UserLocation(latitude: location.latitude!, longitude: location.longitude!)).then((value) {
                                          ShowToastDialog.closeLoader();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Builder(
                                                builder: (context) {
                                                  return Text("Your SOS request has been submitted to admin".tr);
                                                },
                                              ),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        });
                                      } else {
                                        ShowToastDialog.closeLoader();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Builder(
                                              builder: (context) {
                                                return Text("Your SOS request is already submitted".tr);
                                              },
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (controller.currentOrder.value.status == Constant.orderInTransit && controller.currentOrder.value.paymentStatus == false) {
                      return RoundedButtonFill(
                        title: "Pay Now".tr,
                        onPress: () async {
                          if (controller.selectedPaymentMethod.value == PaymentGateway.stripe.name) {
                            controller.stripeMakePayment(amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.paypal.name) {
                            controller.paypalPaymentSheet(controller.totalAmount.value.toString(), context);
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.payStack.name) {
                            controller.payStackPayment(controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.mercadoPago.name) {
                            controller.mercadoPagoMakePayment(context: context, amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.flutterWave.name) {
                            controller.flutterWaveInitiatePayment(context: context, amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.payFast.name) {
                            controller.payFastPayment(context: context, amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.cod.name) {
                            controller.completeOrder();
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.wallet.name) {
                            controller.completeOrder();
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.midTrans.name) {
                            controller.midtransMakePayment(context: context, amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.orangeMoney.name) {
                            controller.orangeMakePayment(context: context, amount: controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.xendit.name) {
                            controller.xenditPayment(context, controller.totalAmount.value.toString());
                          } else if (controller.selectedPaymentMethod.value == PaymentGateway.razorpay.name) {
                            RazorPayController().createOrderRazorPay(amount: double.parse(controller.totalAmount.value.toString()), razorpayModel: controller.razorPayModel.value).then((value) {
                              if (value == null) {
                                Get.back();
                                ShowToastDialog.showToast("Something went wrong, please contact admin.".tr);
                              } else {
                                CreateRazorPayOrderModel result = value;
                                controller.openCheckout(amount: controller.totalAmount.value.toString(), orderId: result.id);
                              }
                            });
                          } else {
                            ShowToastDialog.showToast("Please select payment method".tr);
                          }
                        },
                        color: AppThemeData.primary300,
                        textColor: AppThemeData.grey900,
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Padding cardDecorationScreen(IntercityHomeController controller, PaymentGateway value, isDark, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(shape: RoundedRectangleBorder(side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8))),
        child: Padding(padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0), child: image == '' ? Container(color: isDark ? AppThemeData.grey800 : AppThemeData.grey100) : Image.asset(image)),
      ),
    );
  }

  Obx cardDecoration(IntercityHomeController controller, PaymentGateway value, isDark, String image) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                controller.selectedPaymentMethod.value = value.name;
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: ShapeDecoration(shape: RoundedRectangleBorder(side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8))),
                    child: Padding(padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0), child: Image.asset(image)),
                  ),
                  const SizedBox(width: 10),
                  value.name == "wallet"
                      ? Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.name.capitalizeString(),
                              textAlign: TextAlign.start,
                              style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                            ),
                            Text(
                              Constant.amountShow(amount: controller.userModel.value.walletAmount == null ? '0.0' : controller.userModel.value.walletAmount.toString()),
                              textAlign: TextAlign.start,
                              style: AppThemeData.semiBoldTextStyle(fontSize: 14, color: isDark ? AppThemeData.primary300 : AppThemeData.primary300),
                            ),
                          ],
                        ),
                      )
                      : Expanded(
                        child: Text(
                          value.name.capitalizeString(),
                          textAlign: TextAlign.start,
                          style: AppThemeData.semiBoldTextStyle(fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                        ),
                      ),
                  const Expanded(child: SizedBox()),
                  Radio(
                    value: value.name,
                    groupValue: controller.selectedPaymentMethod.value,
                    activeColor: isDark ? AppThemeData.primary300 : AppThemeData.primary300,
                    onChanged: (value) {
                      controller.selectedPaymentMethod.value = value.toString();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
