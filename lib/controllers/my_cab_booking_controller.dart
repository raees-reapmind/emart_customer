import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as maths;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cab_order_model.dart';
import 'package:customer/models/payment_model/cod_setting_model.dart';
import 'package:customer/models/payment_model/flutter_wave_model.dart';
import 'package:customer/models/payment_model/mercado_pago_model.dart';
import 'package:customer/models/payment_model/mid_trans.dart';
import 'package:customer/models/payment_model/orange_money.dart';
import 'package:customer/models/payment_model/pay_fast_model.dart';
import 'package:customer/models/payment_model/pay_stack_model.dart';
import 'package:customer/models/payment_model/paypal_model.dart';
import 'package:customer/models/payment_model/paytm_model.dart';
import 'package:customer/models/payment_model/razorpay_model.dart';
import 'package:customer/models/payment_model/stripe_model.dart';
import 'package:customer/models/payment_model/wallet_setting_model.dart';
import 'package:customer/models/payment_model/xendit.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/payment/MercadoPagoScreen.dart';
import 'package:customer/payment/PayFastScreen.dart';
import 'package:customer/payment/getPaytmTxtToken.dart';
import 'package:customer/payment/midtrans_screen.dart';
import 'package:customer/payment/orangePayScreen.dart';
import 'package:customer/payment/paystack/pay_stack_screen.dart';
import 'package:customer/payment/paystack/pay_stack_url_model.dart';
import 'package:customer/payment/paystack/paystack_url_genrater.dart';
import 'package:customer/payment/stripe_failed_model.dart';
import 'package:customer/payment/xenditModel.dart';
import 'package:customer/payment/xenditScreen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:customer/themes/show_toast_dialog.dart';
import 'package:customer/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import '../themes/app_them_data.dart';

class MyCabBookingController extends GetxController {
  RxBool isLoading = true.obs;
  RxString selectedTab = "New".obs;

  RxList<CabOrderModel> cabOrder = <CabOrderModel>[].obs;

  final List<String> tabKeys = ["New", "On Going", "Completed", "Cancelled"];

  Rx<UserModel> userModel = UserModel().obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    fetchParcelData();
  }

  Future<void> selectTab(String tab) async {
    selectedTab.value = tab;
  }

  Future<void> fetchParcelData() async {
    isLoading.value = true;

    if (FirebaseAuth.instance.currentUser != null) {
      await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((user) {
        if (user != null) {
          userModel.value = user;
        }
      });

      FireStoreUtils.getCabDriverOrders().listen((orders) {
        cabOrder.value = orders;
      });

      await getPaymentSettings();
    }

    isLoading.value = false;
  }

  List<CabOrderModel> get filteredParcelOrders => getOrdersForTab(selectedTab.value);

  List<CabOrderModel> getOrdersForTab(String tab) {
    switch (tab) {
      case "New":
        return cabOrder.where((order) => ["Order Placed", "Driver Pending"].contains(order.status)).toList();

      case "On Going":
        return cabOrder.where((order) => ["Driver Accepted", "Order Shipped", "In Transit"].contains(order.status)).toList();

      case "Completed":
        return cabOrder.where((order) => ["Order Completed"].contains(order.status)).toList();

      case "Cancelled":
        return cabOrder.where((order) => ["Order Rejected", "Order Cancelled", "Driver Rejected"].contains(order.status)).toList();

      default:
        return [];
    }
  }

  /// Get localized title for UI
  String getLocalizedTabTitle(String tabKey) {
    switch (tabKey) {
      case "New":
        return "New".tr;
      case "On Going":
        return "On Going".tr;
      case "Completed":
        return "Completed".tr;
      case "Cancelled":
        return "Cancelled".tr;
      default:
        return tabKey;
    }
  }

  String formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }

  Rx<WalletSettingModel> walletSettingModel = WalletSettingModel().obs;
  Rx<CodSettingModel> cashOnDeliverySettingModel = CodSettingModel().obs;
  Rx<PayFastModel> payFastModel = PayFastModel().obs;
  Rx<MercadoPagoModel> mercadoPagoModel = MercadoPagoModel().obs;
  Rx<PayPalModel> payPalModel = PayPalModel().obs;
  Rx<StripeModel> stripeModel = StripeModel().obs;
  Rx<FlutterWaveModel> flutterWaveModel = FlutterWaveModel().obs;
  Rx<PayStackModel> payStackModel = PayStackModel().obs;
  Rx<PaytmModel> paytmModel = PaytmModel().obs;
  Rx<RazorPayModel> razorPayModel = RazorPayModel().obs;

  Rx<MidTrans> midTransModel = MidTrans().obs;
  Rx<OrangeMoney> orangeMoneyModel = OrangeMoney().obs;
  Rx<Xendit> xenditModel = Xendit().obs;

  final RxString selectedPaymentMethod = ''.obs;

  Rx<CabOrderModel> currentOrder = CabOrderModel().obs;

  Rx<CabOrderModel> selectedOrder = CabOrderModel().obs;
  RxDouble totalAmount = 0.0.obs;

  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;

  void calculateTotalAmount(CabOrderModel order) {
    subTotal.value = 0.0;
    discount.value = 0.0;
    taxAmount.value = 0.0;
    totalAmount.value = 0.0;

    selectedOrder.value = order;
    try {
      subTotal.value = double.tryParse(selectedOrder.value.subTotal?.toString() ?? "0") ?? 0.0;
      discount.value = double.tryParse(selectedOrder.value.discount?.toString() ?? "0") ?? 0.0;
      taxAmount.value = 0.0;

      subTotal.value = subTotal.value;

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
      await FireStoreUtils.cabOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment method changed".tr);
        Get.back();
      });
    } else {
      selectedOrder.value.paymentMethod = selectedPaymentMethod.value;
      userModel.value.inProgressOrderID ??= [];
      userModel.value.inProgressOrderID!.clear();
      await FireStoreUtils.updateUser(userModel.value);
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
          note: "Cab Amount debited".tr,
          paymentStatus: "success".tr,
          serviceType: Constant.parcelServiceType,
        );

        await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
          await FireStoreUtils.updateUserWallet(amount: "-${totalAmount.value.toString()}", userId: FireStoreUtils.getCurrentUid());
        });
      }
      selectedOrder.value.paymentStatus = true;
      await FireStoreUtils.cabOrderPlace(selectedOrder.value).then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        Get.back();
      });
    }
  }

  Future<void> getPaymentSettings() async {
    await FireStoreUtils.getPaymentSettingsData().then((value) {
      stripeModel.value = StripeModel.fromJson(jsonDecode(Preferences.getString(Preferences.stripeSettings)));
      payPalModel.value = PayPalModel.fromJson(jsonDecode(Preferences.getString(Preferences.paypalSettings)));
      payStackModel.value = PayStackModel.fromJson(jsonDecode(Preferences.getString(Preferences.payStack)));
      mercadoPagoModel.value = MercadoPagoModel.fromJson(jsonDecode(Preferences.getString(Preferences.mercadoPago)));
      flutterWaveModel.value = FlutterWaveModel.fromJson(jsonDecode(Preferences.getString(Preferences.flutterWave)));
      paytmModel.value = PaytmModel.fromJson(jsonDecode(Preferences.getString(Preferences.paytmSettings)));
      payFastModel.value = PayFastModel.fromJson(jsonDecode(Preferences.getString(Preferences.payFastSettings)));
      razorPayModel.value = RazorPayModel.fromJson(jsonDecode(Preferences.getString(Preferences.razorpaySettings)));
      midTransModel.value = MidTrans.fromJson(jsonDecode(Preferences.getString(Preferences.midTransSettings)));
      orangeMoneyModel.value = OrangeMoney.fromJson(jsonDecode(Preferences.getString(Preferences.orangeMoneySettings)));
      xenditModel.value = Xendit.fromJson(jsonDecode(Preferences.getString(Preferences.xenditSettings)));
      walletSettingModel.value = WalletSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.walletSettings)));
      cashOnDeliverySettingModel.value = CodSettingModel.fromJson(jsonDecode(Preferences.getString(Preferences.codSettings)));

      if (walletSettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.wallet.name;
      } else if (cashOnDeliverySettingModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.cod.name;
      } else if (stripeModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.stripe.name;
      } else if (payPalModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.paypal.name;
      } else if (payStackModel.value.isEnable == true) {
        selectedPaymentMethod.value = PaymentGateway.payStack.name;
      } else if (mercadoPagoModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.mercadoPago.name;
      } else if (flutterWaveModel.value.isEnable == true) {
        selectedPaymentMethod.value = PaymentGateway.flutterWave.name;
      } else if (payFastModel.value.isEnable == true) {
        selectedPaymentMethod.value = PaymentGateway.payFast.name;
      } else if (razorPayModel.value.isEnabled == true) {
        selectedPaymentMethod.value = PaymentGateway.razorpay.name;
      } else if (midTransModel.value.enable == true) {
        selectedPaymentMethod.value = PaymentGateway.midTrans.name;
      } else if (orangeMoneyModel.value.enable == true) {
        selectedPaymentMethod.value = PaymentGateway.orangeMoney.name;
      } else if (xenditModel.value.enable == true) {
        selectedPaymentMethod.value = PaymentGateway.xendit.name;
      }
      Stripe.publishableKey = stripeModel.value.clientpublishableKey.toString();
      Stripe.merchantIdentifier = 'eMart Customer';
      Stripe.instance.applySettings();
      setRef();

      razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
      razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWaller);
      razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    });
  }

  // Strip
  Future<void> stripeMakePayment({required String amount}) async {
    log(double.parse(amount).toStringAsFixed(0));
    try {
      Map<String, dynamic>? paymentIntentData = await createStripeIntent(amount: amount);
      log("stripe Responce====>$paymentIntentData");
      if (paymentIntentData!.containsKey("error")) {
        Get.back();
        ShowToastDialog.showToast("Something went wrong, please contact admin.".tr);
      } else {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentData['client_secret'],
            allowsDelayedPaymentMethods: false,
            googlePay: const PaymentSheetGooglePay(merchantCountryCode: 'US', testEnv: true, currencyCode: "USD"),
            customFlow: true,
            style: ThemeMode.system,
            appearance: PaymentSheetAppearance(colors: PaymentSheetAppearanceColors(primary: AppThemeData.primary300)),
            merchantDisplayName: 'GoRide',
          ),
        );
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      log("$e \n$s");
      ShowToastDialog.showToast("exception:$e \n$s");
    }
  }

  Future<void> displayStripePaymentSheet({required String amount}) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        ShowToastDialog.showToast("Payment successfully".tr);
        completeOrder();
      });
    } on StripeException catch (e) {
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      ShowToastDialog.showToast(lom.error.message);
    } catch (e) {
      ShowToastDialog.showToast(e.toString());
    }
  }

  Future createStripeIntent({required String amount}) async {
    try {
      Map<String, dynamic> body = {
        'amount': ((double.parse(amount) * 100).round()).toString(),
        'currency': "USD",
        'payment_method_types[]': 'card',
        "description": "Strip Payment",
        "shipping[name]": Constant.userModel!.fullName(),
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      var stripeSecret = stripeModel.value.stripeSecret;
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {'Authorization': 'Bearer $stripeSecret', 'Content-Type': 'application/x-www-form-urlencoded'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      log(e.toString());
    }
  }

  //mercadoo
  Future<Null> mercadoPagoMakePayment({required BuildContext context, required String amount}) async {
    final headers = {'Authorization': 'Bearer ${mercadoPagoModel.value.accessToken}', 'Content-Type': 'application/json'};

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL", // or your preferred currency
          "unit_price": double.parse(amount),
        },
      ],
      "payer": {"email": Constant.userModel!.email},
      "back_urls": {
        "failure": "${Constant.globalUrl}payment/failure",
        "pending": "${Constant.globalUrl}payment/pending",
        "success": "${Constant.globalUrl}payment/success",
      },
      "auto_return": "approved",
      // Automatically return after payment is approved
    });

    final response = await http.post(Uri.parse("https://api.mercadopago.com/checkout/preferences"), headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['init_point']))!.then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          completeOrder();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
        }
      });
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

  //Paypal
  void paypalPaymentSheet(String amount, context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (BuildContext context) => UsePaypal(
              sandboxMode: payPalModel.value.isLive == true ? false : true,
              clientId: payPalModel.value.paypalClient ?? '',
              secretKey: payPalModel.value.paypalSecret ?? '',
              returnURL: "com.parkme://paypalpay",
              cancelURL: "com.parkme://paypalpay",
              transactions: [
                {
                  "amount": {
                    "total": amount,
                    "currency": "USD",
                    "details": {"subtotal": amount},
                  },
                },
              ],
              note: "Contact us for any questions on your order.",
              onSuccess: (Map params) async {
                completeOrder();
                ShowToastDialog.showToast("Payment Successful!!".tr);
              },
              onError: (error) {
                Get.back();
                ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
              },
              onCancel: (params) {
                Get.back();
                ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
              },
            ),
      ),
    );
  }

  ///PayStack Payment Method
  Future<void> payStackPayment(String totalAmount) async {
    await PayStackURLGen.payStackURLGen(
      amount: (double.parse(totalAmount) * 100).toString(),
      currency: "ZAR",
      secretKey: payStackModel.value.secretKey.toString(),
      userModel: Constant.userModel!,
    ).then((value) async {
      if (value != null) {
        PayStackUrlModel payStackModel0 = value;
        Get.to(
          PayStackScreen(
            secretKey: payStackModel.value.secretKey.toString(),
            callBackUrl: payStackModel.value.callbackURL.toString(),
            initialURl: payStackModel0.data.authorizationUrl,
            amount: totalAmount,
            reference: payStackModel0.data.reference,
          ),
        )!.then((value) {
          if (value) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            completeOrder();
          } else {
            ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
          }
        });
      } else {
        ShowToastDialog.showToast("Something went wrong, please contact admin.".tr);
      }
    });
  }

  //flutter wave Payment Method
  Future<Null> flutterWaveInitiatePayment({required BuildContext context, required String amount}) async {
    final url = Uri.parse('https://api.flutterwave.com/v3/payments');
    final headers = {'Authorization': 'Bearer ${flutterWaveModel.value.secretKey}', 'Content-Type': 'application/json'};

    final body = jsonEncode({
      "tx_ref": _ref,
      "amount": amount,
      "currency": "NGN",
      "redirect_url": "${Constant.globalUrl}payment/success",
      "payment_options": "ussd, card, barter, payattitude",
      "customer": {
        "email": Constant.userModel!.email.toString(),
        "phonenumber": Constant.userModel!.phoneNumber, // Add a real phone number
        "name": Constant.userModel!.fullName(), // Add a real customer name
      },
      "customizations": {"title": "Payment for Services", "description": "Payment for XYZ services"},
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Get.to(MercadoPagoScreen(initialURl: data['data']['link']))!.then((value) {
        if (value) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          completeOrder();
        } else {
          ShowToastDialog.showToast("Payment UnSuccessful!!".tr);
        }
      });
    } else {
      print('Payment initialization failed: ${response.body}');
      return null;
    }
  }

  String? _ref;

  void setRef() {
    maths.Random numRef = maths.Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      _ref = "AndroidRef$year$refNumber";
    } else if (Platform.isIOS) {
      _ref = "IOSRef$year$refNumber";
    }
  }

  // payFast
  void payFastPayment({required BuildContext context, required String amount}) {
    PayStackURLGen.getPayHTML(payFastSettingData: payFastModel.value, amount: amount.toString(), userModel: Constant.userModel!).then((
      String? value,
    ) async {
      bool isDone = await Get.to(PayFastScreen(htmlData: value!, payFastSettingData: payFastModel.value));
      if (isDone) {
        Get.back();
        ShowToastDialog.showToast("Payment successfully".tr);
        completeOrder();
      } else {
        Get.back();
        ShowToastDialog.showToast("Payment Failed".tr);
      }
    });
  }

  ///Paytm payment function
  Future<void> getPaytmCheckSum(context, {required double amount}) async {
    // final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    // String getChecksum = "${Constant.globalUrl}payments/getpaytmchecksum";
    //
    // final response = await http.post(
    //   Uri.parse(getChecksum),
    //   headers: {},
    //   body: {"mid": paytmModel.value.paytmMID.toString(), "order_id": orderId, "key_secret": paytmModel.value.pAYTMMERCHANTKEY.toString()},
    // );
    //
    // final data = jsonDecode(response.body);
    // await verifyCheckSum(checkSum: data["code"], amount: amount, orderId: orderId).then((value) {
    //   initiatePayment(amount: amount, orderId: orderId).then((value) {
    //     String callback = "";
    //     if (paytmModel.value.isSandboxEnabled == true) {
    //       callback = "${callback}https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    //     } else {
    //       callback = "${callback}https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    //     }
    //
    //     GetPaymentTxtTokenModel result = value;
    //     startTransaction(context, txnTokenBy: result.body.txnToken, orderId: orderId, amount: amount, callBackURL: callback, isStaging: paytmModel.value.isSandboxEnabled);
    //   });
    // });
  }

  Future<void> startTransaction(
    context, {
    required String txnTokenBy,
    required orderId,
    required double amount,
    required callBackURL,
    required isStaging,
  }) async {
    // try {
    //   var response = AllInOneSdk.startTransaction(
    //     paytmModel.value.paytmMID.toString(),
    //     orderId,
    //     amount.toString(),
    //     txnTokenBy,
    //     callBackURL,
    //     isStaging,
    //     true,
    //     true,
    //   );
    //
    //   response.then((value) {
    //     if (value!["RESPMSG"] == "Txn Success") {
    //       print("txt done!!");
    //       ShowToastDialog.showToast("Payment Successful!!");
    //       completeOrder();
    //     }
    //   }).catchError((onError) {
    //     if (onError is PlatformException) {
    //       Get.back();
    //
    //       ShowToastDialog.showToast(onError.message.toString());
    //     } else {
    //       log("======>>2");
    //       Get.back();
    //       ShowToastDialog.showToast(onError.message.toString());
    //     }
    //   });
    // } catch (err) {
    //   Get.back();
    //   ShowToastDialog.showToast(err.toString());
    // }
  }

  Future verifyCheckSum({required String checkSum, required double amount, required orderId}) async {
    String getChecksum = "${Constant.globalUrl}payments/validatechecksum";
    final response = await http.post(
      Uri.parse(getChecksum),
      headers: {},
      body: {
        "mid": paytmModel.value.paytmMID.toString(),
        "order_id": orderId,
        "key_secret": paytmModel.value.pAYTMMERCHANTKEY.toString(),
        "checksum_value": checkSum,
      },
    );
    final data = jsonDecode(response.body);
    return data['status'];
  }

  Future<GetPaymentTxtTokenModel> initiatePayment({required double amount, required orderId}) async {
    String initiateURL = "${Constant.globalUrl}payments/initiatepaytmpayment";
    String callback = "";
    if (paytmModel.value.isSandboxEnabled == true) {
      callback = "${callback}https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = "${callback}https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response = await http.post(
      Uri.parse(initiateURL),
      headers: {},
      body: {
        "mid": paytmModel.value.paytmMID,
        "order_id": orderId,
        "key_secret": paytmModel.value.pAYTMMERCHANTKEY,
        "amount": amount.toString(),
        "currency": "INR",
        "callback_url": callback,
        "custId": FireStoreUtils.getCurrentUid(),
        "issandbox": paytmModel.value.isSandboxEnabled == true ? "1" : "2",
      },
    );
    log(response.body);
    final data = jsonDecode(response.body);
    if (data["body"]["txnToken"] == null || data["body"]["txnToken"].toString().isEmpty) {
      Get.back();
      ShowToastDialog.showToast("something went wrong, please contact admin.".tr);
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  ///RazorPay payment function
  final Razorpay razorPay = Razorpay();

  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayModel.value.razorpayKey,
      'amount': amount * 100,
      'name': 'GoRide',
      'order_id': orderId,
      "currency": "INR",
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': Constant.userModel!.phoneNumber, 'email': Constant.userModel!.email},
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      razorPay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Successful!!".tr);
    completeOrder();
  }

  void handleExternalWaller(ExternalWalletResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Processing!! via".tr);
  }

  void handlePaymentError(PaymentFailureResponse response) {
    Get.back();
    ShowToastDialog.showToast("Payment Failed!!".tr);
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    final currentDate = DateTime.now();
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  //Midtrans payment
  Future<void> midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) {
      ShowToastDialog.closeLoader();
      if (url != '') {
        Get.to(() => MidtransScreen(initialURl: url))!.then((value) {
          if (value == true) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            completeOrder();
          } else {
            ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
          }
        });
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = const Uuid().v1();
    final url = Uri.parse(
      midTransModel.value.isSandbox! ? 'https://api.sandbox.midtrans.com/v1/payment-links' : 'https://api.midtrans.com/v1/payment-links',
    );

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(midTransModel.value.serverKey!),
      },
      body: jsonEncode({
        'transaction_details': {'order_id': ordersId, 'gross_amount': double.parse(amount.toString()).toInt()},
        'usage_limit': 2,
        "callbacks": {"finish": "https://www.google.com?merchant_order_id=$ordersId"},
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['payment_url'];
    } else {
      ShowToastDialog.showToast("something went wrong, please contact admin.".tr);
      return '';
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  Future<void> orangeMakePayment({required String amount, required BuildContext context}) async {
    reset();
    var id = const Uuid().v4();
    var paymentURL = await fetchToken(context: context, orderId: id, amount: amount, currency: 'USD');
    ShowToastDialog.closeLoader();
    if (paymentURL.toString() != '') {
      Get.to(
        () => OrangeMoneyScreen(
          initialURl: paymentURL,
          accessToken: accessToken,
          amount: amount,
          orangePay: orangeMoneyModel.value,
          orderId: orderId,
          payToken: payToken,
        ),
      )!.then((value) {
        if (value == true) {
          ShowToastDialog.showToast("Payment Successful!!".tr);
          completeOrder();
          ();
        }
      });
    } else {
      ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
    }
  }

  Future fetchToken({required String orderId, required String currency, required BuildContext context, required String amount}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {'grant_type': 'client_credentials'};

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Authorization': "Basic ${orangeMoneyModel.value.auth!}",
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: requestBody,
    );

    // Handle the response

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      // ignore: use_build_context_synchronously
      return await webpayment(context: context, amountData: amount, currency: currency, orderIdData: orderId);
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.".tr);
      return '';
    }
  }

  Future webpayment({
    required String orderIdData,
    required BuildContext context,
    required String currency,
    required String amountData,
  }) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl =
        orangeMoneyModel.value.isSandbox! == true
            ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment'
            : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key": orangeMoneyModel.value.merchantKey ?? '',
      "currency": orangeMoneyModel.value.isSandbox == true ? "OUV" : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url": orangeMoneyModel.value.returnUrl!.toString(),
      "cancel_url": orangeMoneyModel.value.cancelUrl!.toString(),
      "notif_url": orangeMoneyModel.value.notifUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode(requestBody),
    );

    // Handle the response
    if (response.statusCode == 201) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.".tr);
      return '';
    }
  }

  static void reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //XenditPayment
  Future<void> xenditPayment(context, amount) async {
    await createXenditInvoice(amount: amount).then((model) {
      ShowToastDialog.closeLoader();
      if (model.id != null) {
        Get.to(
          () => XenditScreen(initialURl: model.invoiceUrl ?? '', transId: model.id ?? '', apiKey: xenditModel.value.apiKey!.toString()),
        )!.then((value) {
          if (value == true) {
            ShowToastDialog.showToast("Payment Successful!!".tr);
            completeOrder();
            ();
          } else {
            ShowToastDialog.showToast("Payment Unsuccessful!!".tr);
          }
        });
      }
    });
  }

  Future<XenditModel> createXenditInvoice({required var amount}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(xenditModel.value.apiKey!.toString()),
      // 'Cookie': '__cf_bm=yERkrx3xDITyFGiou0bbKY1bi7xEwovHNwxV1vCNbVc-1724155511-1.0.1.1-jekyYQmPCwY6vIJ524K0V6_CEw6O.dAwOmQnHtwmaXO_MfTrdnmZMka0KZvjukQgXu5B.K_6FJm47SGOPeWviQ',
    };

    final body = jsonEncode({
      'external_id': const Uuid().v1(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR', //IDR, PHP, THB, VND, MYR
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        return model;
      } else {
        return XenditModel();
      }
    } catch (e) {
      return XenditModel();
    }
  }
}
