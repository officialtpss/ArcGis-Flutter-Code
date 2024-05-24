
import 'package:arcgis_ar/authorization/views/EnableLocationScreen.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../authorization/bindings/ar_binding.dart';
import '../authorization/views/ArView.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [

    GetPage(
      name: _Paths.PERMISSION,
      page: () =>  const EnableLocationScreen(),
      binding: ArBinding(),
    ), GetPage(
      name: _Paths.HOME,
      page: () =>   ArView(),
      binding: ArBinding(),
    )
  ];
}
