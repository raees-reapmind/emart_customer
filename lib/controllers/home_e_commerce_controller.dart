import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/banner_model.dart';
import 'package:customer/models/brands_model.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/service/cart_provider.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/constant.dart';

class HomeECommerceController extends GetxController {
  final CartProvider cartProvider = CartProvider();

  Future<void> getCartData() async {
    cartProvider.cartStream.listen((event) async {
      cartItem.clear();
      cartItem.addAll(event);
    });
    update();
  }

  RxBool isLoading = true.obs;
  RxBool isListView = true.obs;
  RxBool isPopular = true.obs;

  Rx<PageController> pageController = PageController(viewportFraction: 0.877).obs;
  Rx<PageController> pageBottomController = PageController(viewportFraction: 0.877).obs;
  RxInt currentPage = 0.obs;
  RxInt currentBottomPage = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getVendorCategory();
    getData();
    super.onInit();
  }

  RxList<VendorCategoryModel> vendorCategoryModel = <VendorCategoryModel>[].obs;
  RxList<VendorCategoryModel> categoryWiseProductList = <VendorCategoryModel>[].obs;

  RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;
  RxList<VendorModel> newArrivalRestaurantList = <VendorModel>[].obs;
  RxList<AdvertisementModel> advertisementList = <AdvertisementModel>[].obs;

  RxList<BannerModel> bannerModel = <BannerModel>[].obs;
  RxList<BannerModel> bannerBottomModel = <BannerModel>[].obs;
  RxList<BrandsModel> brandList = <BrandsModel>[].obs;

  Future<void> getData() async {
    isLoading.value = true;
    getCartData();
    FireStoreUtils.getAllNearestRestaurant().listen((event) async {
      print("=====>${event.length}");

      newArrivalRestaurantList.clear();
      allNearestRestaurant.clear();
      advertisementList.clear();

      allNearestRestaurant.addAll(event);
      newArrivalRestaurantList.addAll(event);
      Constant.restaurantList = allNearestRestaurant;
      List<String> usedCategoryIds = allNearestRestaurant.expand((vendor) => vendor.categoryID ?? []).whereType<String>().toSet().toList();
      vendorCategoryModel.value = vendorCategoryModel.where((category) => usedCategoryIds.contains(category.id)).toList();

      newArrivalRestaurantList.sort((a, b) => (b.createdAt ?? Timestamp.now()).toDate().compareTo((a.createdAt ?? Timestamp.now()).toDate()));

      if (Constant.isEnableAdsFeature == true) {
        await FireStoreUtils.getAllAdvertisement().then((value) {
          advertisementList.clear();
          for (var element1 in value) {
            for (var element in allNearestRestaurant) {
              if (element1.vendorId == element.id) {
                advertisementList.add(element1);
              }
            }
          }
        });
      }
    });
    setLoading();
  }

  Future<void> setLoading() async {
    await Future.delayed(Duration(seconds: 1), () async {
      if (allNearestRestaurant.isEmpty) {
        await Future.delayed(Duration(seconds: 2), () {
          isLoading.value = false;
        });
      } else {
        isLoading.value = false;
      }
      update();
    });
  }

  Future<void> getVendorCategory() async {
    await FireStoreUtils.getHomeVendorCategory().then((value) {
      vendorCategoryModel.value = value;
    });
    await FireStoreUtils.getHomePageShowCategory().then((value) {
      categoryWiseProductList.value = value;
    });

    await FireStoreUtils.getHomeTopBanner().then((value) {
      bannerModel.value = value;
    });

    await FireStoreUtils.getHomeBottomBanner().then((value) {
      bannerBottomModel.value = value;
    });

    await FireStoreUtils.getBrandList().then((value) {
      brandList.value = value;
    });
    await getFavouriteRestaurant();
  }

  RxList<FavouriteModel> favouriteList = <FavouriteModel>[].obs;

  Future<void> getFavouriteRestaurant() async {
    if (Constant.userModel?.id != null) {
      await FireStoreUtils.getFavouriteRestaurant().then((value) {
        favouriteList.value = value;
      });
    }
  }
}
