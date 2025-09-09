import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'device_control.dart'; // ✅ Import the DeviceControlScreen

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? connectedDevice;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _getBondedDevices();
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      print("❌ Error fetching bonded devices: $e");
    }

    setState(() {
      devicesList = devices;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });

    BluetoothConnection.toAddress(device.address).then((connection) {
      print("✅ Connected to ${device.name}");
      setState(() {
        connectedDevice = device;
        isConnecting = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceControlScreen(connection: connection),
        ),
      );
    }).catchError((error) {
      print("❌ Connection failed: $error");
      setState(() {
        isConnecting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Classic Bluetooth Devices")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _getBondedDevices,
            child: const Text("Refresh Paired Devices"),
          ),
          Expanded(
            child: devicesList.isEmpty
                ? const Center(child: Text("No paired devices found"))
                : ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                final device = devicesList[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address),
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),
          if (isConnecting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
