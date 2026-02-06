import 'package:customer/constant/constant.dart';
import 'package:customer/models/brands_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:get/get.dart';

class AllBrandProductController extends GetxController {
  RxList<ProductModel> productList = <ProductModel>[].obs;
  Rx<BrandsModel> brandModel = BrandsModel().obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArguments();
    super.onInit();
  }

  Future<void> getArguments() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      brandModel.value = arguments['brandModel'];
      await getProductByCategoryId();
    }
    isLoading.value = false;
  }

  Future<void> getProductByCategoryId() async {
    List<ProductModel> productDataList = await FireStoreUtils.getProductListByBrandId(brandModel.value.id.toString());

    List<VendorModel> vendorList = await FireStoreUtils.getAllStoresFuture();
    List<ProductModel> allProduct = <ProductModel>[];
    for (var vendor in vendorList) {
      await FireStoreUtils.getAllProducts(vendor.id.toString()).then((value) {
        if (Constant.isSubscriptionModelApplied == true || vendor.adminCommission?.isEnabled == true) {
          if (vendor.subscriptionPlan != null && Constant.isExpire(vendor) == false) {
            if (vendor.subscriptionPlan?.itemLimit == '-1') {
              allProduct.addAll(value);
            } else {
              int selectedProduct =
                  value.length < int.parse(vendor.subscriptionPlan?.itemLimit ?? '0') ? (value.isEmpty ? 0 : (value.length)) : int.parse(vendor.subscriptionPlan?.itemLimit ?? '0');
              allProduct.addAll(value.sublist(0, selectedProduct));
            }
          }
        } else {
          allProduct.addAll(value);
        }
      });
    }
    for (var element in productDataList) {
      final bool productIsInList = allProduct.any((product) => product.id == element.id);
      if (productIsInList) {
        productList.add(element);
      }
    }
  }
}
