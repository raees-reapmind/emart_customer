import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/cab_order_model.dart';

import 'subscription_plan_model.dart';
import 'admin_commission_model.dart';

class UserModel {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? profilePictureURL;
  String? fcmToken;
  String? countryCode;
  String? phoneNumber;
  num? walletAmount;
  bool? active;
  bool? isActive;
  bool? isDocumentVerify;
  Timestamp? createdAt;
  String? role;
  UserLocation? location;
  UserBankDetails? userBankDetails;
  List<ShippingAddress>? shippingAddress;
  String? carName;
  String? carNumber;
  String? carPictureURL;
  List<dynamic>? inProgressOrderID;
  List<dynamic>? orderRequestData;
  String? vendorID;
  String? zoneId;
  num? rotation;
  String? appIdentifier;
  String? provider;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;
  String? serviceType;
  String? sectionId;
  String? vehicleId;
  String? vehicleType;
  String? carMakes;
  String? reviewsCount;
  String? reviewsSum;
  AdminCommission? adminCommissionModel;
  CabOrderModel? orderCabRequestData;
  String? rideType;
  String? ownerId;
  bool? isOwner;

  UserModel({
    this.id,
    this.firstName,
    this.lastName,
    this.active,
    this.isActive,
    this.isDocumentVerify,
    this.email,
    this.profilePictureURL,
    this.fcmToken,
    this.countryCode,
    this.phoneNumber,
    this.walletAmount,
    this.createdAt,
    this.role,
    this.location,
    this.shippingAddress,
    this.carName,
    this.carNumber,
    this.carPictureURL,
    this.inProgressOrderID,
    this.orderRequestData,
    this.vendorID,
    this.zoneId,
    this.rotation,
    this.appIdentifier,
    this.provider,
    this.subscriptionPlanId,
    this.subscriptionExpiryDate,
    this.subscriptionPlan,
    this.serviceType,
    this.sectionId,
    this.vehicleId,
    this.vehicleType,
    this.carMakes,
    this.reviewsCount,
    this.reviewsSum,
    this.adminCommissionModel,
    this.orderCabRequestData,
    this.rideType,
    this.ownerId,
    this.isOwner,
  });

  String fullName() {
    return "${firstName ?? ''} ${lastName ?? ''}";
  }

  double get averageRating {
    final double sum = double.tryParse(reviewsSum ?? '0') ?? 0.0;
    final double count = double.tryParse(reviewsCount ?? '0') ?? 0.0;

    if (count <= 0) return 0.0;
    return sum / count;
  }

  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    profilePictureURL = json['profilePictureURL'];
    fcmToken = json['fcmToken'];
    countryCode = json['countryCode'];
    phoneNumber = json['phoneNumber'];
    walletAmount = json['wallet_amount'] ?? 0;
    createdAt = json['createdAt'];
    active = json['active'];
    isActive = json['isActive'];
    isDocumentVerify = json['isDocumentVerify'] ?? false;
    role = json['role'] ?? 'user';
    location = json['location'] != null ? UserLocation.fromJson(json['location']) : null;
    userBankDetails = json['userBankDetails'] != null ? UserBankDetails.fromJson(json['userBankDetails']) : null;
    if (json['shippingAddress'] != null) {
      shippingAddress = <ShippingAddress>[];
      json['shippingAddress'].forEach((v) {
        shippingAddress!.add(ShippingAddress.fromJson(v));
      });
    }
    carName = json['carName'];
    carNumber = json['carNumber'];
    carPictureURL = json['carPictureURL'];
    inProgressOrderID = json['inProgressOrderID'] ?? [];
    //orderRequestData = json['orderRequestData'] ?? [];
    if (json['orderRequestData'] is List) {
      orderRequestData = json['orderRequestData'];
    } else if (json['orderRequestData'] is Map) {
      orderRequestData = [json['orderRequestData']];
    } else {
      orderRequestData = [];
    }
    vendorID = json['vendorID'] ?? '';
    zoneId = json['zoneId'] ?? '';
    rotation = json['rotation'];
    appIdentifier = json['appIdentifier'];
    provider = json['provider'];
    subscriptionPlanId = json['subscriptionPlanId'];
    subscriptionExpiryDate = json['subscriptionExpiryDate'];
    subscriptionPlan = json['subscription_plan'] != null ? SubscriptionPlanModel.fromJson(json['subscription_plan']) : null;
    serviceType = json['serviceType'];
    sectionId = json['sectionId'] ?? '';
    vehicleId = json['vehicleId'];
    vehicleType = json['vehicleType'];
    carMakes = json['carMakes'];
    reviewsCount = json['reviewsCount'] == null ? '0' : json['reviewsCount'].toString();
    reviewsSum = json['reviewsSum'] == null ? '0' : json['reviewsSum'].toString();
    adminCommissionModel = json['adminCommission'] != null ? AdminCommission.fromJson(json['adminCommission']) : null;
    orderCabRequestData = json['ordercabRequestData'] != null ? CabOrderModel.fromJson(json['ordercabRequestData']) : null;
    rideType = json['rideType'];
    ownerId = json['ownerId'];
    isOwner = json['isOwner'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['profilePictureURL'] = profilePictureURL;
    data['fcmToken'] = fcmToken;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['wallet_amount'] = walletAmount ?? 0;
    data['createdAt'] = createdAt;
    data['active'] = active;
    data['isActive'] = isActive ?? false;
    data['role'] = role;
    data['isDocumentVerify'] = isDocumentVerify;
    data['zoneId'] = zoneId;
    data['sectionId'] = sectionId ?? '';

    if (location != null) {
      data['location'] = location!.toJson();
    }
    if (userBankDetails != null) {
      data['userBankDetails'] = userBankDetails!.toJson();
    }
    if (shippingAddress != null) {
      data['shippingAddress'] = shippingAddress!.map((v) => v.toJson()).toList();
    }
    data['serviceType'] = serviceType;
    data['rotation'] = rotation;
    data['inProgressOrderID'] = inProgressOrderID;

    if (role == Constant.userRoleDriver) {
      data['vendorID'] = vendorID;
      data['carName'] = carName;
      data['carNumber'] = carNumber;
      data['carPictureURL'] = carPictureURL;
      data['orderRequestData'] = orderRequestData;

      data['vehicleType'] = vehicleType;
      data['carMakes'] = carMakes;
      data['vehicleId'] = vehicleId ?? '';
      if (orderCabRequestData != null) {
        data['ordercabRequestData'] = orderCabRequestData!.toJson();
      }
      data['rideType'] = rideType;
      data['ownerId'] = ownerId;
      data['isOwner'] = isOwner;
    }
    if (role == Constant.userRoleVendor) {
      data['vendorID'] = vendorID;
      data['subscriptionPlanId'] = subscriptionPlanId;
      data['subscriptionExpiryDate'] = subscriptionExpiryDate;
      data['subscription_plan'] = subscriptionPlan?.toJson();
    }
    data['appIdentifier'] = appIdentifier;
    data['provider'] = provider;
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    if (adminCommissionModel != null) {
      data['adminCommission'] = adminCommissionModel!.toJson();
    }
    return data;
  }
}

class UserLocation {
  double? latitude;
  double? longitude;

  UserLocation({this.latitude, this.longitude});

  UserLocation.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class ShippingAddress {
  String? id;
  String? address;
  String? addressAs;
  String? landmark;
  String? locality;
  UserLocation? location;
  bool? isDefault;

  ShippingAddress({this.address, this.landmark, this.locality, this.location, this.isDefault, this.addressAs, this.id});

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    address = json['address'];
    landmark = json['landmark'];
    locality = json['locality'];
    isDefault = json['isDefault'];
    addressAs = json['addressAs'];
    location = json['location'] == null ? null : UserLocation.fromJson(json['location']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['address'] = address;
    data['landmark'] = landmark;
    data['locality'] = locality;
    data['isDefault'] = isDefault;
    data['addressAs'] = addressAs;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    return data;
  }

  // String getFullAddress() {
  //   return '${address == null || address!.isEmpty ? "" : address} $locality ${landmark == null || landmark!.isEmpty ? "" : landmark.toString()}';
  // }

  String getFullAddress() {
    return [
      if (address != null && address!.trim().isNotEmpty) address!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!.trim(),
    ].join(', ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class UserBankDetails {
  String bankName;
  String branchName;
  String holderName;
  String accountNumber;
  String otherDetails;

  UserBankDetails({this.bankName = '', this.otherDetails = '', this.branchName = '', this.accountNumber = '', this.holderName = ''});

  factory UserBankDetails.fromJson(Map<String, dynamic> parsedJson) {
    return UserBankDetails(
      bankName: parsedJson['bankName'] ?? '',
      branchName: parsedJson['branchName'] ?? '',
      holderName: parsedJson['holderName'] ?? '',
      accountNumber: parsedJson['accountNumber'] ?? '',
      otherDetails: parsedJson['otherDetails'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'branchName': branchName,
      'holderName': holderName,
      'accountNumber': accountNumber,
      'otherDetails': otherDetails,
    };
  }
}

class CarInfo {
  String? passenger;
  String? doors;
  String? airConditioning;
  String? gear;
  String? mileage;
  String? fuelFilling;
  String? fuelType;
  String? maxPower;
  String? mph;
  String? topSpeed;
  List<dynamic>? carImage;

  CarInfo({
    this.passenger,
    this.doors,
    this.airConditioning,
    this.gear,
    this.mileage,
    this.fuelFilling,
    this.fuelType,
    this.carImage,
    this.maxPower,
    this.mph,
    this.topSpeed,
  });

  CarInfo.fromJson(Map<String, dynamic> json) {
    passenger = json['passenger'] ?? "";
    doors = json['doors'] ?? "";
    airConditioning = json['air_conditioning'] ?? "";
    gear = json['gear'] ?? "";
    mileage = json['mileage'] ?? "";
    fuelFilling = json['fuel_filling'] ?? "";
    fuelType = json['fuel_type'] ?? "";
    carImage = json['car_image'] ?? [];
    maxPower = json['maxPower'] ?? "";
    mph = json['mph'] ?? "";
    topSpeed = json['topSpeed'] ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['passenger'] = passenger;
    data['doors'] = doors;
    data['air_conditioning'] = airConditioning;
    data['gear'] = gear;
    data['mileage'] = mileage;
    data['fuel_filling'] = fuelFilling;
    data['fuel_type'] = fuelType;
    data['car_image'] = carImage;
    data['maxPower'] = maxPower;
    data['mph'] = mph;
    data['topSpeed'] = topSpeed;
    return data;
  }
}

class UserSettings {
  bool pushNewMessages;

  bool orderUpdates;

  bool newArrivals;

  bool promotions;

  UserSettings({this.pushNewMessages = true, this.orderUpdates = true, this.newArrivals = true, this.promotions = true});

  factory UserSettings.fromJson(Map<dynamic, dynamic> parsedJson) {
    return UserSettings(
      pushNewMessages: parsedJson['pushNewMessages'] ?? true,
      orderUpdates: parsedJson['orderUpdates'] ?? true,
      newArrivals: parsedJson['newArrivals'] ?? true,
      promotions: parsedJson['promotions'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'pushNewMessages': pushNewMessages, 'orderUpdates': orderUpdates, 'newArrivals': newArrivals, 'promotions': promotions};
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:customer/constant/constant.dart';
//
// import 'subscription_plan_model.dart';
//
// class UserModel {
//   String? id;
//   String? firstName;
//   String? lastName;
//   String? email;
//   String? profilePictureURL;
//   String? fcmToken;
//   String? countryCode;
//   String? phoneNumber;
//   num? walletAmount;
//   bool? active;
//   bool? isActive;
//   bool? isDocumentVerify;
//   Timestamp? createdAt;
//   String? role;
//   UserLocation? location;
//   UserBankDetails? userBankDetails;
//   List<ShippingAddress>? shippingAddress;
//   String? carName;
//   String? carNumber;
//   String? carPictureURL;
//   List<dynamic>? inProgressOrderID;
//   List<dynamic>? orderRequestData;
//   String? vendorID;
//   String? zoneId;
//   num? rotation;
//   String? appIdentifier;
//   String? provider;
//   String? subscriptionPlanId;
//   Timestamp? subscriptionExpiryDate;
//   SubscriptionPlanModel? subscriptionPlan;
//
//   UserModel({
//     this.id,
//     this.firstName,
//     this.lastName,
//     this.active,
//     this.isActive,
//     this.isDocumentVerify,
//     this.email,
//     this.profilePictureURL,
//     this.fcmToken,
//     this.countryCode,
//     this.phoneNumber,
//     this.walletAmount,
//     this.createdAt,
//     this.role,
//     this.location,
//     this.shippingAddress,
//     this.carName,
//     this.carNumber,
//     this.carPictureURL,
//     this.inProgressOrderID,
//     this.orderRequestData,
//     this.vendorID,
//     this.zoneId,
//     this.rotation,
//     this.appIdentifier,
//     this.provider,
//     this.subscriptionPlanId,
//     this.subscriptionExpiryDate,
//     this.subscriptionPlan,
//   });
//
//   String fullName() {
//     return "${firstName ?? ''} ${lastName ?? ''}";
//   }
//
//   UserModel.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     email = json['email'];
//     firstName = json['firstName'];
//     lastName = json['lastName'];
//     profilePictureURL = json['profilePictureURL'];
//     fcmToken = json['fcmToken'];
//     countryCode = json['countryCode'];
//     phoneNumber = json['phoneNumber'];
//     walletAmount = json['wallet_amount'] ?? 0;
//     createdAt = json['createdAt'];
//     active = json['active'];
//     isActive = json['isActive'];
//     isDocumentVerify = json['isDocumentVerify'] ?? false;
//     role = json['role'] ?? 'user';
//     location = json['location'] != null ? UserLocation.fromJson(json['location']) : null;
//     userBankDetails = json['userBankDetails'] != null ? UserBankDetails.fromJson(json['userBankDetails']) : null;
//     if (json['shippingAddress'] != null) {
//       shippingAddress = <ShippingAddress>[];
//       json['shippingAddress'].forEach((v) {
//         shippingAddress!.add(ShippingAddress.fromJson(v));
//       });
//     }
//     carName = json['carName'];
//     carNumber = json['carNumber'];
//     carPictureURL = json['carPictureURL'];
//     inProgressOrderID = json['inProgressOrderID'];
//     orderRequestData = json['orderRequestData'];
//     vendorID = json['vendorID'] ?? '';
//     zoneId = json['zoneId'] ?? '';
//     rotation = json['rotation'];
//     appIdentifier = json['appIdentifier'];
//     provider = json['provider'];
//     subscriptionPlanId = json['subscriptionPlanId'];
//     subscriptionExpiryDate = json['subscriptionExpiryDate'];
//     subscriptionPlan = json['subscription_plan'] != null ? SubscriptionPlanModel.fromJson(json['subscription_plan']) : null;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = id;
//     data['email'] = email;
//     data['firstName'] = firstName;
//     data['lastName'] = lastName;
//     data['profilePictureURL'] = profilePictureURL;
//     data['fcmToken'] = fcmToken;
//     data['countryCode'] = countryCode;
//     data['phoneNumber'] = phoneNumber;
//     data['wallet_amount'] = walletAmount ?? 0;
//     data['createdAt'] = createdAt;
//     data['active'] = active;
//     data['isActive'] = isActive;
//     data['role'] = role;
//     data['isDocumentVerify'] = isDocumentVerify;
//     data['zoneId'] = zoneId;
//     if (location != null) {
//       data['location'] = location!.toJson();
//     }
//     if (userBankDetails != null) {
//       data['userBankDetails'] = userBankDetails!.toJson();
//     }
//     if (shippingAddress != null) {
//       data['shippingAddress'] = shippingAddress!.map((v) => v.toJson()).toList();
//     }
//     if (role == Constant.userRoleDriver) {
//       data['vendorID'] = vendorID;
//       data['carName'] = carName;
//       data['carNumber'] = carNumber;
//       data['carPictureURL'] = carPictureURL;
//       data['inProgressOrderID'] = inProgressOrderID;
//       data['orderRequestData'] = orderRequestData;
//       data['rotation'] = rotation;
//     }
//     if (role == Constant.userRoleVendor) {
//       data['vendorID'] = vendorID;
//       data['subscriptionPlanId'] = subscriptionPlanId;
//       data['subscriptionExpiryDate'] = subscriptionExpiryDate;
//       data['subscription_plan'] = subscriptionPlan?.toJson();
//     }
//     data['appIdentifier'] = appIdentifier;
//     data['provider'] = provider;
//
//     return data;
//   }
// }
//
