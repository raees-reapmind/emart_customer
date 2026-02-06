import 'package:get/get.dart';
import '../models/onprovider_order_model.dart';
import '../models/worker_model.dart';
import '../service/fire_store_utils.dart';

class MyBookingOnDemandController extends GetxController {
  RxList<OnProviderOrderModel> orders = <OnProviderOrderModel>[].obs;
  RxBool isLoading = true.obs;

  RxString selectedTab = "Placed".obs;
  RxMap<String, WorkerModel> workers = <String, WorkerModel>{}.obs;

  RxList<String> tabTitles = ["Placed", "Completed", "Cancelled"].obs;

  @override
  void onInit() {
    super.onInit();
    listenOrders(); // Listen for real-time updates
  }


  void selectTab(String tab) {
    selectedTab.value = tab;
  }

  void listenOrders() {
    isLoading.value = true;

    FireStoreUtils.getProviderOrdersStream().listen(
      (updatedOrders) {
        orders.value = updatedOrders;

        // Fetch worker info if not already fetched
        for (var order in updatedOrders) {
          if (order.workerId != null && order.workerId!.isNotEmpty && !workers.containsKey(order.workerId!)) {
            FireStoreUtils.getWorker(order.workerId!).then((worker) {
              if (worker != null) workers[order.workerId!] = worker;
            });
          }
        }

        isLoading.value = false;
      },
      onError: (error) {
        print("Error fetching orders stream: $error");
        isLoading.value = false;
      },
    );
  }

  List<OnProviderOrderModel> get filteredParcelOrders => getOrdersForTab(selectedTab.value);

  List<OnProviderOrderModel> getOrdersForTab(String tab) {
    switch (tab) {
      case "Placed":
        return orders.where((order) => ["Order Placed", "Order Accepted", "Order Assigned", "Order Ongoing", "In Transit"].contains(order.status)).toList();

      case "Completed":
        return orders.where((order) => ["Order Completed"].contains(order.status)).toList();

      case "Cancelled":
        return orders.where((order) => ["Order Rejected", "Order Cancelled", "Driver Rejected"].contains(order.status)).toList();

      default:
        return [];
    }
  }

  WorkerModel? getWorker(String? workerId) {
    if (workerId == null || workerId.isEmpty) return null;
    return workers[workerId];
  }
}
