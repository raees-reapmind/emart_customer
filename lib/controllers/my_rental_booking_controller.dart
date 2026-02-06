import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:get/get.dart';
import '../models/rental_order_model.dart';
import '../models/tax_model.dart';
import '../service/fire_store_utils.dart';

class MyRentalBookingController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<RentalOrderModel> rentalOrders = <RentalOrderModel>[].obs;

  RxString selectedTab = "New".obs;
  RxList<String> tabTitles = ["New", "On Going", "Completed", "Cancelled"].obs;

  StreamSubscription<List<RentalOrderModel>>? _rentalSubscription;
  final RxString selectedPaymentMethod = ''.obs;

  @override
  void onInit() {
    super.onInit();
    listenRentalOrders();
  }

  void selectTab(String tab) {
    selectedTab.value = tab;
  }

  /// Start listening to rental orders live. Cancel previous subscription first.
  void listenRentalOrders() {
    isLoading.value = true;
    _rentalSubscription?.cancel();
    if (Constant.userModel != null) {
      _rentalSubscription = FireStoreUtils.getRentalOrders().listen(
        (orders) {
          rentalOrders.assignAll(orders);
        },
        onError: (err) {
          isLoading.value = false;
          print("Error fetching rental orders: $err");
        },
      );
    }
    isLoading.value = false;

  }

  Rx<RentalOrderModel> selectedOrder = RentalOrderModel().obs;
  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble extraKilometerCharge = 0.0.obs;
  RxDouble extraMinutesCharge = 0.0.obs;

  void calculateTotalAmount(RentalOrderModel order) {
    subTotal.value = 0.0;
    discount.value = 0.0;
    taxAmount.value = 0.0;
    totalAmount.value = 0.0;
    extraKilometerCharge.value = 0.0;
    extraMinutesCharge.value = 0.0;

    selectedOrder.value = order;
    try {
      subTotal.value = double.tryParse(selectedOrder.value.subTotal?.toString() ?? "0") ?? 0.0;
      discount.value = double.tryParse(selectedOrder.value.discount?.toString() ?? "0") ?? 0.0;
      taxAmount.value = 0.0;

      if (selectedOrder.value.endTime != null) {
        DateTime start = selectedOrder.value.startTime!.toDate();
        DateTime end = selectedOrder.value.endTime!.toDate();
        int hours = end.difference(start).inHours;
        if (hours >= int.parse(selectedOrder.value.rentalPackageModel!.includedHours.toString())) {
          hours = hours - int.parse(selectedOrder.value.rentalPackageModel!.includedHours.toString());
          double hourlyRate = double.tryParse(selectedOrder.value.rentalPackageModel?.extraMinuteFare?.toString() ?? "0") ?? 0.0;
          extraMinutesCharge.value = (hours * 60) * hourlyRate;
        }
      }

      if (selectedOrder.value.startKitoMetersReading != null && selectedOrder.value.endKitoMetersReading != null) {
        double startKm = double.tryParse(selectedOrder.value.startKitoMetersReading?.toString() ?? "0") ?? 0.0;
        double endKm = double.tryParse(selectedOrder.value.endKitoMetersReading?.toString() ?? "0") ?? 0.0;
        if (endKm > startKm) {
          double totalKm = endKm - startKm;
          if (totalKm > double.parse(selectedOrder.value.rentalPackageModel!.includedDistance!)) {
            totalKm = totalKm - double.parse(selectedOrder.value.rentalPackageModel!.includedDistance!);
            double extraKmRate = double.tryParse(selectedOrder.value.rentalPackageModel?.extraKmFare?.toString() ?? "0") ?? 0.0;
            extraKilometerCharge.value = totalKm * extraKmRate;
          }
        }
      }
      subTotal.value = subTotal.value + extraKilometerCharge.value + extraMinutesCharge.value;

      if (selectedOrder.value.taxSetting != null) {
        for (var element in selectedOrder.value.taxSetting!) {
          taxAmount.value += Constant.calculateTax(amount: (subTotal.value - discount.value).toString(), taxModel: element);
        }
      }

      totalAmount.value = (subTotal.value - discount.value) + taxAmount.value;
    } catch (e) {
      ShowToastDialog.showToast("Failed to calculate total: $e");
    }
  }

  Future<void> completeOrder() async {
    if (selectedPaymentMethod.value == PaymentGateway.cod.name) {
      selectedOrder.value.paymentMethod = selectedPaymentMethod.value;
      await FireStoreUtils.rentalOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment method changed".tr);
        Get.back();
        Get.back();
      });
    } else {
      selectedOrder.value.paymentStatus = true;
      selectedOrder.value.paymentMethod = selectedPaymentMethod.value;
      if (selectedPaymentMethod.value == PaymentGateway.wallet.name) {
        WalletTransactionModel transactionModel = WalletTransactionModel(
          id: Constant.getUuid(),
          amount: double.parse(totalAmount.toString()),
          date: Timestamp.now(),
          paymentMethod: PaymentGateway.wallet.name,
          transactionUser: "customer",
          userId: FireStoreUtils.getCurrentUid(),
          isTopup: false,
          orderId: selectedOrder.value.id,
          note: "Rental Amount debited".tr,
          paymentStatus: "success".tr,
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          if (value == true) {
            await FireStoreUtils.updateUserWallet(amount: "-${totalAmount.value.toString()}", userId: FireStoreUtils.getCurrentUid());
          }
        });
      }

      await FireStoreUtils.rentalOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        Get.back();
        Get.back();
      });
    }
  }

  /// Return filtered list for a specific tab title
  List<RentalOrderModel> getOrdersForTab(String tab) {
    switch (tab) {
      case "New":
        return rentalOrders.where((order) => ["Order Placed", "Order Accepted", "Driver Pending"].contains(order.status)).toList();

      case "On Going":
        return rentalOrders.where((order) => ["Driver Accepted", "Order Shipped", "In Transit"].contains(order.status)).toList();

      case "Completed":
        return rentalOrders.where((order) => ["Order Completed"].contains(order.status)).toList();

      case "Cancelled":
        return rentalOrders.where((order) => ["Order Rejected", "Order Cancelled", "Driver Rejected"].contains(order.status)).toList();

      default:
        return [];
    }
  }

  /// Old helper (optional)
  List<RentalOrderModel> get filteredRentalOrders => getOrdersForTab(selectedTab.value);

  Future<void> cancelRentalRequest(RentalOrderModel order, {List<TaxModel>? taxList}) async {
    try {
      isLoading.value = true;
      order.status = Constant.orderCancelled;
      await FireStoreUtils.rentalOrderPlace(order);

      listenRentalOrders();

      if (order.paymentMethod?.toLowerCase() != "cod") {
        double totalTax = 0.0;

        if (taxList != null) {
          for (var element in taxList) {
            totalTax += Constant.calculateTax(
              amount: (double.parse(order.subTotal.toString()) - double.parse(order.discount.toString())).toString(),
              taxModel: element,
            );
          }
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
          note: "Refund for cancelled booking".tr,
          paymentStatus: "success".tr,
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(walletTransaction);
        await FireStoreUtils.updateUserWallet(amount: refundAmount.toString(), userId: FireStoreUtils.getCurrentUid());
      }
      ShowToastDialog.showToast("Booking cancelled successfully".tr);
    } catch (e) {
      ShowToastDialog.showToast("Failed to cancel booking: $e".tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _rentalSubscription?.cancel();
    super.onClose();
  }
}
