import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/inbox_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/theme_controller.dart';
import '../../../service/fire_store_utils.dart';
import '../../../themes/show_toast_dialog.dart';
import '../../../widget/firebase_pagination/src/fireStore_pagination.dart';
import '../../../widget/firebase_pagination/src/models/view_type.dart';
import 'chat_screen.dart';

class DriverInboxScreen extends StatelessWidget {
  const DriverInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark.value;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppThemeData.surfaceDark : AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text("Driver Inbox".tr, textAlign: TextAlign.start, style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 16, color: isDark ? AppThemeData.grey50 : AppThemeData.grey900)),
      ),
      body: FirestorePagination(
        //item builder type is compulsory.
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, documentSnapshots, index) {
          final data = documentSnapshots[index].data() as Map<String, dynamic>?;
          InboxModel inboxModel = InboxModel.fromJson(data!);
          return InkWell(
            onTap: () async {
              ShowToastDialog.showLoader("Please wait...".tr);

              UserModel? customer = await FireStoreUtils.getUserProfile(inboxModel.customerId.toString());
              UserModel? restaurantUser = await FireStoreUtils.getUserProfile(inboxModel.restaurantId.toString());
              ShowToastDialog.closeLoader();

              Get.to(
                const ChatScreen(),
                arguments: {
                  "customerName": customer!.fullName(),
                  "restaurantName": restaurantUser!.fullName(),
                  "orderId": inboxModel.orderId,
                  "restaurantId": restaurantUser.id,
                  "customerId": customer.id,
                  "customerProfileImage": customer.profilePictureURL,
                  "restaurantProfileImage": restaurantUser.profilePictureURL,
                  "token": restaurantUser.fcmToken,
                  "chatType": inboxModel.chatType,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Container(
                decoration: ShapeDecoration(color: isDark ? AppThemeData.grey900 : AppThemeData.grey50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: NetworkImageWidget(
                          imageUrl: inboxModel.restaurantProfileImage.toString(),
                          fit: BoxFit.cover,
                          height: Responsive.height(6, context),
                          width: Responsive.width(12, context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${inboxModel.restaurantName}",
                                    textAlign: TextAlign.start,
                                    style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 16, color: isDark ? AppThemeData.grey100 : AppThemeData.grey800),
                                  ),
                                ),
                                Text(
                                  Constant.timestampToDate(inboxModel.createdAt!),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(fontFamily: AppThemeData.regular, fontSize: 16, color: isDark ? AppThemeData.grey400 : AppThemeData.grey500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${inboxModel.lastMessage}",
                              textAlign: TextAlign.start,
                              style: TextStyle(fontFamily: AppThemeData.medium, fontSize: 14, color: isDark ? AppThemeData.grey200 : AppThemeData.grey700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        shrinkWrap: true,
        onEmpty: Constant.showEmptyView(message: "No Conversion found".tr),
        // orderBy is compulsory to enable pagination
        query: FirebaseFirestore.instance.collection('chat_driver').where("customerId", isEqualTo: FireStoreUtils.getCurrentUid()).orderBy('createdAt', descending: true),
        //Change types customerId
        viewType: ViewType.list,
        initialLoader: Constant.loader(),
        // to fetch real-time data
        isLive: true,
      ),
    );
  }
}
