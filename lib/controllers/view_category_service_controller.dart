import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/on_demand_home_controller.dart';
import 'package:get/get.dart';
import '../models/provider_serivce_model.dart';
import '../service/fire_store_utils.dart';

class ViewCategoryServiceController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<ProviderServiceModel> providerList = <ProviderServiceModel>[].obs;

  RxString categoryId = "".obs, categoryTitle = "".obs;
  Rx<OnDemandHomeController> onDemandHomeController = Get.find<OnDemandHomeController>().obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>;
    categoryId.value = args['categoryId'] ?? "";
    categoryTitle.value = args['categoryTitle'] ?? "";

    getData();
  }

  Future<void> getData() async {
    providerList.clear();
    isLoading.value = true;

    List<ProviderServiceModel> providerServiceList = await FireStoreUtils.getProviderFuture(categoryId: categoryId.value);

    List<String?> uniqueAuthId = providerServiceList.map((service) => service.author).toList();
    List<String?> uniqueServiceId = providerServiceList.map((service) => service.id).toList();

    List<ProviderServiceModel> filterByItemLimit = <ProviderServiceModel>[];
    List<String?> uniqueId = <String>[];

    if ((Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel!.adminCommision?.isEnabled == true)) {
      for (var authUser in uniqueAuthId) {
        List<ProviderServiceModel> listofAllServiceByAuth = await FireStoreUtils.getAllProviderServiceByAuthorId(authUser!);

        for (int i = 0; i < listofAllServiceByAuth.length; i++) {
          if (listofAllServiceByAuth[i].subscriptionPlan?.itemLimit != null &&
              (i < int.parse(listofAllServiceByAuth[i].subscriptionPlan?.itemLimit ?? '0') || listofAllServiceByAuth[i].subscriptionPlan?.itemLimit == '-1')) {
            if (uniqueServiceId.contains(listofAllServiceByAuth[i].id)) {
              filterByItemLimit.add(listofAllServiceByAuth[i]);
            }
          }
        }

        for (var service in filterByItemLimit) {
          for (var unique in uniqueServiceId) {
            if (service.id == unique && !uniqueId.contains(service.id) && service.subscriptionTotalOrders != '0') {
              uniqueId.add(service.id);
              providerList.add(service);
            }
          }
        }
      }
    } else {
      providerList.addAll(providerServiceList);
    }

    isLoading.value = false;
  }
}
