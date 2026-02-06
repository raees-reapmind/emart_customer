import 'package:get/get.dart';
import '../models/banner_model.dart';
import '../models/parcel_category.dart';
import '../service/fire_store_utils.dart';

class HomeParcelController extends GetxController {
  RxBool isLoading = true.obs;

  RxList<BannerModel> bannerTopHome = <BannerModel>[].obs;
  RxList<ParcelCategory> parcelCategory = <ParcelCategory>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() async {
    try {
      isLoading.value = true;

      // Load banners
      await FireStoreUtils.getHomeTopBanner().then((value) {
        bannerTopHome.value = value;
      });

      // Load parcel categories
      await FireStoreUtils.getParcelServiceCategory().then((value) {
        parcelCategory.value = value;
      });

    } catch (e) {
      bannerTopHome.clear();
      parcelCategory.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
