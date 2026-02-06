import 'package:customer/constant/constant.dart';
import 'package:customer/screen_ui/cab_service_screens/cab_home_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/profile_screen/profile_screen.dart';
import 'package:customer/screen_ui/multi_vendor_service/wallet_screen/wallet_screen.dart';
import 'package:customer/service/fire_store_utils.dart';
import 'package:get/get.dart';
import '../screen_ui/cab_service_screens/my_cab_booking_screen.dart';

class CabDashboardController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxList pageList = [].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getTaxList();
    if (Constant.walletSetting == false) {
      pageList.value = [CabHomeScreen(), const MyCabBookingScreen(), const ProfileScreen()];
    } else {
      pageList.value = [CabHomeScreen(), const MyCabBookingScreen(), const WalletScreen(), const ProfileScreen()];
    }
    super.onInit();
  }

  Future<void> getTaxList() async {
    await FireStoreUtils.getTaxList(Constant.sectionConstantModel!.id).then((value) {
      if (value != null) {
        Constant.taxList = value;
      }
    });
  }
}
