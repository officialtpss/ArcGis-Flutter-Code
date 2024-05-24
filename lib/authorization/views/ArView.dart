import 'package:arcgis_ar/authorization/controllers/ar_controller.dart';
import 'package:arcgis_ar/authorization/views/ARLocationScreen.dart';
import 'package:arcgis_ar/authorization/views/EnableLocationScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



class ArView extends GetView<ArController> {
  ArView({Key? key}) : super(key: key);

  //SearchController airportsController = Get.find<SearchController>();
  TextEditingController textEditingController =  TextEditingController();
  TextEditingController emailController =  TextEditingController();


  @override
  Widget build(BuildContext context) {

    return Obx(() {
      return   Scaffold(
          body: controller.isPermissionGranted.value?const ARLocationScreen():const EnableLocationScreen()
      );
    });

  }

}
