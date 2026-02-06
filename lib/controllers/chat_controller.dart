import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/conversation_model.dart';
import '../models/inbox_model.dart';
import '../service/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../service/send_notification.dart';

class ChatController extends GetxController {
  Rx<TextEditingController> messageController = TextEditingController().obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    // TODO: implement onInit
    if (scrollController.hasClients) {
      Timer(const Duration(milliseconds: 500), () => scrollController.jumpTo(scrollController.position.maxScrollExtent));
    }
    getArgument();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxString orderId = "".obs;
  RxString customerId = "".obs;
  RxString customerName = "".obs;
  RxString customerProfileImage = "".obs;
  RxString restaurantId = "".obs;
  RxString restaurantName = "".obs;
  RxString restaurantProfileImage = "".obs;
  RxString token = "".obs;
  RxString chatType = "".obs;

  void getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderId.value = argumentData['orderId'];
      customerId.value = argumentData['customerId'];
      customerName.value = argumentData['customerName'];
      customerProfileImage.value = argumentData['customerProfileImage'] ?? "";
      restaurantId.value = argumentData['restaurantId'];
      restaurantName.value = argumentData['restaurantName'];
      restaurantProfileImage.value = argumentData['restaurantProfileImage'] ?? "";
      token.value = argumentData['token'] ?? "";
      chatType.value = argumentData['chatType'];
    }
    isLoading.value = false;
  }

  Future<void> sendMessage(String message, Url? url, String videoThumbnail, String messageType) async {
    InboxModel inboxModel = InboxModel(
      lastSenderId: customerId.value,
      customerId: customerId.value,
      customerName: customerName.value,
      restaurantId: restaurantId.value,
      restaurantName: restaurantName.value,
      createdAt: Timestamp.now(),
      orderId: orderId.value,
      customerProfileImage: customerProfileImage.value,
      restaurantProfileImage: restaurantProfileImage.value,
      lastMessage: messageController.value.text,
      chatType: chatType.value,
    );

    print("chatType: ${chatType.value}");
    if (chatType.value == "Driver") {
      await FireStoreUtils.addDriverInbox(inboxModel);
    } else if (chatType.value == "worker" || chatType.value == "Worker") {
      await FireStoreUtils.addWorkerInbox(inboxModel);
    } else if (chatType.value == "provider" || chatType.value == "Provider") {
      await FireStoreUtils.addProviderInbox(inboxModel);
    } else {
      await FireStoreUtils.addRestaurantInbox(inboxModel);
    }

    ConversationModel conversationModel = ConversationModel(
      id: const Uuid().v4(),
      message: message,
      senderId: customerId.value,
      receiverId: restaurantId.value,
      createdAt: Timestamp.now(),
      url: url,
      orderId: orderId.value,
      messageType: messageType,
      videoThumbnail: videoThumbnail,
    );

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent a message".tr;
      } else if (url.mime.contains('video')) {
        conversationModel.message = "Sent a video".tr;
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a audio".tr;
      }
    }

    if (chatType.value == "Driver") {
      await FireStoreUtils.addDriverChat(conversationModel);
    } else if (chatType.value == "worker" || chatType.value == "Worker") {
      await FireStoreUtils.addWorkerChat(conversationModel);
    } else if (chatType.value == "provider" || chatType.value == "Provider") {
      await FireStoreUtils.addProviderChat(conversationModel);
    } else {
      await FireStoreUtils.addRestaurantChat(conversationModel);
    }

    //await SendNotification.sendChatFcmMessage(customerName.value, conversationModel.message.toString(), token.value, {});
    await SendNotification.sendChatFcmMessage(customerName.value, conversationModel.message.toString(), token.value, {
      "type": "chat",
      "chatType": chatType.value,
      "orderId": orderId.value,
      "customerId": customerId.value,
      "customerName": customerName.value,
      "customerProfileImage": customerProfileImage.value,
      "restaurantId": restaurantId.value,
      "restaurantName": restaurantName.value,
      "restaurantProfileImage": restaurantProfileImage.value,
      "token": token.value,
    });
  }

  final ImagePicker imagePicker = ImagePicker();

  // Future pickFile({required ImageSource source}) async {
  //   try {
  //     XFile? image = await imagePicker.pickImage(source: source);
  //     if (image == null) return;
  //     Url url = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), Get.context!);
  //     sendMessage('', url, '', 'image');
  //     Get.back();
  //   } on PlatformException catch (e) {
  //     ShowToastDialog.showToast("${"failed_to_pick".tr} : \n $e");
  //   }
  // }
}
