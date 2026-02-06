import 'package:customer/constant/constant.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/vendor_category_model.dart';
import '../service/fire_store_utils.dart';
import 'package:get/get.dart';

class CategoryRestaurantController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool dineIn = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<VendorCategoryModel> vendorCategoryModel = VendorCategoryModel().obs;
  RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorCategoryModel.value = argumentData['vendorCategoryModel'];
      dineIn.value = argumentData['dineIn'];
      await getZone();
      await getRestaurant();
    }
    Future.delayed(Duration(seconds: 1), () {
      isLoading.value = false;
    });
  }

  Future getRestaurant() async {
    FireStoreUtils.getAllNearestRestaurantByCategoryId(categoryId: vendorCategoryModel.value.id.toString(), isDining: dineIn.value).listen((
      event,
    ) async {
      allNearestRestaurant.clear();
      allNearestRestaurant.addAll(event);
    });
  }

  Future<void> getZone() async {
    await FireStoreUtils.getZone().then((value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          if (Constant.isPointInPolygon(
            LatLng(Constant.selectedLocation.location!.latitude ?? 0.0, Constant.selectedLocation.location!.longitude ?? 0.0),
            value[i].area!,
          )) {
            Constant.selectedZone = value[i];
            Constant.isZoneAvailable = true;
            break;
          } else {
            Constant.isZoneAvailable = false;
          }
        }
      }
    });
  }
}
