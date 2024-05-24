import 'package:arcgis_ar/model/BridgeDataModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get_rx/get_rx.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../service/http_service.dart';
import '../../service/http_service_impl.dart';

class ArController extends GetxController {


  final HttpService _httpService = Get.find<HttpServiceImpl>();

  RxDouble nearestBridge =  0.0.obs;
  RxDouble nearestBridgeMetre =  0.0.obs;
  RxDouble nearestLatitude =  0.0.obs;
  RxDouble nearestLongitude =  0.0.obs;
  RxString structureNumber =  "".obs;
  Rx<BridgeDataModel> bridgeDataModel = BridgeDataModel().obs;


  double test = 0.0;
  var isDataLoading = false.obs;
  var isPermissionGranted = false.obs;


  Widget loader() {
    return isDataLoading.value? Container(
      color: Colors.grey[200],
      width: 90.0,
      height: 90.0,
      child:  const Padding(padding: EdgeInsets.all(5.0),child: Center(child: CircularProgressIndicator())),
    ): Container();
  }

  @override
  void onInit() async{
    super.onInit();
    isPermissionGranted.value = await Permission.location.isGranted;
  }

  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();

  }
  Future<void> getData(String lat, String lng) async {
    try {

      dio.Response? response = await _httpService.getRequest(
          "xOi1kZaI0eWDREZv/arcgis/rest/services/NTAD_National_Bridge_Inventory/FeatureServer/0/query?where=STATE_CODE_001=39&geometry=$lng,$lat&geometryType=esriGeometryPoint&spatialRel=esriSpatialRelIntersects&distance=1000&units=esriSRUnit_Meter&outFields=RECORD_TYPE_005A,ROUTE_NUMBER_005D,NAVIGATION_038,LATDD,LONGDD,STATE_CODE_001,PLACE_CODE_004,STRUCTURE_NUMBER_008&outSR=4326&f=json");
      debugPrint("response!.data");

      debugPrint("${response!.data}");

      bridgeDataModel.value = BridgeDataModel.fromJson(response.data);

      double minDistance = double.infinity;
      double nearestLat = 0.0;
      double nearestLng = 0.0;
      String sstructureNumber = "";

      if(bridgeDataModel.value.features!.isNotEmpty){

        for (int i = 0; i < bridgeDataModel.value.features!.length; i++) {
          double bridgeLat =
          bridgeDataModel.value.features![i].attributes!.lATDD!;
          double bridgeLng =
          bridgeDataModel.value.features![i].attributes!.lONGDD!;
          String bridgeStructureNumber =
          bridgeDataModel.value.features![i].attributes!.sTRUCTURENUMBER008!;

          var distance = Geolocator.distanceBetween(
              double.parse(lat), double.parse(lng), bridgeLat, bridgeLng);

          if (distance < minDistance) {
            minDistance = distance;
            nearestLat = bridgeLat;
            nearestLng = bridgeLng;
            sstructureNumber = bridgeStructureNumber;
          }
        }
        debugPrint("Nearest Bridge Latitude: $nearestLat");
        debugPrint("Nearest Bridge Longitude: $nearestLng");
        debugPrint("Distance to Nearest Bridge: $minDistance meters");
        var feet = minDistance * 0.3048;
        nearestBridgeMetre(minDistance);
        nearestBridge(feet);
        nearestLatitude(nearestLat);
        nearestLongitude(nearestLng);
        structureNumber(sstructureNumber);
      }
      else{
        Fluttertoast.showToast(msg: "No bridge found within 1 km");
      }


        } catch (ex) {
      debugPrint(ex.toString());
    }
  }







}
