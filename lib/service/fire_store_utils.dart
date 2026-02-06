import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/models/brands_model.dart';
import 'package:customer/models/rental_order_model.dart';
import 'package:customer/models/rental_package_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/zone_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import '../constant/constant.dart';
import '../models/attributes_model.dart';
import '../models/cab_order_model.dart';
import '../models/cashback_redeem_model.dart';
import '../models/category_model.dart';
import '../models/coupon_model.dart';
import '../models/currency_model.dart';
import '../models/favorite_ondemand_service_model.dart';
import '../models/gift_cards_model.dart';
import '../models/advertisement_model.dart';
import '../models/banner_model.dart';
import '../models/cashback_model.dart';
import '../models/conversation_model.dart';
import '../models/dine_in_booking_model.dart';
import '../models/email_template_model.dart';
import '../models/favourite_item_model.dart';
import '../models/favourite_model.dart';
import '../models/gift_cards_order_model.dart';
import '../models/inbox_model.dart';
import '../models/mail_setting.dart';
import '../models/notification_model.dart';
import '../models/on_boarding_model.dart';
import '../models/onprovider_order_model.dart';
import '../models/order_model.dart';
import '../models/parcel_category.dart';
import '../models/parcel_order_model.dart';
import '../models/parcel_weight_model.dart';
import '../models/payment_model/cod_setting_model.dart';
import '../models/payment_model/flutter_wave_model.dart';
import '../models/payment_model/mercado_pago_model.dart';
import '../models/payment_model/mid_trans.dart';
import '../models/payment_model/orange_money.dart';
import '../models/payment_model/pay_fast_model.dart';
import '../models/payment_model/pay_stack_model.dart';
import '../models/payment_model/paypal_model.dart';
import '../models/payment_model/paytm_model.dart';
import '../models/payment_model/razorpay_model.dart';
import '../models/payment_model/stripe_model.dart';
import '../models/payment_model/wallet_setting_model.dart';
import '../models/payment_model/xendit.dart';
import '../models/popular_destination.dart';
import '../models/product_model.dart';
import '../models/provider_serivce_model.dart';
import '../models/rating_model.dart';
import '../models/referral_model.dart';
import '../models/rental_vehicle_type.dart';
import '../models/review_attribute_model.dart';
import '../models/section_model.dart';
import '../models/story_model.dart';
import '../models/tax_model.dart';
import '../models/vehicle_type.dart';
import '../models/vendor_category_model.dart';
import '../models/vendor_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/worker_model.dart';
import '../screen_ui/multi_vendor_service/chat_screens/ChatVideoContainer.dart';
import '../themes/app_them_data.dart';
import '../themes/show_toast_dialog.dart';
import '../utils/preferences.dart';
import '../widget/geoflutterfire/src/geoflutterfire.dart';
import '../widget/geoflutterfire/src/models/point.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static String getCurrentUid() {
    return auth.FirebaseAuth.instance.currentUser!.uid;
  }

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (auth.FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExistOrNot(auth.FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  static Future<bool> userExistOrNot(String uid) async {
    bool isExist = false;

    await fireStore
        .collection(CollectionName.users)
        .doc(uid)
        .get()
        .then((value) {
          if (value.exists) {
            isExist = true;
          } else {
            isExist = false;
          }
        })
        .catchError((error) {
          log("Failed to check user exist: $error");
          isExist = false;
        });
    return isExist;
  }

  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
          if (value.exists) {
            userModel = UserModel.fromJson(value.data()!);
          }
        })
        .catchError((error) {
          log("Failed to update user: $error");
          userModel = null;
        });
    return userModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(userModel.toJson())
        .whenComplete(() {
          Constant.userModel = userModel;
          isUpdate = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isUpdate = false;
        });
    return isUpdate;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "customer")
        .get()
        .then((value) {
          for (var element in value.docs) {
            OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
            onBoardingModel.add(documentModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return onBoardingModel;
  }

  static Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
            airPortList.add(ariPortModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return airPortList;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore.collection(CollectionName.referral).doc(ratingModel.id).set(ratingModel.toJson());
    } catch (e, s) {
      print('FireStoreUtils.referralAdd $e $s');
      return "Couldn't review".tr;
    }
    return null;
  }

  static Future<ReferralModel?> getReferralUserByCode(String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore.collection(CollectionName.referral).where("referralCode", isEqualTo: referralCode).get().then((value) {
        if (value.docs.isNotEmpty) {
          referralModel = ReferralModel.fromJson(value.docs.first.data());
        }
      });
    } catch (e, s) {
      print('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<List<SectionModel>> getSections() async {
    List<SectionModel> sections = [];
    QuerySnapshot<Map<String, dynamic>> productsQuery = await fireStore.collection(CollectionName.sections).where("isActive", isEqualTo: true).get();

    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        sections.add(SectionModel.fromJson(document.data()));
      } catch (e) {
        print('**-FireStoreUtils.getSection Parse error $e');
      }
    });
    return sections;
  }

  static Future<List<dynamic>> getSectionBannerList() async {
    List<dynamic> sections = [];
    await fireStore.collection(CollectionName.settings).doc("AppHomeBanners").get().then((value) {
      if (value.exists) {
        sections = value.data()!['banners'] ?? [];
      }
    });
    return sections;
  }

  static Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currency;
    await fireStore.collection(CollectionName.currency).where("isActive", isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        currency = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currency;
  }

  static Future<List<AdvertisementModel>> getAllAdvertisement() async {
    List<AdvertisementModel> advertisementList = [];
    await fireStore
        .collection(CollectionName.advertisements)
        .where('status', isEqualTo: 'approved')
        .where('paymentStatus', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThan: DateTime.now())
        .orderBy('priority', descending: false)
        .get()
        .then((value) {
          for (var element in value.docs) {
            AdvertisementModel advertisementModel = AdvertisementModel.fromJson(element.data());
            if (advertisementModel.isPaused == null || advertisementModel.isPaused == false) {
              advertisementList.add(advertisementModel);
            }
          }
        });
    return advertisementList;
  }

  static Future<List<FavouriteModel>> getFavouriteRestaurant() async {
    List<FavouriteModel> favouriteList = [];
    await fireStore.collection(CollectionName.favoriteVendor).where('user_id', isEqualTo: getCurrentUid()).where("section_id", isEqualTo: Constant.sectionConstantModel!.id).get().then((value) {
      for (var element in value.docs) {
        FavouriteModel favouriteModel = FavouriteModel.fromJson(element.data());
        favouriteList.add(favouriteModel);
      }
    });
    log("CollectionName.favoriteRestaurant :: ${favouriteList.length}");
    return favouriteList;
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    EmailTemplateModel? emailTemplateModel;
    await fireStore.collection(CollectionName.emailTemplates).where('type', isEqualTo: type).get().then((value) {
      print("------>");
      if (value.docs.isNotEmpty) {
        print(value.docs.first.data());
        emailTemplateModel = EmailTemplateModel.fromJson(value.docs.first.data());
      }
    });
    return emailTemplateModel;
  }

  static Future<List<CashbackModel>> getCashbackList() async {
    List<CashbackModel> cashbackList = [];
    try {
      await fireStore
          .collection(CollectionName.cashback)
          .where('isEnabled', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.now())
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .get()
          .then((event) {
            if (event.docs.isNotEmpty) {
              for (var element in event.docs) {
                CashbackModel cashbackModel = CashbackModel.fromJson(element.data());
                if (cashbackModel.customerIds == null || cashbackModel.customerIds?.contains(FireStoreUtils.getCurrentUid()) == true) {
                  cashbackList.add(cashbackModel);
                }
              }
            }
          });
    } catch (error, stackTrace) {
      log('Error fetching redeemed cashback data: $error', stackTrace: stackTrace);
    }

    return cashbackList;
  }

  static Future addDriverInbox(InboxModel inboxModel) async {
    return await fireStore.collection("chat_driver").doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addDriverChat(ConversationModel conversationModel) async {
    return await fireStore.collection("chat_driver").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addRestaurantInbox(InboxModel inboxModel) async {
    return await fireStore.collection("chat_store").doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addRestaurantChat(ConversationModel conversationModel) async {
    return await fireStore.collection("chat_store").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addWorkerInbox(InboxModel inboxModel) async {
    return await fireStore.collection("chat_worker").doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addWorkerChat(ConversationModel conversationModel) async {
    return await fireStore.collection("chat_worker").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addProviderInbox(InboxModel inboxModel) async {
    return await fireStore.collection("chat_provider").doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addProviderChat(ConversationModel conversationModel) async {
    return await fireStore.collection("chat_provider").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future<List<TaxModel>?> getTaxList(String? sectionId) async {
    List<TaxModel> taxList = [];
    List<Placemark> placeMarks = await placemarkFromCoordinates(Constant.selectedLocation.location!.latitude ?? 0.0, Constant.selectedLocation.location!.longitude ?? 0.0);
    await fireStore
        .collection(CollectionName.tax)
        .where('sectionId', isEqualTo: sectionId)
        .where('country', isEqualTo: placeMarks.first.country)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            TaxModel taxModel = TaxModel.fromJson(element.data());
            taxList.add(taxModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });

    return taxList;
  }

  static Future<List<DineInBookingModel>> getDineInBooking(bool isUpcoming) async {
    List<DineInBookingModel> list = [];

    if (isUpcoming) {
      await fireStore
          .collection(CollectionName.bookedTable)
          .where('authorID', isEqualTo: getCurrentUid())
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .get()
          .then((value) {
            for (var element in value.docs) {
              DineInBookingModel taxModel = DineInBookingModel.fromJson(element.data());
              list.add(taxModel);
            }
          })
          .catchError((error) {
            log(error.toString());
          });
    } else {
      await fireStore
          .collection(CollectionName.bookedTable)
          .where('authorID', isEqualTo: getCurrentUid())
          .where('date', isLessThan: Timestamp.now())
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .get()
          .then((value) {
            for (var element in value.docs) {
              DineInBookingModel taxModel = DineInBookingModel.fromJson(element.data());
              list.add(taxModel);
            }
          })
          .catchError((error) {
            log(error.toString());
          });
    }

    return list;
  }

  static Future<List<VendorCategoryModel>> getHomeVendorCategory() async {
    List<VendorCategoryModel> list = [];
    await fireStore
        .collection(CollectionName.vendorCategories)
        .where("section_id", isEqualTo: Constant.sectionConstantModel!.id)
        .where("show_in_homepage", isEqualTo: true)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            VendorCategoryModel walletTransactionModel = VendorCategoryModel.fromJson(element.data());
            list.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return list;
  }

  static Future<List<ProductModel>> getProductListByBrandId(String brandId) async {
    List<ProductModel> list = [];
    await fireStore
        .collection(CollectionName.vendorProducts)
        .where('brandID', isEqualTo: brandId)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            ProductModel walletTransactionModel = ProductModel.fromJson(element.data());
            list.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return list;
  }

  static Future<List<BannerModel>> getHomeBottomBanner() async {
    List<BannerModel> bannerList = [];
    await fireStore
        .collection(CollectionName.bannerItems)
        .where("is_publish", isEqualTo: true)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where("position", isEqualTo: "middle")
        .orderBy("set_order", descending: false)
        .get()
        .then((value) {
          for (var element in value.docs) {
            BannerModel bannerHome = BannerModel.fromJson(element.data());
            bannerList.add(bannerHome);
          }
        });
    return bannerList;
  }

  static Future<List<BrandsModel>> getBrandList() async {
    List<BrandsModel> brandList = [];
    await fireStore.collection(CollectionName.brands).where("is_publish", isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        BrandsModel bannerHome = BrandsModel.fromJson(element.data());
        brandList.add(bannerHome);
      }
    });
    return brandList;
  }

  static Future<bool?> setBookedOrder(DineInBookingModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.bookedTable)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<List> getVendorCuisines(String id) async {
    List tagList = [];
    List prodTagList = [];
    QuerySnapshot<Map<String, dynamic>> productsQuery = await fireStore.collection(CollectionName.vendorProducts).where('vendorID', isEqualTo: id).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      if (document.data().containsKey("categoryID") && document.data()['categoryID'].toString().isNotEmpty) {
        prodTagList.add(document.data()['categoryID']);
      }
    });
    QuerySnapshot<Map<String, dynamic>> catQuery = await fireStore.collection(CollectionName.vendorCategories).where('publish', isEqualTo: true).get();
    await Future.forEach(catQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      Map<String, dynamic> catDoc = document.data();
      if (catDoc.containsKey("id") && catDoc['id'].toString().isNotEmpty && catDoc.containsKey("title") && catDoc['title'].toString().isNotEmpty && prodTagList.contains(catDoc['id'])) {
        tagList.add(catDoc['title']);
      }
    });
    return tagList;
  }

  static Future<List<FavouriteItemModel>> getFavouriteItem() async {
    List<FavouriteItemModel> favouriteList = [];
    await fireStore.collection(CollectionName.favoriteItem).where('user_id', isEqualTo: getCurrentUid()).where("section_id", isEqualTo: Constant.sectionConstantModel!.id).get().then((value) {
      for (var element in value.docs) {
        FavouriteItemModel favouriteModel = FavouriteItemModel.fromJson(element.data());
        favouriteList.add(favouriteModel);
      }
    });
    return favouriteList;
  }

  static Future<VendorModel?> getVendorById(String vendorId) async {
    VendorModel? vendorModel;
    try {
      await fireStore.collection(CollectionName.vendors).doc(vendorId).get().then((value) {
        if (value.exists) {
          vendorModel = VendorModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorModel;
  }

  static Future<ProductModel?> getProductById(String productId) async {
    ProductModel? vendorCategoryModel;
    try {
      await fireStore.collection(CollectionName.vendorProducts).doc(productId).get().then((value) {
        if (value.exists) {
          vendorCategoryModel = ProductModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<List<GiftCardsModel>> getGiftCard() async {
    List<GiftCardsModel> giftCardModelList = [];
    QuerySnapshot<Map<String, dynamic>> currencyQuery = await fireStore.collection(CollectionName.giftCards).where("isEnable", isEqualTo: true).get();
    await Future.forEach(currencyQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        log(document.data().toString());
        giftCardModelList.add(GiftCardsModel.fromJson(document.data()));
      } catch (e) {
        debugPrint('FireStoreUtils.get Currency Parse error $e');
      }
    });
    return giftCardModelList;
  }

  static Future<bool?> setWalletTransaction(WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.wallet)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<void> getSettings() async {
    try {
      final restaurantSnap = await FirebaseFirestore.instance.collection(CollectionName.settings).doc('vendor').get();

      if (restaurantSnap.exists && restaurantSnap.data() != null) {
        Constant.isSubscriptionModelApplied = restaurantSnap.data()?['subscription_model'] ?? false;
      } else {
        Constant.isSubscriptionModelApplied = false;
      }

      fireStore.collection(CollectionName.settings).doc("DriverNearBy").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.distanceType = event.data()?["distanceType"] ?? "km";
          Constant.isEnableOTPTripStart = event.data()?["enableOTPTripStart"] ?? false;
          Constant.isEnableOTPTripStartForRental = event.data()?["enableOTPTripStartForRental"] ?? false;
        }
      });

      fireStore.collection(CollectionName.settings).doc("maintenance_settings").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.isMaintenanceModeForCustomer = event.data()?["isMaintenanceModeForCustomer"] ?? false;
        }
      });

      final globalSettingsSnap = await FirebaseFirestore.instance.collection(CollectionName.settings).doc("globalSettings").get();

      if (globalSettingsSnap.exists && globalSettingsSnap.data() != null) {
        Constant.isEnableAdsFeature = globalSettingsSnap.data()?['isEnableAdsFeature'] ?? false;
        Constant.isSelfDeliveryFeature = globalSettingsSnap.data()?['isSelfDelivery'] ?? false;
        Constant.defaultCountryCode = globalSettingsSnap.data()?['defaultCountryCode'] ?? '';
        Constant.defaultCountry = globalSettingsSnap.data()?['defaultCountry'] ?? '';

        String? colorStr = globalSettingsSnap.data()?['app_customer_color'];
        if (colorStr != null && colorStr.isNotEmpty) {
          AppThemeData.primary300 = Color(int.parse(colorStr.replaceFirst("#", "0xff")));
        }
      }

      fireStore.collection(CollectionName.settings).doc("googleMapKey").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.mapAPIKey = event.data()?["key"] ?? "";
        }
      });
      fireStore.collection(CollectionName.settings).doc("placeHolderImage").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.placeHolderImage = event.data()?["image"] ?? "";
        }
      });

      fireStore.collection(CollectionName.settings).doc("notification_setting").snapshots().listen((event) {
        if (event.exists) {
          Constant.senderId = event.data()?["senderId"];
          Constant.jsonNotificationFileURL = event.data()?["serviceJson"];
        }
      });

      final cashbackSnap = await fireStore.collection(CollectionName.settings).doc("cashbackOffer").get();

      if (cashbackSnap.exists && cashbackSnap.data() != null) {
        Constant.isCashbackActive = cashbackSnap.data()?["isEnable"] ?? false;
      } else {
        Constant.isCashbackActive = false;
      }

      final driverNearBySnap = await fireStore.collection(CollectionName.settings).doc("DriverNearBy").get();

      if (driverNearBySnap.exists && driverNearBySnap.data() != null) {
        Constant.selectedMapType = driverNearBySnap.data()?["selectedMapType"] ?? "";
        Constant.mapType = driverNearBySnap.data()?["mapType"] ?? "";
      }

      fireStore.collection(CollectionName.settings).doc("privacyPolicy").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.privacyPolicy = event.data()?["privacy_policy"] ?? "";
        }
      });

      fireStore.collection(CollectionName.settings).doc("termsAndConditions").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.termsAndConditions = event.data()?["termsAndConditions"] ?? "";
        }
      });

      fireStore.collection(CollectionName.settings).doc("walletSettings").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.walletSetting = event.data()?["isEnabled"] ?? false;
        }
      });

      fireStore.collection(CollectionName.settings).doc("Version").snapshots().listen((event) {
        if (event.exists && event.data() != null) {
          Constant.googlePlayLink = event.data()?["googlePlayLink"] ?? '';
          Constant.appStoreLink = event.data()?["appStoreLink"] ?? '';
          Constant.appVersion = event.data()?["app_version"] ?? '';
          Constant.websiteUrl = event.data()?["websiteUrl"] ?? '';
        }
      });

      final storySnap = await fireStore.collection(CollectionName.settings).doc('story').get();

      if (storySnap.exists && storySnap.data() != null) {
        Constant.storyEnable = storySnap.data()?['isEnabled'] ?? false;
      } else {
        Constant.storyEnable = false;
      }

      final emailSnap = await fireStore.collection(CollectionName.settings).doc("emailSetting").get();

      if (emailSnap.exists && emailSnap.data() != null) {
        Constant.mailSettings = MailSettings.fromJson(emailSnap.data()!);
      }

      final specialDiscountSnap = await fireStore.collection(CollectionName.settings).doc("specialDiscountOffer").get();

      if (specialDiscountSnap.exists && specialDiscountSnap.data() != null) {
        Constant.specialDiscountOffer = specialDiscountSnap.data()?["isEnable"] ?? false;
      } else {
        Constant.specialDiscountOffer = false;
      }
    } catch (e) {
      log("getSettings() Error: $e");
    }
  }

  static Future<List<GiftCardsOrderModel>> getGiftHistory() async {
    List<GiftCardsOrderModel> giftCardsOrderList = [];
    await fireStore.collection(CollectionName.giftPurchases).where("userid", isEqualTo: FireStoreUtils.getCurrentUid()).get().then((value) {
      for (var element in value.docs) {
        GiftCardsOrderModel giftCardsOrderModel = GiftCardsOrderModel.fromJson(element.data());
        giftCardsOrderList.add(giftCardsOrderModel);
      }
    });
    return giftCardsOrderList;
  }

  static Future<List<OrderModel>> getAllOrder() async {
    List<OrderModel> list = [];

    print("Current UID: ${getCurrentUid()}");
    print("Section ID: ${Constant.sectionConstantModel?.id}");

    try {
      final snapshot =
          await fireStore
              .collection(CollectionName.vendorOrders)
              .where("authorID", isEqualTo: getCurrentUid())
              .where("section_id", isEqualTo: Constant.sectionConstantModel!.id)
              .orderBy("createdAt", descending: true)
              .get();

      print("Snapshot size: ${snapshot.docs.length}");

      for (var element in snapshot.docs) {
        OrderModel order = OrderModel.fromJson(element.data());
        print("Order fetched: ${order.id}"); // or other fields
        list.add(order);
      }

      print("Total Orders added to list: ${list.length}");
    } catch (e) {
      print("Error fetching orders: $e");
    }

    return list;
  }

  static Future<RatingModel?> getOrderReviewsByID(String orderId, String productID) async {
    RatingModel? ratingModel;

    await fireStore
        .collection(CollectionName.itemsReview)
        .where('orderid', isEqualTo: orderId)
        .where('productId', isEqualTo: productID)
        .get()
        .then((value) {
          if (value.docs.isNotEmpty) {
            ratingModel = RatingModel.fromJson(value.docs.first.data());
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return ratingModel;
  }

  static Future<VendorCategoryModel?> getVendorCategoryByCategoryId(String categoryId) async {
    VendorCategoryModel? vendorCategoryModel;
    try {
      await fireStore.collection(CollectionName.vendorCategories).doc(categoryId).get().then((value) {
        if (value.exists) {
          vendorCategoryModel = VendorCategoryModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<ReviewAttributeModel?> getVendorReviewAttribute(String attributeId) async {
    ReviewAttributeModel? vendorCategoryModel;
    try {
      await fireStore.collection(CollectionName.reviewAttributes).doc(attributeId).get().then((value) {
        if (value.exists) {
          vendorCategoryModel = ReviewAttributeModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  // static Future<bool?> setRatingModel(RatingModel ratingModel) async {
  //   bool isAdded = false;
  //   await fireStore
  //       .collection(CollectionName.itemsReview)
  //       .doc(ratingModel.id)
  //       .set(ratingModel.toJson())
  //       .then((value) {
  //         isAdded = true;
  //       })
  //       .catchError((error) {
  //         log("Failed to update user: $error");
  //         isAdded = false;
  //       });
  //   return isAdded;
  // }

  static Future<VendorModel?> updateVendor(VendorModel vendor) async {
    return await fireStore.collection(CollectionName.vendors).doc(vendor.id).set(vendor.toJson()).then((document) {
      return vendor;
    });
  }

  static Future<bool?> setProduct(ProductModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.vendorProducts)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<ReferralModel?> getReferralUserBy() async {
    ReferralModel? referralModel;
    try {
      await fireStore.collection(CollectionName.referral).doc(getCurrentUid()).get().then((value) {
        referralModel = ReferralModel.fromJson(value.data()!);
      });
    } catch (e, s) {
      print('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<List<ProductModel>> getProductByVendorId(String vendorId) async {
    String selectedFoodType = Preferences.getString(Preferences.foodDeliveryType, defaultValue: "Delivery");
    List<ProductModel> list = [];
    log("GetProductByVendorId :: $selectedFoodType");
    if (selectedFoodType == "TakeAway") {
      await fireStore
          .collection(CollectionName.vendorProducts)
          .where("vendorID", isEqualTo: vendorId)
          .where('publish', isEqualTo: true)
          .orderBy("createdAt", descending: false)
          .get()
          .then((value) {
            for (var element in value.docs) {
              ProductModel productModel = ProductModel.fromJson(element.data());
              list.add(productModel);
            }
          })
          .catchError((error) {
            log(error.toString());
          });
    } else {
      await fireStore
          .collection(CollectionName.vendorProducts)
          .where("vendorID", isEqualTo: vendorId)
          .where("takeawayOption", isEqualTo: false)
          .where('publish', isEqualTo: true)
          .orderBy("createdAt", descending: false)
          .get()
          .then((value) {
            for (var element in value.docs) {
              ProductModel productModel = ProductModel.fromJson(element.data());
              list.add(productModel);
            }
          })
          .catchError((error) {
            log(error.toString());
          });
    }

    return list;
  }

  static Future<DeliveryCharge?> getDeliveryCharge() async {
    DeliveryCharge? deliveryCharge;
    try {
      await fireStore.collection(CollectionName.settings).doc("DeliveryCharge").get().then((value) {
        if (value.exists) {
          deliveryCharge = DeliveryCharge.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return deliveryCharge;
  }

  static Future<List<CouponModel>> getAllVendorPublicCoupons(String vendorId) async {
    List<CouponModel> coupon = [];

    await fireStore
        .collection(CollectionName.coupons)
        .where("vendorID", isEqualTo: vendorId)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel taxModel = CouponModel.fromJson(element.data());
            coupon.add(taxModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    print("coupon :::::::::::::::::${coupon.length}");
    return coupon;
  }

  static Future<List<CouponModel>> getAllVendorCoupons(String vendorId) async {
    List<CouponModel> coupon = [];

    await fireStore
        .collection(CollectionName.coupons)
        .where("vendorID", isEqualTo: vendorId)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel taxModel = CouponModel.fromJson(element.data());
            coupon.add(taxModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    print("coupon :::::::::::::::::${coupon.length}");
    return coupon;
  }

  static Future<List<CashbackModel>> getAllCashbak() async {
    List<CashbackModel> cashbackList = [];
    await fireStore
        .collection(CollectionName.cashback)
        .get()
        .then((value) {
          cashbackList =
              value.docs.map((doc) {
                return CashbackModel.fromJson(doc.data());
              }).toList();
        })
        .catchError((error) {
          log(error.toString());
        });

    return cashbackList;
  }

  static Future<List<CashbackRedeemModel>> getRedeemedCashbacks(String cashbackId) async {
    List<CashbackRedeemModel> redeemedDocs = [];

    try {
      await fireStore.collection(CollectionName.cashbackRedeem).where('userId', isEqualTo: FireStoreUtils.getCurrentUid()).where('cashbackId', isEqualTo: cashbackId).get().then((value) {
        redeemedDocs =
            value.docs.map((doc) {
              return CashbackRedeemModel.fromJson(doc.data());
            }).toList();
      });
    } catch (error, stackTrace) {
      log('Error fetching redeemed cashback data: $error', stackTrace: stackTrace);
    }

    return redeemedDocs;
  }

  static Future<bool?> setCashbackRedeemModel(CashbackRedeemModel cashbackRedeemModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.cashbackRedeem)
        .doc(cashbackRedeemModel.id)
        .set(cashbackRedeemModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.vendorOrders)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
          isAdded = true;
        })
        .catchError((error) {
          log("Failed to update user: $error");
          isAdded = false;
        });
    return isAdded;
  }

  static Future<List<CouponModel>> getOfferByVendorId(String vendorId) async {
    List<CouponModel> couponList = [];
    await fireStore
        .collection(CollectionName.coupons)
        .where("vendorID", isEqualTo: vendorId)
        .where("isEnabled", isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel favouriteModel = CouponModel.fromJson(element.data());
            couponList.add(favouriteModel);
          }
        });
    return couponList;
  }

  static Future<List<AttributesModel>?> getAttributes() async {
    List<AttributesModel> attributeList = [];
    await fireStore.collection(CollectionName.vendorAttributes).get().then((value) {
      for (var element in value.docs) {
        AttributesModel favouriteModel = AttributesModel.fromJson(element.data());
        attributeList.add(favouriteModel);
      }
    });
    return attributeList;
  }

  static Future<VendorCategoryModel?> getVendorCategoryById(String categoryId) async {
    VendorCategoryModel? vendorCategoryModel;
    try {
      await fireStore.collection(CollectionName.vendorCategories).doc(categoryId).get().then((value) {
        if (value.exists) {
          vendorCategoryModel = VendorCategoryModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return vendorCategoryModel;
  }

  static Future<List<RatingModel>> getVendorReviews(String vendorId) async {
    List<RatingModel> ratingList = [];
    await fireStore.collection(CollectionName.itemsReview).where('VendorId', isEqualTo: vendorId).get().then((value) {
      for (var element in value.docs) {
        RatingModel giftCardsOrderModel = RatingModel.fromJson(element.data());
        ratingList.add(giftCardsOrderModel);
      }
    });
    return ratingList;
  }

  static Future getPaymentSettingsData() async {
    await fireStore.collection(CollectionName.settings).doc("payFastSettings").get().then((value) async {
      if (value.exists) {
        PayFastModel payFastModel = PayFastModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.payFastSettings, jsonEncode(payFastModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("MercadoPago").get().then((value) async {
      if (value.exists) {
        MercadoPagoModel mercadoPagoModel = MercadoPagoModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.mercadoPago, jsonEncode(mercadoPagoModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("paypalSettings").get().then((value) async {
      if (value.exists) {
        PayPalModel payPalModel = PayPalModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.paypalSettings, jsonEncode(payPalModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("stripeSettings").get().then((value) async {
      if (value.exists) {
        StripeModel stripeModel = StripeModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.stripeSettings, jsonEncode(stripeModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("flutterWave").get().then((value) async {
      if (value.exists) {
        FlutterWaveModel flutterWaveModel = FlutterWaveModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.flutterWave, jsonEncode(flutterWaveModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("payStack").get().then((value) async {
      if (value.exists) {
        PayStackModel payStackModel = PayStackModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.payStack, jsonEncode(payStackModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("PaytmSettings").get().then((value) async {
      if (value.exists) {
        PaytmModel paytmModel = PaytmModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.paytmSettings, jsonEncode(paytmModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("walletSettings").get().then((value) async {
      if (value.exists) {
        WalletSettingModel walletSettingModel = WalletSettingModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.walletSettings, jsonEncode(walletSettingModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("razorpaySettings").get().then((value) async {
      if (value.exists) {
        RazorPayModel razorPayModel = RazorPayModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.razorpaySettings, jsonEncode(razorPayModel.toJson()));
      }
    });
    await fireStore.collection(CollectionName.settings).doc("CODSettings").get().then((value) async {
      if (value.exists) {
        CodSettingModel codSettingModel = CodSettingModel.fromJson(value.data()!);
        await Preferences.setString(Preferences.codSettings, jsonEncode(codSettingModel.toJson()));
      }
    });

    await fireStore.collection(CollectionName.settings).doc("midtrans_settings").get().then((value) async {
      if (value.exists) {
        MidTrans midTrans = MidTrans.fromJson(value.data()!);
        await Preferences.setString(Preferences.midTransSettings, jsonEncode(midTrans.toJson()));
      }
    });

    await fireStore.collection(CollectionName.settings).doc("orange_money_settings").get().then((value) async {
      if (value.exists) {
        OrangeMoney orangeMoney = OrangeMoney.fromJson(value.data()!);
        await Preferences.setString(Preferences.orangeMoneySettings, jsonEncode(orangeMoney.toJson()));
      }
    });

    await fireStore.collection(CollectionName.settings).doc("xendit_settings").get().then((value) async {
      if (value.exists) {
        Xendit xendit = Xendit.fromJson(value.data()!);
        await Preferences.setString(Preferences.xenditSettings, jsonEncode(xendit.toJson()));
      }
    });
  }

  static Future<bool?> updateUserWallet({required String amount, required String userId}) async {
    bool isAdded = false;
    await getUserProfile(userId).then((value) async {
      if (value != null) {
        UserModel userModel = value;
        print("Old Wallet Amount: ${userModel.walletAmount}");
        print("Amount to Add: $amount");
        userModel.walletAmount = double.parse(userModel.walletAmount.toString()) + double.parse(amount);
        await FireStoreUtils.updateUser(userModel).then((value) {
          isAdded = value;
        });
      }
    });
    return isAdded;
  }

  static StreamController<List<VendorModel>>? getNearestVendorByCategoryController;

  static Stream<List<VendorModel>> getAllNearestRestaurantByCategoryId({bool? isDining, required String categoryId}) async* {
    try {
      getNearestVendorByCategoryController = StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];
      Query<Map<String, dynamic>> query =
          isDining == true
              ? fireStore.collection(CollectionName.vendors).where('categoryID', arrayContains: categoryId).where("enabledDiveInFuture", isEqualTo: true)
              : fireStore.collection(CollectionName.vendors).where('categoryID', arrayContains: categoryId);

      GeoFirePoint center = Geoflutterfire().point(latitude: Constant.selectedLocation.location!.latitude ?? 0.0, longitude: Constant.selectedLocation.location!.longitude ?? 0.0);
      String field = 'g';

      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(center: center, radius: double.parse(Constant.sectionConstantModel!.nearByRadius.toString()), field: field, strictMode: true);

      stream.listen((List<DocumentSnapshot> documentList) async {
        vendorList.clear();
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          VendorModel vendorModel = VendorModel.fromJson(data);
          if ((Constant.isSubscriptionModelApplied == true || vendorModel.adminCommission?.isEnabled == true) && vendorModel.subscriptionPlan != null) {
            if (vendorModel.subscriptionTotalOrders == "-1") {
              vendorList.add(vendorModel);
            } else {
              if ((vendorModel.subscriptionExpiryDate != null && vendorModel.subscriptionExpiryDate!.toDate().isBefore(DateTime.now()) == false) || vendorModel.subscriptionPlan?.expiryDay == '-1') {
                if (vendorModel.subscriptionTotalOrders != '0') {
                  vendorList.add(vendorModel);
                }
              }
            }
          } else {
            vendorList.add(vendorModel);
          }
        }
        getNearestVendorByCategoryController!.sink.add(vendorList);
      });

      yield* getNearestVendorByCategoryController!.stream;
    } catch (e) {
      print(e);
    }
  }

  static StreamController<List<VendorModel>>? getNearestVendorController;

  static Stream<List<VendorModel>> getAllNearestRestaurant({bool? isDining}) async* {
    try {
      getNearestVendorController = StreamController<List<VendorModel>>.broadcast();
      List<VendorModel> vendorList = [];
      Query<Map<String, dynamic>> query =
          isDining == true
              ? fireStore.collection(CollectionName.vendors).where('section_id', isEqualTo: Constant.sectionConstantModel!.id).where("enabledDiveInFuture", isEqualTo: true)
              : fireStore.collection(CollectionName.vendors).where('section_id', isEqualTo: Constant.sectionConstantModel!.id);

      GeoFirePoint center = Geoflutterfire().point(latitude: Constant.selectedLocation.location!.latitude ?? 0.0, longitude: Constant.selectedLocation.location!.longitude ?? 0.0);
      String field = 'g';

      Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
          .collection(collectionRef: query)
          .within(center: center, radius: double.parse(Constant.sectionConstantModel!.nearByRadius.toString()), field: field, strictMode: true);

      stream.listen((List<DocumentSnapshot> documentList) async {
        vendorList.clear();
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          VendorModel vendorModel = VendorModel.fromJson(data);
          if ((Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel!.adminCommision?.isEnabled == true) && vendorModel.subscriptionPlan != null) {
            if (vendorModel.subscriptionTotalOrders == "-1") {
              vendorList.add(vendorModel);
            } else {
              if ((vendorModel.subscriptionExpiryDate != null && vendorModel.subscriptionExpiryDate!.toDate().isBefore(DateTime.now()) == false) || vendorModel.subscriptionPlan?.expiryDay == "-1") {
                if (vendorModel.subscriptionTotalOrders != '0') {
                  vendorList.add(vendorModel);
                }
              }
            }
          } else {
            vendorList.add(vendorModel);
          }
        }
        getNearestVendorController!.sink.add(vendorList);
      });

      yield* getNearestVendorController!.stream;
    } catch (e) {
      print(e);
    }
  }

  static Future<List<VendorCategoryModel>> getHomePageShowCategory() async {
    List<VendorCategoryModel> vendorCategoryList = [];
    await fireStore
        .collection(CollectionName.vendorCategories)
        .where("section_id", isEqualTo: Constant.sectionConstantModel!.id)
        .where("show_in_homepage", isEqualTo: true)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            VendorCategoryModel vendorCategoryModel = VendorCategoryModel.fromJson(element.data());
            vendorCategoryList.add(vendorCategoryModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return vendorCategoryList;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionList = [];
    log("FireStoreUtils.getCurrentUid() :: ${FireStoreUtils.getCurrentUid()}");
    await fireStore
        .collection(CollectionName.wallet)
        .where('user_id', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('date', descending: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            WalletTransactionModel walletTransactionModel = WalletTransactionModel.fromJson(element.data());
            walletTransactionList.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return walletTransactionList;
  }

  static Future<List<ProductModel>> getProductListByCategoryId(String categoryId) async {
    List<ProductModel> productList = [];
    List<ProductModel> categorybyProductList = [];
    QuerySnapshot<Map<String, dynamic>> currencyQuery = await fireStore.collection(CollectionName.vendorProducts).where('categoryID', isEqualTo: categoryId).where('publish', isEqualTo: true).get();
    await Future.forEach(currencyQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        productList.add(ProductModel.fromJson(document.data()));
      } catch (e) {
        print('FireStoreUtils.getCurrencys Parse error $e');
      }
    });

    List<VendorModel?> vendorList = await getAllStoresFuture();
    List<ProductModel> allProduct = <ProductModel>[];

    for (var vendor in vendorList) {
      await getAllProducts(vendor!.id.toString()).then((value) {
        if (Constant.isSubscriptionModelApplied == true || vendor.adminCommission?.isEnabled == true) {
          if (vendor.subscriptionPlan != null && Constant.isExpire(vendor) == false) {
            if (vendor.subscriptionPlan?.itemLimit == '-1') {
              allProduct.addAll(value);
            } else {
              int selectedProduct = value.length < int.parse(vendor.subscriptionPlan?.itemLimit ?? '0') ? (value.isEmpty ? 0 : (value.length)) : int.parse(vendor.subscriptionPlan?.itemLimit ?? '0');
              allProduct.addAll(value.sublist(0, selectedProduct));
            }
          }
        } else {
          allProduct.addAll(value);
        }
      });
    }

    for (var element in productList) {
      bool productIsInList = allProduct.any((product) => product.id == element.id);
      if (productIsInList) {
        categorybyProductList.add(element);
      }
    }

    return categorybyProductList;
  }

  static Future<List<ProductModel>> getAllProducts(String vendorId) async {
    List<ProductModel> products = [];

    QuerySnapshot<Map<String, dynamic>> productsQuery =
        await fireStore
            .collection(CollectionName.vendorProducts)
            .where("section_id", isEqualTo: Constant.sectionConstantModel!.id)
            .where('vendorID', isEqualTo: vendorId)
            .where('publish', isEqualTo: true)
            .orderBy('createdAt', descending: false)
            .get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        products.add(ProductModel.fromJson(document.data()));
      } catch (e) {
        print('product**-FireStoreUtils.getAllProducts Parse error $e');
      }
    });
    return products;
  }

  static Future<List<VendorModel>> getAllStoresFuture({String? categoryId}) async {
    List<VendorModel> vendors = [];

    try {
      final collectionReference =
          categoryId == null
              ? fireStore.collection(CollectionName.vendors).where("section_id", isEqualTo: Constant.sectionConstantModel!.id)
              : fireStore.collection(CollectionName.vendors).where("section_id", isEqualTo: Constant.sectionConstantModel!.id).where("categoryID", isEqualTo: categoryId);

      GeoFirePoint center = Geoflutterfire().point(latitude: Constant.selectedLocation.location!.latitude ?? 0.0, longitude: Constant.selectedLocation.location!.longitude ?? 0.0);

      String field = 'g';

      List<DocumentSnapshot> documentList =
          await Geoflutterfire()
              .collection(collectionRef: collectionReference)
              .within(center: center, radius: double.parse(Constant.sectionConstantModel!.nearByRadius.toString()), field: field, strictMode: true)
              .first; // Fetch the data once as a Future

      if (documentList.isNotEmpty) {
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;
          VendorModel vendorModel = VendorModel.fromJson(data);

          if (Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel?.adminCommision?.isEnabled == true) {
            if (vendorModel.subscriptionPlan != null && Constant.isExpire(vendorModel) == false) {
              if (vendorModel.subscriptionTotalOrders == "-1") {
                vendors.add(vendorModel);
              } else {
                if ((vendorModel.subscriptionExpiryDate != null && vendorModel.subscriptionExpiryDate!.toDate().isBefore(DateTime.now()) == false) || vendorModel.subscriptionPlan?.expiryDay == "-1") {
                  if (vendorModel.subscriptionTotalOrders != '0') {
                    vendors.add(vendorModel);
                  }
                }
              }
            }
          } else {
            vendors.add(vendorModel);
          }
        }
      }
    } catch (e) {
      print('Error fetching vendors: $e');
    }

    return vendors;
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    NotificationModel? notificationModel;
    await fireStore.collection(CollectionName.dynamicNotification).where('type', isEqualTo: type).get().then((value) {
      print("------>");
      if (value.docs.isNotEmpty) {
        print(value.docs.first.data());

        notificationModel = NotificationModel.fromJson(value.docs.first.data());
      } else {
        notificationModel = NotificationModel(id: "", message: "Notification setup is pending", subject: "setup notification", type: "");
      }
    });
    return notificationModel;
  }

  static Future<List<VendorCategoryModel>> getVendorCategory() async {
    List<VendorCategoryModel> list = [];
    await fireStore
        .collection(CollectionName.vendorCategories)
        .where('section_id', isEqualTo: Constant.sectionConstantModel!.id)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            print("====>${value.docs.length}");
            VendorCategoryModel walletTransactionModel = VendorCategoryModel.fromJson(element.data());
            list.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return list;
  }

  static Future<GiftCardsOrderModel> placeGiftCardOrder(GiftCardsOrderModel giftCardsOrderModel) async {
    print("=====>");
    print(giftCardsOrderModel.toJson());
    await fireStore.collection(CollectionName.giftPurchases).doc(giftCardsOrderModel.id).set(giftCardsOrderModel.toJson());
    return giftCardsOrderModel;
  }

  static Future removeFavouriteRestaurant(FavouriteModel favouriteModel) async {
    await fireStore.collection(CollectionName.favoriteVendor).where("store_id", isEqualTo: favouriteModel.restaurantId).get().then((value) {
      value.docs.forEach((element) async {
        await fireStore.collection(CollectionName.favoriteVendor).doc(element.id).delete();
      });
    });
  }

  static Future<void> setFavouriteRestaurant(FavouriteModel favouriteModel) async {
    favouriteModel.sectionId = Constant.sectionConstantModel!.id;
    log("setFavouriteRestaurant :: ${favouriteModel.toJson()}");
    await fireStore.collection(CollectionName.favoriteVendor).add(favouriteModel.toJson());
  }

  static Future<void> removeFavouriteItem(FavouriteItemModel favouriteModel) async {
    try {
      final favoriteCollection = fireStore.collection(CollectionName.favoriteItem);
      final querySnapshot = await favoriteCollection.where("product_id", isEqualTo: favouriteModel.productId).get();
      for (final doc in querySnapshot.docs) {
        await favoriteCollection.doc(doc.id).delete();
      }
    } catch (e) {
      print("Error removing favourite item: $e");
    }
  }

  static Future<void> setFavouriteItem(FavouriteItemModel favouriteModel) async {
    favouriteModel.sectionId = Constant.sectionConstantModel!.id;
    await fireStore.collection(CollectionName.favoriteItem).add(favouriteModel.toJson());
  }

  static Future<Url> uploadChatImageToFireStorage(File image, BuildContext context) async {
    ShowToastDialog.showLoader("Please wait".tr);
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  static Future<List<CouponModel>> getHomeCoupon() async {
    List<CouponModel> list = [];
    await fireStore
        .collection(CollectionName.coupons)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel walletTransactionModel = CouponModel.fromJson(element.data());
            list.add(walletTransactionModel);
          }
        })
        .catchError((error) {
          log(error.toString());
        });
    return list;
  }

  static Future<List<BannerModel>> getHomeTopBanner() async {
    List<BannerModel> bannerList = [];
    await fireStore
        .collection(CollectionName.bannerItems)
        .where("is_publish", isEqualTo: true)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where("position", isEqualTo: "top")
        .orderBy("set_order", descending: false)
        .get()
        .then((value) {
          for (var element in value.docs) {
            BannerModel bannerHome = BannerModel.fromJson(element.data());
            bannerList.add(bannerHome);
          }
        });
    return bannerList;
  }

  static Future<List<StoryModel>> getStory() async {
    List<StoryModel> storyList = [];
    await fireStore
        .collection(CollectionName.story)
        .where('sectionID', isEqualTo: Constant.sectionConstantModel!.id)
        .get()
        .then((value) {
          print("Number of Stories Fetched: ${value.docs.length}");
          for (var element in value.docs) {
            StoryModel walletTransactionModel = StoryModel.fromJson(element.data());
            storyList.add(walletTransactionModel);
          }
        });
    return storyList;
  }

  static Future<GiftCardsOrderModel?> checkRedeemCode(String giftCode) async {
    GiftCardsOrderModel? giftCardsOrderModel;
    await fireStore.collection(CollectionName.giftPurchases).where("giftCode", isEqualTo: giftCode).get().then((value) {
      if (value.docs.isNotEmpty) {
        giftCardsOrderModel = GiftCardsOrderModel.fromJson(value.docs.first.data());
      }
    });
    return giftCardsOrderModel;
  }

  static Future<void> sendTopUpMail({required String amount, required String paymentMethod, required String tractionId}) async {
    EmailTemplateModel? emailTemplateModel = await FireStoreUtils.getEmailTemplates(Constant.walletTopup);

    String newString = emailTemplateModel!.message.toString();
    newString = newString.replaceAll("{username}", Constant.userModel!.firstName.toString() + Constant.userModel!.lastName.toString());
    newString = newString.replaceAll("{date}", DateFormat('yyyy-MM-dd').format(Timestamp.now().toDate()));
    newString = newString.replaceAll("{amount}", Constant.amountShow(amount: amount));
    newString = newString.replaceAll("{paymentmethod}", paymentMethod.toString());
    newString = newString.replaceAll("{transactionid}", tractionId.toString());
    newString = newString.replaceAll("{newwalletbalance}.", Constant.amountShow(amount: Constant.userModel!.walletAmount.toString()));
    await Constant.sendMail(subject: emailTemplateModel.subject, isAdmin: emailTemplateModel.isSendToAdmin, body: newString, recipients: [Constant.userModel!.email]);
  }

  static Future<ChatVideoContainer?> uploadChatVideoToFireStorage(BuildContext context, File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef = FirebaseStorage.instance.ref('videos/$uniqueID.mp4');
      final UploadTask uploadTask = videoRef.putFile(video, SettableMetadata(contentType: 'video/mp4'));
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      File thumbnail = await VideoCompress.getFileThumbnail(
        video.path,
        quality: 75, // 0 - 100
        position: -1, // Get the first frame
      );

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef = FirebaseStorage.instance.ref('thumbnails/$thumbnailID.jpg');
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(thumbnail.readAsBytesSync(), SettableMetadata(contentType: 'image/jpeg'));
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(videoUrl: Url(url: videoUrl.toString(), mime: metaData.contentType ?? 'video', videoThumbnail: thumbnailUrl), thumbnailUrl: thumbnailUrl);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  static Future<OrderModel?> getOrderByOrderId(String orderId) async {
    OrderModel? orderModel;
    try {
      await fireStore.collection(CollectionName.vendorOrders).doc(orderId).get().then((value) {
        if (value.data() != null) {
          orderModel = OrderModel.fromJson(value.data()!);
        }
      });
    } catch (e, s) {
      print('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return orderModel;
  }

  static Future<List<CouponModel>> getCabCoupon() async {
    List<CouponModel> ordersList = [];
    await fireStore
        .collection(CollectionName.promos)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel bannerHome = CouponModel.fromJson(element.data());
            ordersList.add(bannerHome);
          }
        });
    return ordersList;
  }

  static Future<List<CouponModel>> getParcelCoupon() async {
    List<CouponModel> ordersList = [];
    await fireStore
        .collection(CollectionName.parcelCoupons)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel bannerHome = CouponModel.fromJson(element.data());
            ordersList.add(bannerHome);
          }
        });
    return ordersList;
  }

  static Future<List<CouponModel>> getRentalCoupon() async {
    List<CouponModel> ordersList = [];
    await fireStore
        .collection(CollectionName.rentalCoupons)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .where("isEnabled", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel bannerHome = CouponModel.fromJson(element.data());
            ordersList.add(bannerHome);
          }
        });
    return ordersList;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      await fireStore.collection(CollectionName.users).doc(FireStoreUtils.getCurrentUid()).delete();

      // delete user  from firebase auth
      await auth.FirebaseAuth.instance.currentUser?.delete().then((value) {
        isDelete = true;
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<List<ParcelCategory>> getParcelServiceCategory() async {
    List<ParcelCategory> parcelCategoryList = [];
    await fireStore
        .collection(CollectionName.parcelCategory)
        .where('publish', isEqualTo: true)
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .orderBy('set_order', descending: false)
        .get()
        .then((value) {
          for (var element in value.docs) {
            try {
              ParcelCategory category = ParcelCategory.fromJson(element.data());
              parcelCategoryList.add(category);
            } catch (e, stackTrace) {
              print('getParcelServiceCategory parse error: ${element.id} $e');
              print(stackTrace);
            }
          }
        });
    return parcelCategoryList;
  }

  static Future<List<ParcelWeightModel>> getParcelWeight() async {
    List<ParcelWeightModel> parcelWeightList = [];
    await fireStore.collection(CollectionName.parcelWeight).get().then((value) {
      for (var element in value.docs) {
        try {
          ParcelWeightModel category = ParcelWeightModel.fromJson(element.data());
          parcelWeightList.add(category);
        } catch (e, stackTrace) {
          print('getParcelWeight parse error: ${element.id} $e');
          print(stackTrace);
        }
      }
    });
    return parcelWeightList;
  }

  static Future<bool> setParcelOrder(ParcelOrderModel orderModel, double totalAmount) async {
    // try {
    //   final firestore = FirebaseFirestore.instance;
    //   final isNew = orderModel.id.isEmpty;
    //
    //   final docRef = firestore.collection(CollectionName.parcelOrders).doc(isNew ? null : orderModel.id);
    //   if (isNew) {
    //     orderModel.id = docRef.id;
    //   }
    //
    //   // Handle wallet payment if needed
    //   if (orderModel.paymentCollectByReceiver == false && orderModel.paymentMethod == "wallet") {
    //     WalletTransactionModel transactionModel = WalletTransactionModel(
    //       id: Constant.getUuid(),
    //       serviceType: 'parcel-service',
    //       amount: totalAmount,
    //       date: Timestamp.now(),
    //       paymentMethod: PaymentGateway.wallet.name,
    //       transactionUser: "customer",
    //       userId: FireStoreUtils.getCurrentUid(),
    //       isTopup: false,
    //       orderId: orderModel.id,
    //       note: "Order Amount debited".tr,
    //       paymentStatus: "success".tr,
    //     );
    //
    //     await FireStoreUtils.setWalletTransaction(transactionModel).then((value) async {
    //       if (value == true) {
    //         await FireStoreUtils.updateUserWallet(amount: "-$totalAmount", userId: FireStoreUtils.getCurrentUid());
    //       }
    //     });
    //   }
    //
    //   // Set the parcel order in Firestore
    //   await firestore.collection(CollectionName.parcelOrders).doc(orderModel.id).set(orderModel.toJson());
    //
    //   return true;
    // } catch (e) {
    //   debugPrint("Failed to place parcel order: $e");
    //   return false;
    // }
    return true;
  }

  static Future<void> sendParcelBookEmail({required ParcelOrderModel orderModel}) async {
    try {
      EmailTemplateModel? emailTemplateModel = await FireStoreUtils.getEmailTemplates(Constant.newParcelBook);

      String newString = emailTemplateModel!.message.toString();
      newString = newString.replaceAll("{passengername}", "${Constant.userModel!.firstName} ${Constant.userModel!.lastName}");
      newString = newString.replaceAll("{parcelid}", orderModel.id.toString());
      newString = newString.replaceAll("{date}", DateFormat('dd-MM-yyyy').format(orderModel.createdAt!.toDate()));
      newString = newString.replaceAll("{sendername}", orderModel.sender!.name.toString());
      newString = newString.replaceAll("{senderphone}", orderModel.sender!.phone.toString());
      newString = newString.replaceAll("{note}", orderModel.note.toString());
      newString = newString.replaceAll("{deliverydate}", DateFormat('dd-MM-yyyy').format(orderModel.receiverPickupDateTime!.toDate()));

      String subjectNewString = emailTemplateModel.subject.toString();
      subjectNewString = subjectNewString.replaceAll("{orderid}", orderModel.id.toString());
      await Constant.sendMail(subject: subjectNewString, isAdmin: emailTemplateModel.isSendToAdmin, body: newString, recipients: [Constant.userModel!.email]);
    } catch (e) {
      log("SIGNUP :: 22 :::::: $e");
    }
  }

  static Stream<List<ParcelOrderModel>> listenParcelOrders() {
    return fireStore
        .collection(CollectionName.parcelOrders)
        .where('authorID', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            log("===>");
            print(doc.data());
            return ParcelOrderModel.fromJson(doc.data());
          }).toList();
        });
  }

  static Future<List<VehicleType>> getVehicleType() async {
    List<VehicleType> vehicleTypeList = [];
    await fireStore.collection(CollectionName.vehicleType).where('sectionId', isEqualTo: Constant.sectionConstantModel!.id).where("isActive", isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        try {
          VehicleType category = VehicleType.fromJson(element.data());
          vehicleTypeList.add(category);
        } catch (e, stackTrace) {
          print('getVehicleType error: ${element.id} $e');
          print(stackTrace);
        }
      }
    });
    return vehicleTypeList;
  }

  static Future<List<PopularDestination>> getPopularDestination() async {
    List<PopularDestination> popularDestination = [];
    await fireStore.collection(CollectionName.popularDestinations).where("sectionId", isEqualTo: Constant.sectionConstantModel!.id).where('is_publish', isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        try {
          PopularDestination category = PopularDestination.fromJson(element.data());
          popularDestination.add(category);
        } catch (e, stackTrace) {
          print('Get PopularDestination error: ${element.id} $e');
          print(stackTrace);
        }
      }
    });
    return popularDestination;
  }

  static Future cabOrderPlace(CabOrderModel orderModel) async {
    await fireStore.collection(CollectionName.rides).doc(orderModel.id).set(orderModel.toJson());
  }

  static Future parcelOrderPlace(ParcelOrderModel orderModel) async {
    await fireStore.collection(CollectionName.parcelOrders).doc(orderModel.id).set(orderModel.toJson());
  }

  static Future rentalOrderPlace(RentalOrderModel orderModel) async {
    await fireStore.collection(CollectionName.rentalOrders).doc(orderModel.id).set(orderModel.toJson());
  }

  static Future<CabOrderModel?> getCabOrderById(String orderId) async {
    CabOrderModel? orderModel;
    try {
      final doc = await fireStore.collection(CollectionName.rides).doc(orderId).get();
      if (doc.data() != null) {
        final model = CabOrderModel.fromJson(doc.data()!);
        if (model.rideType == "ride") {
          orderModel = model;
        }
      }
    } catch (e, s) {
      print('getCabOrderById error: $e\n$s');
      return null;
    }
    return orderModel;
  }

  static Future<CabOrderModel?> getIntercityOrder(String orderId) async {
    CabOrderModel? orderModel;
    try {
      final doc = await fireStore.collection(CollectionName.rides).doc(orderId).get();
      if (doc.data() != null) {
        final model = CabOrderModel.fromJson(doc.data()!);
        if (model.rideType == "intercity") {
          orderModel = model;
        }
      }
    } catch (e, s) {
      print('getCabOrderById error: $e\n$s');
      return null;
    }
    return orderModel;
  }

  static Future<UserModel?> getDriver(String userId) async {
    UserModel? userModel;

    try {
      final doc = await fireStore.collection(CollectionName.users).doc(userId).get();

      if (doc.data() != null) {
        userModel = UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      log("getDriver error: $e");
    }

    return userModel;
  }

  // static Future<List<CabOrderModel>> getCabDriverOrders() async {
  //   List<CabOrderModel> ordersList = [];
  //   await fireStore.collection(CollectionName.rides).where('authorID', isEqualTo: FireStoreUtils.getCurrentUid()).orderBy('createdAt', descending: true).get().then((value) {
  //     for (var element in value.docs) {
  //       CabOrderModel orderModel = CabOrderModel.fromJson(element.data());
  //       ordersList.add(orderModel);
  //     }
  //   });
  //   return ordersList;
  // }

  static Stream<List<CabOrderModel>> getCabDriverOrders() {
    return fireStore
        .collection(CollectionName.rides)
        .where('authorID', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) {
          List<CabOrderModel> ordersList = [];
          for (var element in query.docs) {
            ordersList.add(CabOrderModel.fromJson(element.data()));
          }
          return ordersList;
        });
  }

  static Future<List<CategoryModel>> getOnDemandCategory() async {
    List<CategoryModel> categoryList = [];
    await fireStore
        .collection(CollectionName.providerCategories)
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
        .where("level", isEqualTo: 0)
        .where("publish", isEqualTo: true)
        .get()
        .then((value) {
          for (var element in value.docs) {
            CategoryModel orderModel = CategoryModel.fromJson(element.data());
            categoryList.add(orderModel);
          }
        });
    return categoryList;
  }

  static Future<CategoryModel?> getCategoryById(String categoryId) async {
    CategoryModel? categoryModel;
    await fireStore.collection(CollectionName.providerCategories).doc(categoryId).get().then((value) {
      if (value.exists) {
        categoryModel = CategoryModel.fromJson(value.data()!);
      }
    });
    return categoryModel;
  }

  static Future<List<ProviderServiceModel>> getProviderFuture({String categoryId = ''}) async {
    List<ProviderServiceModel> providerList = [];

    try {
      Query<Map<String, dynamic>> collectionReference;

      if (categoryId.isNotEmpty) {
        collectionReference = fireStore
            .collection(CollectionName.providersServices)
            .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
            .where('categoryId', isEqualTo: categoryId)
            .where("publish", isEqualTo: true);
      } else {
        collectionReference = fireStore.collection(CollectionName.providersServices).where("sectionId", isEqualTo: Constant.sectionConstantModel!.id).where("publish", isEqualTo: true);
      }

      GeoFirePoint center = Geoflutterfire().point(latitude: Constant.selectedLocation.location!.latitude ?? 0.0, longitude: Constant.selectedLocation.location!.longitude ?? 0.0);

      String field = 'g';

      await Geoflutterfire()
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: double.parse(Constant.sectionConstantModel!.nearByRadius.toString()), field: field, strictMode: true)
          .first
          .then((documentList) {
            for (var document in documentList) {
              ProviderServiceModel providerServiceModel = ProviderServiceModel.fromJson(document.data() as Map<String, dynamic>);

              log(
                ":: isExpireDate(expiryDay :: ${Constant.isExpireDate(expiryDay: (providerServiceModel.subscriptionPlan?.expiryDay == '-1'), subscriptionExpiryDate: providerServiceModel.subscriptionExpiryDate)}",
              );

              if (Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel?.adminCommision?.isEnabled == true) {
                if (providerServiceModel.subscriptionPlan != null &&
                    Constant.isExpireDate(expiryDay: (providerServiceModel.subscriptionPlan?.expiryDay == '-1'), subscriptionExpiryDate: providerServiceModel.subscriptionExpiryDate) == false) {
                  if (providerServiceModel.subscriptionTotalOrders == "-1" || providerServiceModel.subscriptionTotalOrders != '0') {
                    providerList.add(providerServiceModel);
                  }
                }
              } else {
                providerList.add(providerServiceModel);
              }
            }
          })
          .catchError((error) {
            log('Error fetching providers: $error');
          });
    } catch (e) {
      log('Error in getProviderFuture: $e');
    }

    return providerList;
  }

  static Future<List<ProviderServiceModel>> getAllProviderServiceByAuthorId(String authId) async {
    List<ProviderServiceModel> providerService = [];
    await fireStore.collection(CollectionName.providersServices).where('author', isEqualTo: authId).where('publish', isEqualTo: true).orderBy('createdAt', descending: false).get().then((value) {
      for (var element in value.docs) {
        ProviderServiceModel orderModel = ProviderServiceModel.fromJson(element.data());
        providerService.add(orderModel);
      }
    });
    return providerService;
  }

  static Future<CategoryModel?> getSubCategoryById(String categoryId) async {
    CategoryModel? categoryModel;
    await fireStore.collection(CollectionName.providerCategories).doc(categoryId).get().then((value) {
      if (value.exists) {
        categoryModel = CategoryModel.fromJson(value.data()!);
      }
    });
    return categoryModel;
  }

  static Future<List<RatingModel>> getReviewByProviderServiceId(String serviceId) async {
    List<RatingModel> providerReview = [];
    await fireStore.collection(CollectionName.itemsReview).where('productId', isEqualTo: serviceId).get().then((value) {
      for (var element in value.docs) {
        RatingModel orderModel = RatingModel.fromJson(element.data());
        providerReview.add(orderModel);
      }
    });
    return providerReview;
  }

  static Future<List<ProviderServiceModel>> getProviderServiceByProviderId({required String providerId}) async {
    List<ProviderServiceModel> providerList = [];

    try {
      final collectionReference = fireStore
          .collection(CollectionName.providersServices)
          .where("author", isEqualTo: providerId)
          .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id)
          .where("publish", isEqualTo: true);

      // Geolocation center point
      GeoFirePoint center = Geoflutterfire().point(latitude: Constant.selectedLocation.location!.latitude ?? 0.0, longitude: Constant.selectedLocation.location!.longitude ?? 0.0);

      String field = 'g';

      // Query within radius
      await Geoflutterfire()
          .collection(collectionRef: collectionReference)
          .within(center: center, radius: double.parse(Constant.sectionConstantModel!.nearByRadius.toString()), field: field, strictMode: true)
          .first
          .then((documentList) {
            for (var document in documentList) {
              ProviderServiceModel providerServiceModel = ProviderServiceModel.fromJson(document.data() as Map<String, dynamic>);

              log(
                ":: isExpireDate(expiryDay :: ${Constant.isExpireDate(expiryDay: (providerServiceModel.subscriptionPlan?.expiryDay == '-1'), subscriptionExpiryDate: providerServiceModel.subscriptionExpiryDate)}",
              );

              //Subscription & Commission check
              if (Constant.isSubscriptionModelApplied == true || Constant.sectionConstantModel?.adminCommision?.isEnabled == true) {
                if (providerServiceModel.subscriptionPlan != null &&
                    Constant.isExpireDate(expiryDay: (providerServiceModel.subscriptionPlan?.expiryDay == '-1'), subscriptionExpiryDate: providerServiceModel.subscriptionExpiryDate) == false) {
                  if (providerServiceModel.subscriptionTotalOrders == "-1" || providerServiceModel.subscriptionTotalOrders != '0') {
                    providerList.add(providerServiceModel);
                  }
                }
              } else {
                providerList.add(providerServiceModel);
              }
            }
          })
          .catchError((error) {
            log('Error fetching provider services: $error');
          });
    } catch (e) {
      log('Error in getProviderServiceByProviderId: $e');
    }

    return providerList;
  }

  static Future<List<CouponModel>> getProviderCoupon(String providerId) async {
    List<CouponModel> offers = [];
    await fireStore
        .collection(CollectionName.providersCoupons)
        .where('providerId', isEqualTo: providerId)
        .where("isEnabled", isEqualTo: true)
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel favouriteOndemandServiceModel = CouponModel.fromJson(element.data());
            offers.add(favouriteOndemandServiceModel);
          }
        });
    return offers;
  }

  static Future<List<CouponModel>> getProviderCouponAfterExpire(String providerId) async {
    List<CouponModel> coupon = [];
    await fireStore
        .collection(CollectionName.providersCoupons)
        .where('providerId', isEqualTo: providerId)
        .where('isEnabled', isEqualTo: true)
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .where('isPublic', isEqualTo: true)
        .where('expiresAt', isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
          for (var element in value.docs) {
            CouponModel favouriteOndemandServiceModel = CouponModel.fromJson(element.data());
            coupon.add(favouriteOndemandServiceModel);
          }
        });
    return coupon;
  }

  static Future<OnProviderOrderModel> onDemandOrderPlace(OnProviderOrderModel orderModel, double totalAmount) async {
    DocumentReference documentReference;
    if (orderModel.id.isEmpty) {
      documentReference = fireStore.collection(CollectionName.providerOrders).doc();
      orderModel.id = documentReference.id;
    } else {
      documentReference = fireStore.collection(CollectionName.providerOrders).doc(orderModel.id);
    }
    await documentReference.set(orderModel.toJson());

    return orderModel;
  }

  static Future<void> sendOrderOnDemandServiceEmail({required OnProviderOrderModel orderModel}) async {
    try {
      String firstHTML = """
       <table style="width: 100%; border-collapse: collapse; border: 1px solid rgb(0, 0, 0);">
    <thead>
        <tr>
            <th style="text-align: left; border: 1px solid rgb(0, 0, 0);">Product Name<br></th>
            <th style="text-align: left; border: 1px solid rgb(0, 0, 0);">Quantity<br></th>
            <th style="text-align: left; border: 1px solid rgb(0, 0, 0);">Price<br></th>
            <th style="text-align: left; border: 1px solid rgb(0, 0, 0);">Total<br></th>
        </tr>
    </thead>
    <tbody>
    """;

      EmailTemplateModel? emailTemplateModel = await FireStoreUtils.getEmailTemplates(Constant.newOnDemandBook);

      if (emailTemplateModel != null) {
        String newString = emailTemplateModel.message.toString();
        newString = newString.replaceAll("{username}", "${Constant.userModel?.firstName ?? ''} ${Constant.userModel?.lastName ?? ''}");
        newString = newString.replaceAll("{orderid}", orderModel.id);
        newString = newString.replaceAll("{date}", DateFormat('dd-MM-yyyy').format(orderModel.createdAt.toDate()));
        newString = newString.replaceAll("{address}", orderModel.address!.getFullAddress());
        newString = newString.replaceAll("{paymentmethod}", orderModel.payment_method);

        double total = 0.0;
        double discount = 0.0;
        double taxAmount = 0.0;
        List<String> htmlList = [];

        if (orderModel.provider.disPrice == "" || orderModel.provider.disPrice == "0") {
          total = double.parse(orderModel.provider.price.toString()) * orderModel.quantity;
        } else {
          total = double.parse(orderModel.provider.disPrice.toString()) * orderModel.quantity;
        }

        String product = """
        <tr>
            <td style="width: 20%; border-top: 1px solid rgb(0, 0, 0);">${orderModel.provider.title}</td>
            <td style="width: 20%; border: 1px solid rgb(0, 0, 0);" rowspan="2">${orderModel.quantity}</td>
            <td style="width: 20%; border: 1px solid rgb(0, 0, 0);" rowspan="2">${Constant.amountShow(amount: (orderModel.provider.disPrice == "" || orderModel.provider.disPrice == "0") ? orderModel.provider.price.toString() : orderModel.provider.disPrice.toString())}</td>
            <td style="width: 20%; border: 1px solid rgb(0, 0, 0);" rowspan="2">${Constant.amountShow(amount: (total).toString())}</td>
        </tr>
    """;
        htmlList.add(product);

        if (orderModel.couponCode != null && orderModel.couponCode!.isNotEmpty) {
          discount = double.parse(orderModel.discount.toString());
        }
        List<String> taxHtmlList = [];
        if (orderModel.taxModel != null) {
          for (var element in orderModel.taxModel!) {
            taxAmount = taxAmount + Constant.getTaxValue(amount: (total - discount).toString(), taxModel: element);
            String taxHtml =
                """<span style="font-size: 1rem;">${element.title}: ${Constant.amountShow(amount: Constant.getTaxValue(amount: (total - discount).toString(), taxModel: element).toString())}${Constant.taxList.indexOf(element) == Constant.taxList.length - 1 ? "</span>" : "<br></span>"}""";
            taxHtmlList.add(taxHtml);
          }
        }

        var totalamount = total + taxAmount - discount;

        newString = newString.replaceAll("{subtotal}", Constant.amountShow(amount: total.toString()));
        newString = newString.replaceAll("{coupon}", '(${orderModel.couponCode.toString()})');
        newString = newString.replaceAll("{discountamount}", orderModel.couponCode == null ? "0.0" : Constant.amountShow(amount: orderModel.discount.toString()));
        newString = newString.replaceAll("{totalAmount}", Constant.amountShow(amount: totalamount.toString()));

        String tableHTML = htmlList.join();
        String lastHTML = "</tbody></table>";
        newString = newString.replaceAll("{productdetails}", firstHTML + tableHTML + lastHTML);
        newString = newString.replaceAll("{taxdetails}", taxHtmlList.join());
        newString = newString.replaceAll("{newwalletbalance}.", Constant.amountShow(amount: Constant.userModel?.walletAmount.toString()));

        String subjectNewString = emailTemplateModel.subject.toString();
        subjectNewString = subjectNewString.replaceAll("{orderid}", orderModel.id);
        await Constant.sendMail(subject: subjectNewString, isAdmin: emailTemplateModel.isSendToAdmin, body: newString, recipients: [Constant.userModel?.email]);
      }
    } catch (e) {
      log("SIGNUP :: 22 :::::: $e");
    }
  }

  static Future<void> updateOnDemandOrder(OnProviderOrderModel orderModel) async {
    if (orderModel.id.isEmpty) {
      throw Exception("Order ID cannot be empty");
    }

    try {
      final docRef = fireStore.collection(CollectionName.providerOrders).doc(orderModel.id);
      await docRef.set(orderModel.toJson(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating OnDemand order: $e");
      rethrow;
    }
  }

  // static Future<void> updateOnDemandOrder(OnProviderOrderModel orderModel) async {
  //   if (orderModel.id.isEmpty) {
  //     throw Exception("Order ID cannot be empty");
  //   }
  //
  //   try {
  //     final docRef = fireStore.collection(CollectionName.providerOrders).doc(orderModel.id);
  //
  //     // Convert model to map
  //     final Map<String, dynamic> data = orderModel.toJson();
  //
  //     // Remove null values so we only update non-null fields
  //     final Map<String, dynamic> updateData = {};
  //     data.forEach((key, value) {
  //       if (value != null) {
  //         updateData[key] = value;
  //       }
  //     });
  //
  //     if (updateData.isNotEmpty) {
  //       await docRef.set(updateData, SetOptions(merge: true));
  //       print("Order ${orderModel.id} updated dynamically: $updateData");
  //     } else {
  //       print("No fields to update for order ${orderModel.id}");
  //     }
  //   } catch (e) {
  //     print("Error updating OnDemand order: $e");
  //     rethrow;
  //   }
  // }

  // static Future<List<OnProviderOrderModel>> getProviderOrders() async {
  //   List<OnProviderOrderModel> ordersList = [];
  //   await fireStore
  //       .collection(CollectionName.providerOrders)
  //       .where("authorID", isEqualTo: FireStoreUtils.getCurrentUid())
  //       .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id.toString())
  //       .orderBy("createdAt", descending: true)
  //       .get()
  //       .then((value) {
  //         for (var element in value.docs) {
  //           OnProviderOrderModel orderModel = OnProviderOrderModel.fromJson(element.data());
  //           ordersList.add(orderModel);
  //         }
  //       });
  //   return ordersList;
  // }

  static Stream<List<OnProviderOrderModel>> getProviderOrdersStream() {
    return fireStore
        .collection(CollectionName.providerOrders)
        .where("authorID", isEqualTo: getCurrentUid())
        .where("sectionId", isEqualTo: Constant.sectionConstantModel!.id.toString())
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => OnProviderOrderModel.fromJson(doc.data())).toList());
  }

  static Future<WorkerModel?> getWorker(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await fireStore.collection(CollectionName.providersWorkers).doc(id).get();

      if (doc.exists && doc.data() != null) {
        return WorkerModel.fromJson(doc.data()!);
      }
    } catch (e) {
      print("FireStoreUtils.getWorker error: $e");
    }
    return null;
  }

  static Future<OnProviderOrderModel?> getProviderOrderById(String orderId) async {
    OnProviderOrderModel? orderModel;
    await fireStore.collection(CollectionName.providerOrders).doc(orderId).get().then((value) {
      if (value.exists) {
        orderModel = OnProviderOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<RatingModel?> getReviewsByProviderID(String orderId, String providerId) async {
    RatingModel? ratingModel;

    await fireStore
        .collection(CollectionName.itemsReview)
        .where('orderid', isEqualTo: orderId)
        .where('VendorId', isEqualTo: providerId)
        .limit(1)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            ratingModel = RatingModel.fromJson(snapshot.docs.first.data());
          }
        })
        .catchError((error) {
          print('Error fetching review for provider: $error');
        });

    return ratingModel;
  }

  static Future<RatingModel?> getReviewsByWorkerID(String orderId, String workerId) async {
    RatingModel? ratingModel;

    await fireStore
        .collection(CollectionName.itemsReview)
        .where('orderid', isEqualTo: orderId)
        .where('driverId', isEqualTo: workerId)
        .limit(1)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            ratingModel = RatingModel.fromJson(snapshot.docs.first.data());
          }
        })
        .catchError((error) {
          print('Error fetching review by worker ID: $error');
        });

    return ratingModel;
  }

  static Future<ProviderServiceModel?> getCurrentProvider(String uid) async {
    try {
      final doc = await fireStore.collection(CollectionName.providersServices).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return ProviderServiceModel.fromJson(doc.data()!);
      }
    } catch (e, stackTrace) {
      print('Error fetching current provider: $e');
      print(stackTrace);
    }
    return null;
  }

  static Future<RatingModel?> updateReviewById(RatingModel ratingProduct) async {
    try {
      await fireStore.collection(CollectionName.itemsReview).doc(ratingProduct.id).set(ratingProduct.toJson());
      return ratingProduct;
    } catch (e, stackTrace) {
      print('Error updating review: $e');
      print(stackTrace);
      return null;
    }
  }

  static Future<ProviderServiceModel?> updateProvider(ProviderServiceModel provider) async {
    try {
      await fireStore.collection(CollectionName.providersServices).doc(provider.id).set(provider.toJson());
      return provider;
    } catch (e, stackTrace) {
      print('Error updating provider: $e');
      print(stackTrace);
      return null;
    }
  }

  static Future<WorkerModel?> updateWorker(WorkerModel worker) async {
    try {
      await fireStore.collection(CollectionName.providersWorkers).doc(worker.id).set(worker.toJson());
      return worker;
    } catch (e, stackTrace) {
      print('Error updating worker: $e');
      print(stackTrace);
      return null;
    }
  }

  static Future<ParcelOrderModel?> getParcelOrder(String orderId) async {
    try {
      final doc = await fireStore.collection(CollectionName.parcelOrders).doc(orderId).get();
      if (doc.exists && doc.data() != null) {
        return ParcelOrderModel.fromJson(doc.data()!);
      }
    } catch (e, stackTrace) {
      print('Error fetching current provider: $e');
      print(stackTrace);
    }
    return null;
  }

  static Stream<UserModel?> driverStream(String userId) {
    return fireStore.collection(CollectionName.users).doc(userId).snapshots().map((doc) {
      if (doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  static Future<void> updateCabOrder(CabOrderModel orderModel) async {
    if (orderModel.id!.isEmpty) {
      throw Exception("Order ID cannot be empty");
    }

    try {
      final docRef = fireStore.collection(CollectionName.rides).doc(orderModel.id);
      await docRef.set(orderModel.toJson(), SetOptions(merge: true));
    } catch (e) {
      print("Error updating OnDemand order: $e");
      rethrow;
    }
  }

  static Future<List<RentalVehicleType>> getRentalVehicleType() async {
    List<RentalVehicleType> vehicleTypeList = [];
    await fireStore.collection(CollectionName.rentalVehicleType).where('sectionId', isEqualTo: Constant.sectionConstantModel!.id).where("isActive", isEqualTo: true).get().then((value) {
      for (var element in value.docs) {
        try {
          RentalVehicleType category = RentalVehicleType.fromJson(element.data());
          vehicleTypeList.add(category);
        } catch (e, stackTrace) {
          print('getVehicleType error: ${element.id} $e');
          print(stackTrace);
        }
      }
    });
    return vehicleTypeList;
  }

  static Future<List<RentalPackageModel>> getRentalPackage(String vehicleId) async {
    List<RentalPackageModel> rentalPackageList = [];
    await fireStore.collection(CollectionName.rentalPackages).where("vehicleTypeId", isEqualTo: vehicleId).orderBy("ordering", descending: false).get().then((value) {
      for (var element in value.docs) {
        try {
          log('Rental Package Data: ${element.data()}');
          RentalPackageModel category = RentalPackageModel.fromJson(element.data());
          rentalPackageList.add(category);
        } catch (e, stackTrace) {
          print('getVehicleType error: ${element.id} $e');
          print(stackTrace);
        }
      }
    });
    return rentalPackageList;
  }

  static Stream<List<RentalOrderModel>> getRentalOrders() {
    return fireStore
        .collection(CollectionName.rentalOrders)
        .where('authorID', isEqualTo: FireStoreUtils.getCurrentUid())
        .where('sectionId', isEqualTo: Constant.sectionConstantModel!.id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) {
          List<RentalOrderModel> ordersList = [];
          for (var element in query.docs) {
            ordersList.add(RentalOrderModel.fromJson(element.data()));
          }
          return ordersList;
        });
  }

  static Future<RentalOrderModel?> getRentalOrderById(String orderId) async {
    RentalOrderModel? orderModel;
    await fireStore.collection(CollectionName.rentalOrders).doc(orderId).get().then((value) {
      if (value.exists) {
        orderModel = RentalOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<RatingModel?> getReviewsbyID(String orderId) async {
    RatingModel? ratingModel;

    await fireStore
        .collection(CollectionName.itemsReview)
        .where('orderid', isEqualTo: orderId)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            ratingModel = RatingModel.fromJson(snapshot.docs.first.data());
          }
        })
        .catchError((error) {
          print('Error fetching review for provider: $error');
        });

    return ratingModel;
  }

  static Future<dynamic> getOrderByIdFromAllCollections(String orderId) async {
    final List<String> collections = [CollectionName.parcelOrders, CollectionName.rentalOrders, CollectionName.providerOrders, CollectionName.rides, CollectionName.vendorOrders];

    for (String collection in collections) {
      try {
        final snapshot = await fireStore.collection(collection).where('id', isEqualTo: orderId).limit(1).get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          data['collection_name'] = collection;
          return data;
        }
      } catch (e) {
        log("Error fetching from $collection => $e");
      }
    }

    log("No order found with ID $orderId");
    return null;
  }

  static Future<void> setSos(String orderId, UserLocation userLocation) {
    DocumentReference documentReference = fireStore.collection(CollectionName.sos).doc();

    Map<String, dynamic> sosMap = {'id': documentReference.id, 'orderId': orderId, 'status': "Initiated", 'latLong': userLocation.toJson()};

    return documentReference
        .set(sosMap)
        .then((_) {
          print("SOS request created successfully for order: $orderId");
        })
        .catchError((error) {
          print("Failed to create SOS request: $error");
        });
  }

  static Future<bool> getSOS(String orderId) {
    return fireStore
        .collection(CollectionName.sos)
        .where('orderId', isEqualTo: orderId)
        .get()
        .then((querySnapshot) {
          bool isAdded = false;
          for (var element in querySnapshot.docs) {
            if (element['orderId'] == orderId) {
              isAdded = true;
              break;
            }
          }
          return isAdded;
        })
        .catchError((error) {
          print("Error checking SOS: $error");
          return false;
        });
  }

  static Future<void> setRideComplain({
    required String orderId,
    required String title,
    required String description,
    required String driverID,
    required String driverName,
    required String customerID,
    required String customerName,
  }) async {
    try {
      DocumentReference docRef = fireStore.collection(CollectionName.complaints).doc();

      Map<String, dynamic> complaintData = {
        'id': docRef.id,
        'createdAt': Timestamp.now(),
        'description': description,
        'driverId': driverID,
        'driverName': driverName,
        'orderId': orderId,
        'customerName': customerName,
        'customerId': customerID,
        'status': "Initiated",
        'title': title,
      };

      await docRef.set(complaintData);
    } catch (e) {
      print("Error adding ride complain: $e");
      rethrow;
    }
  }

  static Future<bool> isRideComplainAdded(String orderId) async {
    try {
      QuerySnapshot querySnapshot = await fireStore.collection(CollectionName.complaints).where('orderId', isEqualTo: orderId).limit(1).get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking ride complain: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getRideComplainData(String orderId) async {
    try {
      QuerySnapshot querySnapshot = await fireStore.collection(CollectionName.complaints).where('orderId', isEqualTo: orderId).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching ride complain data: $e");
      return null;
    }
  }

  static void removeFavouriteOndemandService(FavouriteOndemandServiceModel favouriteModel) {
    FirebaseFirestore.instance.collection(CollectionName.favoriteService).where("user_id", isEqualTo: favouriteModel.user_id).where("service_id", isEqualTo: favouriteModel.service_id).get().then((
      value,
    ) {
      for (var element in value.docs) {
        FirebaseFirestore.instance.collection(CollectionName.favoriteService).doc(element.id).delete().then((value) {
          print("Remove Success!");
        });
      }
    });
  }

  static Future<void> setFavouriteOndemandSection(FavouriteOndemandServiceModel favouriteModel) async {
    await fireStore.collection(CollectionName.favoriteService).add(favouriteModel.toJson()).then((value) {
      print("===FAVOURITE ADDED=== ${favouriteModel.toJson()}");
    });
  }

  static Future<List<FavouriteOndemandServiceModel>> getFavouritesServiceList(String userId) async {
    List<FavouriteOndemandServiceModel> lstFavourites = [];

    QuerySnapshot<Map<String, dynamic>> favourites =
        await fireStore.collection(CollectionName.favoriteService).where('user_id', isEqualTo: userId).where("section_id", isEqualTo: Constant.sectionConstantModel!.id).get();

    await Future.forEach(favourites.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        lstFavourites.add(FavouriteOndemandServiceModel.fromJson(document.data()));
      } catch (e) {
        print('FavouriteModel.getCurrencys Parse error $e');
      }
    });

    return lstFavourites;
  }

  static Future<List<ProviderServiceModel>> getCurrentProviderService(FavouriteOndemandServiceModel model) async {
    List<ProviderServiceModel> providerService = [];

    QuerySnapshot<Map<String, dynamic>> reviewQuery =
        await fireStore.collection(CollectionName.providersServices).where('id', isEqualTo: model.service_id).where('sectionId', isEqualTo: model.section_id).get();
    await Future.forEach(reviewQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        providerService.add(ProviderServiceModel.fromJson(document.data()));
      } catch (e) {
        print('FireStoreUtils.getReviewByProviderServiceId Parse error ${document.id} $e');
      }
    });
    return providerService;
  }
}
