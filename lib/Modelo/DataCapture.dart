import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trackingmovil/main.dart';

class DataCapture{
  //HomeStart dataSpeed=HomeStart();
  final firebase = FirebaseFirestore.instance;
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
    } else {
      await Geolocator.openLocationSettings();
    }
    if (!serviceEnabled) {
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
    print(await Geolocator.getCurrentPosition());
    String dato = await Geolocator.getCurrentPosition().toString();
   // await insertarDatos(dato);
    return await Geolocator.getCurrentPosition();
  }
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++
  insertarDatos(dato) async {
    try {
      await firebase.collection('Data').doc().set({"Location": dato});
    } catch (e) {
      print("ERRROR....." + e.toString());
    }
  }
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  Future<double> speed() async {
    double speedMps=0;
    Geolocator.getPositionStream().listen((position) {
      speedMps = position.speed; // This is your speed
     // dataSpeed.velocidad.text=speedMps.toString();
      print('VELOCIDAD:::' + speedMps.toString());
      DateTime now = DateTime.now();
      print(now.hour.toString() +
          ":" +
          now.minute.toString() +
          ":" +
          now.second.toString());
    });
    return await speedMps;
  }


}