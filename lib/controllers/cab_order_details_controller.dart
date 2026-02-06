import 'dart:convert';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/rating_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart' as osm;
import '../models/cab_order_model.dart';
import '../models/user_model.dart';
import '../service/fire_store_utils.dart';
import '../themes/app_them_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CabOrderDetailsController extends GetxController {
  Rx<CabOrderModel> cabOrder = CabOrderModel().obs;

  RxBool isLoading = false.obs;

  // Google Maps Data
  RxSet<gmap.Marker> googleMarkers = <gmap.Marker>{}.obs;
  RxSet<gmap.Polyline> googlePolylines = <gmap.Polyline>{}.obs;

  // OSM Data
  RxList<osm.LatLng> osmPolyline = <osm.LatLng>[].obs;

  final String googleApiKey = Constant.mapAPIKey;

  final Rx<UserModel> driverUser = UserModel().obs;
  Rx<RatingModel> ratingModel = RatingModel().obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      cabOrder.value = args['cabOrderModel'] as CabOrderModel;
      calculateTotalAmount();
      _setMarkers();
      _getGoogleRoute();
      _getOsmRoute();
    }
    fetchDriverDetails();
  }

  RxDouble subTotal = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble taxAmount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;

  String formatDate(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat("dd MMM yyyy, hh:mm a").format(dateTime);
  }

  Future<void> fetchDriverDetails() async {
    if (cabOrder.value.driverId != null) {
      await FireStoreUtils.getUserProfile(cabOrder.value.driverId ?? '').then((value) {
        if (value != null) {
          driverUser.value = value;
        }
      });

      print(driverUser.value.toJson());
      await FireStoreUtils.getReviewsbyID(cabOrder.value.id.toString()).then((value) {
        if (value != null) {
          ratingModel.value = value;
        }
      });
    }
  }

  void calculateTotalAmount() {
    taxAmount = 0.0.obs;
    discount = 0.0.obs;
    subTotal.value = double.parse(cabOrder.value.subTotal.toString());
    discount.value = double.parse(cabOrder.value.discount ?? '0.0');

    if (cabOrder.value.taxSetting != null) {
      for (var element in cabOrder.value.taxSetting!) {
        taxAmount.value = (taxAmount.value + Constant.calculateTax(amount: (subTotal.value - discount.value).toString(), taxModel: element));
      }
    }

    totalAmount.value = (subTotal.value - discount.value) + taxAmount.value;
    update();
  }

  void _setMarkers() {
    final sourceLat = cabOrder.value.sourceLocation!.latitude;
    final sourceLng = cabOrder.value.sourceLocation!.longitude;
    final destLat = cabOrder.value.destinationLocation!.latitude;
    final destLng = cabOrder.value.destinationLocation!.longitude;

    googleMarkers.value = {
      gmap.Marker(markerId: const gmap.MarkerId('source'), position: gmap.LatLng(sourceLat!, sourceLng!), icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueGreen)),
      gmap.Marker(markerId: const gmap.MarkerId('destination'), position: gmap.LatLng(destLat!, destLng!), icon: gmap.BitmapDescriptor.defaultMarkerWithHue(gmap.BitmapDescriptor.hueRed)),
    };
  }

  ///Google Directions API
  Future<void> _getGoogleRoute() async {
    final src = cabOrder.value.sourceLocation;
    final dest = cabOrder.value.destinationLocation;

    final url = "https://maps.googleapis.com/maps/api/directions/json?origin=${src!.latitude},${src.longitude}&destination=${dest!.latitude},${dest.longitude}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isNotEmpty) {
      final points = data["routes"][0]["overview_polyline"]["points"];
      final polylinePoints = PolylinePoints.decodePolyline(points);

      final polylineCoords = polylinePoints.map((p) => gmap.LatLng(p.latitude, p.longitude)).toList();

      googlePolylines.value = {gmap.Polyline(polylineId: const gmap.PolylineId("google_route"), color: AppThemeData.onDemandDark100, width: 5, points: polylineCoords)};
    }
  }

  /// OSM Route (OSRM API)
  Future<void> _getOsmRoute() async {
    final src = cabOrder.value.sourceLocation;
    final dest = cabOrder.value.destinationLocation;

    final url = "http://router.project-osrm.org/route/v1/driving/${src!.longitude},${src.latitude};${dest!.longitude},${dest.latitude}?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data["routes"].isNotEmpty) {
      final coords = data["routes"][0]["geometry"]["coordinates"] as List<dynamic>;

      osmPolyline.value = coords.map((c) => osm.LatLng(c[1].toDouble(), c[0].toDouble())).toList();
    }
  }
}
