import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trackingmovil/Modelo/DataCapture.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  HomeStart createState() => HomeStart();
}

class HomeStart extends State<Home> {
  late Position position;
  DataCapture datos = DataCapture();
  final firebase = FirebaseFirestore.instance;
  TextEditingController velocidad=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traking Movile',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tracking...'),
          backgroundColor: Colors.black45,
        ),
        body: SingleChildScrollView(
          child: Center(
              child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: Size(400, 90)),
                      onPressed: () async {
                        velocidad.text= await datos.speed().toString();
                        var local =
                            (await datos.determinePosition()).toString();
                      },
                      child: Text(
                        'Start',
                        style: TextStyle(color: Colors.white, fontSize: 60),
                      ))),
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(400, 90)),
                  onPressed: () {
                    print('esto es una prueba de interrución');
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(color: Colors.white, fontSize: 60),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(top: 30),
              child: TextField(
                controller: velocidad,
                style: TextStyle(color: Colors.grey),
                decoration: InputDecoration(
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    ),
                  labelText: 'Velocidad'

                ),
              ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}
