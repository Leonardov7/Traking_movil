import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trackingmovil/Modelo/DataCapture.dart';
import 'package:uuid/uuid.dart'; // Importa uuid para generar un ID único

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.deepPurpleAccent,
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  HomeStart createState() => HomeStart();
}

class HomeStart extends State<Home> {
  DataCapture datos = DataCapture();
  final firebase = FirebaseFirestore.instance;
  TextEditingController velocidad = TextEditingController();
  TextEditingController hora = TextEditingController();
  TextEditingController geoposicion = TextEditingController();

  Timer? _timer;
  String? sessionId; // ID de la sesión actual
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();

    // Inicia el seguimiento de la velocidad y actualiza el controlador de texto
    datos.startSpeedTracking((newSpeed) {
      setState(() {
        velocidad.text = newSpeed.toString();
      });
    });
  }

  void startSavingData() {
    // Genera un nuevo ID de sesión
    var uuid = Uuid();
    sessionId = uuid.v4(); // Genera un UUID
    print("Nueva sesión iniciada con ID: $sessionId");

    // Almacena la sesión en Firestore
    firebase.collection('Sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'startTime': FieldValue.serverTimestamp(),
    }).then((_) {
      print("Sesión almacenada en Firestore");
    }).catchError((error) {
      print("Error al almacenar la sesión: $error");
    });

    // Inicia el temporizador para la captura de datos
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      _secondsElapsed++;

      // Convierte los segundos a formato hh:mm:ss
      final hours = _secondsElapsed ~/ 3600;
      final minutes = (_secondsElapsed % 3600) ~/ 60;
      final seconds = _secondsElapsed % 60;
      hora.text = "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

      // Obtiene la ubicación
      var posicionActual = await datos.determinePosition();
      var local = "${posicionActual.latitude}, ${posicionActual.longitude}";
      geoposicion.text = local;

      // Captura la velocidad actual
      double velocidadActual = double.tryParse(velocidad.text) ?? 0.0;

      // Guarda en la base de datos
      datos.insertarDatos(local, velocidadActual, hora.text, sessionId!);

      print("Datos guardados: Localización=$local, Velocidad=$velocidadActual, Hora=${hora.text}, Sesión=$sessionId");
    });
  }

  void stopSavingData() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _secondsElapsed = 0;
      hora.text = "00:00:00"; // Reinicia el campo de hora

      // Actualiza el documento de la sesión en Firestore con el tiempo de finalización
      if (sessionId != null) {
        firebase.collection('Sessions').doc(sessionId).update({
          'endTime': FieldValue.serverTimestamp(),
        }).then((_) {
          print("Fin de sesión actualizado en Firestore");
        }).catchError((error) {
          print("Error al actualizar el fin de sesión: $error");
        });

        // Limpia el ID de sesión actual
        print("Sesión $sessionId finalizada.");
        sessionId = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoreo de Geolocalización', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Campo de Velocidad
            _buildTextField("Velocidad", velocidad, Icons.speed),
            SizedBox(height: 20),

            // Campo de Tiempo de Ejecución
            _buildTextField("Tiempo de Ejecución", hora, Icons.timer),
            SizedBox(height: 20),

            // Campo de Geoposición
            _buildTextField("Geoposición", geoposicion, Icons.location_on),
            SizedBox(height: 40),

            // Botón Start
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: startSavingData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text("Start", style: TextStyle(fontSize: 18)),
                ),
                SizedBox(width: 20),

                // Botón Reset
                ElevatedButton(
                  onPressed: stopSavingData,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text("Reset", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: TextStyle(color: Colors.black, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
