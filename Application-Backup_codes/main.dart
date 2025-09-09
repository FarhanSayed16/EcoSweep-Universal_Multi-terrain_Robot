// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'screens/home_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/device_control.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Control App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/bluetooth_screen': (context) => const BluetoothScreen(),
        '/device_control': (context) {
          final BluetoothConnection? connection =
          ModalRoute.of(context)!.settings.arguments as BluetoothConnection?;
          if (connection == null) {
            return const Scaffold(
              body: Center(child: Text("No Bluetooth connection found.")),
            );
          }
          return DeviceControlScreen(connection: connection);
        },
      },
    );
  }
}
