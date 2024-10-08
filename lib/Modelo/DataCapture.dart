import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataCapture {
  final firebase = FirebaseFirestore.instance;

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void insertarDatos(String geoposicion, double velocidad, String hora, String sessionId) async {
    try {
      await firebase.collection('Data').add({
        "Geoposicion": geoposicion,
        "Velocidad": velocidad,
        "Hora": hora,
        "sessionId": sessionId,
        "timestamp": FieldValue.serverTimestamp()
      });
    } catch (e) {
      print("ERROR....." + e.toString());
    }
  }

  void startSpeedTracking(Function(double) onSpeedChanged) {
    Geolocator.getPositionStream().listen((position) {
      double speedMps = position.speed;
      onSpeedChanged(speedMps);
    });
  }
}

