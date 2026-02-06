import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../constant/constant.dart';
import '../models/parcel_order_model.dart';
import '../models/wallet_transaction_model.dart';
import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../service/fire_store_utils.dart';
import '../themes/show_toast_dialog.dart';

class ParcelMyBookingController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<ParcelOrderModel> parcelOrder = <ParcelOrderModel>[].obs;

  RxString selectedTab = "New".obs;
  RxList<String> tabTitles = ["New", "In Transit", "Delivered", "Cancelled"].obs;

  StreamSubscription<List<ParcelOrderModel>>? _parcelSubscription;

  @override
  void onInit() {
    super.onInit();
    listenParcelOrders();
  }

  void selectTab(String tab) {
    selectedTab.value = tab;
  }

  /// Start listening to orders live. Cancel previous subscription first.
  void listenParcelOrders() {
    isLoading.value = true;
    if (Constant.userModel == null) {
      isLoading.value = false;
      return;
    }
    _parcelSubscription?.cancel();
    _parcelSubscription = FireStoreUtils.listenParcelOrders().listen(
      (orders) {
        parcelOrder.assignAll(orders);
        isLoading.value = false;
      },
      onError: (err) {
        isLoading.value = false;
        // optionally handle error
      },
    );
  }

  /// Return filtered list for a specific tab title
  List<ParcelOrderModel> getOrdersForTab(String tab) {
    switch (tab) {
      case "New":
        return parcelOrder.where((order) => ["Order Placed"].contains(order.status)).toList();

      case "In Transit":
        return parcelOrder.where((order) => ["Order Accepted", "Driver Accepted", "Driver Pending", "Order Shipped", "In Transit"].contains(order.status)).toList();

      case "Delivered":
        return parcelOrder.where((order) => ["Order Completed"].contains(order.status)).toList();

      case "Cancelled":
        return parcelOrder.where((order) => ["Order Rejected", "Order Cancelled", "Driver Rejected"].contains(order.status)).toList();

      default:
        return [];
    }
  }

  /// Old helper (optional)
  List<ParcelOrderModel> get filteredParcelOrders => getOrdersForTab(selectedTab.value);

  String formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }

  Future<void> cancelParcelOrder(ParcelOrderModel order) async {
    try {
      isLoading.value = true;

      if (order.status != Constant.orderPlaced) {
        ShowToastDialog.showToast("You can only cancel before pickup.".tr);
        return;
      }

      order.status = Constant.orderCancelled;
      await FireStoreUtils.parcelOrderPlace(order);

      listenParcelOrders();

      if (order.paymentMethod?.toLowerCase() != "cod") {
        double totalTax = 0.0;

        final taxSettings = order.taxSetting ?? [];

        for (var element in taxSettings) {
          totalTax += Constant.calculateTax(amount: (double.parse(order.subTotal.toString()) - double.parse(order.discount.toString())).toString(), taxModel: element);
        }

        double subTotal = double.parse(order.subTotal.toString()) - double.parse(order.discount.toString());
        double refundAmount = subTotal + totalTax;

        WalletTransactionModel walletTransaction = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: refundAmount,
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: true,
          // refund
          orderId: order.id,
          note: "Refund for cancelled parcel order",
          paymentStatus: "success",
          serviceType: Constant.parcelServiceType,
        );

        // Save wallet transaction
        await FireStoreUtils.setWalletTransaction(walletTransaction);

        // Update wallet balance
        await FireStoreUtils.updateUserWallet(amount: refundAmount.toString(), userId: FireStoreUtils.getCurrentUid());
      }

      ShowToastDialog.showToast("Order cancelled successfully".tr);
    } catch (e) {
      ShowToastDialog.showToast("${'Failed to cancel order:'.tr} $e".tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _parcelSubscription?.cancel();
    super.onClose();
  }
}
