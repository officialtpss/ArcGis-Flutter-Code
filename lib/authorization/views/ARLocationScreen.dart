import 'dart:math';
import 'dart:typed_data';
import 'package:arcgis_ar/authorization/controllers/ar_controller.dart';
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' as math;
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' as vector;

class ARLocationScreen extends StatefulWidget {
  const ARLocationScreen({super.key});

  @override
  _ARLocationScreenState createState() => _ARLocationScreenState();
}

class _ARLocationScreenState extends State<ARLocationScreen> {
  late ArCoreController arCoreController;
  Location location = Location();
  LocationData? _locationData;
  ArCoreNode? _arNode;
  final authController = Get.find<ArController>();
  @override
  void initState() {
    super.initState();
    initLocationService();
  }

  Future<void> initLocationService() async {
    var permission = await Permission.location.request();
    debugPrint("Permission ${permission.isGranted}");
    debugPrint("Permission ${permission.isProvisional}");
    debugPrint("Permission ${permission.isDenied}");
    if (permission.isGranted) {
      debugPrint("Location data callback ");

      _locationData = await location.getLocation();

      debugPrint("Location data callback current location ${_locationData!.latitude}");
    await authController.getData("${_locationData!.latitude}", "${_locationData!.longitude}");

      debugPrint("Location data ${authController.bridgeDataModel!.value.features!.length}");
      debugPrint("Location data ${authController.bridgeDataModel!.value.features![0].attributes!.lONGDD}");
     // Fluttertoast.showToast(msg: "Near By Bridge location ${authController.bridgeDataModel!.value.features![0].attributes!.lATDD} ${authController.bridgeDataModel!.value.features![0].attributes!.lONGDD}");
     // _updateArNodePosition(arCoreController); // Call the update method immediately



      location.onLocationChanged.listen((LocationData currentLocation) {
        setState(() {
          _locationData = currentLocation;
          Fluttertoast.showToast(msg: "location changed ${_locationData!.latitude} ${_locationData!.longitude}");
          authController.getData("${_locationData!.latitude}", "${_locationData!.longitude}");

          _onArCoreViewCreated(arCoreController);
        // _updateArNodePosition(arCoreController); // Update the AR node position
        });
      });
      location.changeSettings(interval: 10000);
    }
  }


  void _updateArNodePosition(ArCoreController arCoreController) {
   // if (_locationData == null) return;

    this.arCoreController = arCoreController;
    if(authController.bridgeDataModel.value.features!.isNotEmpty){
      debugPrint("Location inside ");
      // Example target location (these values should be the coordinates where you want to place your AR object)
      double targetLatitude =authController.nearestLatitude.value;  // Replace with your target latitude
      double targetLongitude = authController.nearestLongitude.value;  // Replace with your target longitude

      // Calculate the distance and bearing from the current location to the target location
      double distance = calculateDistance(
        _locationData!.latitude!,
        _locationData!.longitude!,
        targetLatitude,
        targetLongitude,
      );

      double bearing = calculateBearing(
        _locationData!.latitude!,
        _locationData!.longitude!,
        targetLatitude,
        targetLongitude,
      );

      // Convert the distance and bearing to ARCore world coordinates
      vector.Vector3 position = calculatePosition(distance, bearing);

      debugPrint(position.toString());
      // If a node already exists, remove it before adding the updated node
      if (_arNode != null) {
        debugPrint("node removed");
        arCoreController.removeNode(nodeName: _arNode!.name);
      }

      // Create a new AR node with the updated position
      _arNode = ArCoreNode(
        shape: ArCoreSphere(
          materials: [ArCoreMaterial(color: Colors.red)],
          radius: 1,
        ),
        position:position,
        name: 'targetNode',
      );

      arCoreController.addArCoreNode(_arNode!);
    }

  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Radius of the Earth in meters
    double dLat = math.radians(lat2 - lat1);
    double dLon = math.radians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(math.radians(lat1)) * cos(math.radians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;
    return distance;
  }

  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double dLon = math.radians(lon2 - lon1);
    double y = sin(dLon) * cos(math.radians(lat2));
    double x = cos(math.radians(lat1)) * sin(math.radians(lat2)) -
        sin(math.radians(lat1)) * cos(math.radians(lat2)) * cos(dLon);
    double bearing = math.degrees(atan2(y, x));
    return (bearing + 360) % 360;
  }

  vector.Vector3 calculatePosition(double distance, double bearing) {
    // This is a simplified approximation
    double x = distance * cos(math.radians(bearing));
    double z = distance * sin(math.radians(bearing));
    return vector.Vector3(x, 0, -z);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: /*Center(child: ElevatedButton(onPressed:()=>   debugPrint("Location data ${_locationData?.latitude}"),child: const Text("Don't click me"),),)*/
      ArCoreView(
        type: ArCoreViewType.STANDARDVIEW,
        onArCoreViewCreated: _onArCoreViewCreated,
        enablePlaneRenderer: true,
        enableTapRecognizer: true,
      ),
    );
  }

  Future<Uint8List> _generateTextTexture(String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(const Offset(0, 0), const Offset(200, 100)));

    final paint = Paint()..color = Colors.black;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 30),
      ),
      textDirection: TextDirection.ltr,
    );

    canvas.drawRect(const Rect.fromLTWH(0, 0, 300, 100), paint);
    textPainter.layout(maxWidth: 300);
    textPainter.paint(canvas, const Offset(40, 10));

    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 100);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  void _onArCoreViewCreated(ArCoreController controller) async{
    arCoreController = controller;
    final ByteData earthMap = await rootBundle.load("assets/images/bridge.png");

    final material1 = ArCoreMaterial(
      color: Colors.white,
      textureBytes: earthMap.buffer.asUint8List(),
    );

    final sphere = ArCoreImage(
     bytes: earthMap.buffer.asUint8List(),
      width: 450,
      height: 180// Adjust the radius as needed
    );

    var childNode = ArCoreNode(
        image: sphere,
        position: vector.Vector3(0,-0.3,0)
    );

    final textureBytes = await _generateTextTexture("Bridge ${authController.structureNumber.value} \n${authController.nearestBridge.value.toStringAsFixed(2)} feet ahead");

    final material = ArCoreMaterial(
      color: Colors.transparent,
      textureBytes: textureBytes,
    );

    if (_arNode != null) {
      debugPrint("node removed");
      arCoreController.removeNode(nodeName: _arNode!.name);
    }
    final plane = ArCoreCube(

      materials: [material],
      size: vector.Vector3(1.0, 0.3, 0.01),

    );

    _arNode = ArCoreNode(
      children: [childNode],
      shape: plane,
      position: vector.Vector3(0, 0, -5),
    );

    arCoreController.addArCoreNode(_arNode!);
   /* controller.addArCoreNode(_arNode!).then((value) {
      debugPrint("Node added with anchor: $_arNode!");
    }).catchError((error) {
      debugPrint("Error adding node with anchor: $error");
    });*/
  }





  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }
}
