import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';


class AppBluetoothService {
  static final AppBluetoothService _instance = AppBluetoothService._internal();
  factory AppBluetoothService() => _instance;
  AppBluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  bool isConnected = false;
  bool isAutoMode = false;

  final StreamController<bool> _isScanningController = StreamController<bool>.broadcast();
  final StreamController<List<BluetoothDiscoveryResult>> _scanResultsController = StreamController<List<BluetoothDiscoveryResult>>.broadcast();
  final StreamController<String> _sensorDataController = StreamController<String>.broadcast();

  Stream<bool> get isScanning => _isScanningController.stream;
  Stream<List<BluetoothDiscoveryResult>> get scannedDevices => _scanResultsController.stream;
  Stream<String> get sensorDataStream => _sensorDataController.stream;

  List<BluetoothDiscoveryResult> _foundDevices = [];

  // Start scanning
  Future<void> startScanning() async {
    _foundDevices.clear();
    _isScanningController.add(true);
    _scanResultsController.add(_foundDevices);

    FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      final existingIndex = _foundDevices.indexWhere((r) => r.device.address == result.device.address);
      if (existingIndex >= 0) {
        _foundDevices[existingIndex] = result;
      } else {
        _foundDevices.add(result);
      }
      _scanResultsController.add(List.from(_foundDevices));
    }).onDone(() {
      _isScanningController.add(false);
    });
  }

  void stopScanning() {
    FlutterBluetoothSerial.instance.cancelDiscovery();
    _isScanningController.add(false);
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (isConnected && _connectedDevice?.address == device.address) {
      print("Already connected to ${device.name}");
      return;
    }

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      isConnected = true;
      print("✅ Connected to ${device.name}");

      _connection!.input!.listen((data) {
        final received = String.fromCharCodes(data);
        if (received.startsWith("DIST:")) {
          _handleSensorData(received);
        }
      }).onDone(() {
        print("🔌 Disconnected by remote");
        disconnectFromDevice();
      });
    } catch (e) {
      isConnected = false;
      print("❌ Connection error: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (!isConnected || _connection == null) {
      print("⚠ Bluetooth not connected");
      return;
    }

    if (isAutoMode && message != "AUTO_OFF") {
      print("🚫 Cannot send manual commands in Auto Mode.");
      return;
    }

    _connection!.output.add(Uint8List.fromList(message.codeUnits));
    await _connection!.output.allSent;
    print("📤 Sent: $message");

    if (message == "AUTO_ON") isAutoMode = true;
    if (message == "AUTO_OFF") isAutoMode = false;
  }

  void _handleSensorData(String data) {
    List<String> parts = data.replaceFirst("DIST:", "").split(",");

    if (parts.length == 2) {
      String formattedData = "Front: ${parts[0]} cm | Bottom: ${parts[1]} cm";
      _sensorDataController.add(formattedData);
      print("📡 Sensor Data Updated: $formattedData");
    } else {
      print("⚠ Invalid sensor data received: $data");
    }
  }

  Future<void> disconnectFromDevice() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    _connectedDevice = null;
    isConnected = false;
    isAutoMode = false;
    print("🔌 Disconnected from device");
  }

  void dispose() {
    _isScanningController.close();
    _scanResultsController.close();
    _sensorDataController.close();
  }
}
