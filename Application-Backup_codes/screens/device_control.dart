import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';

class DeviceControlScreen extends StatefulWidget {
  final BluetoothConnection connection;

  const DeviceControlScreen({Key? key, required this.connection}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  // Core State Variables
  bool isConnected = false;
  String lastCommandSent = "None"; // This is now only for display purposes
  bool isAutoMode = false;

  // Sensor State Variables
  double frontDistance = -1;
  double leftDistance = -1;
  double rightDistance = -1;
  String rawSensorData = "Waiting for data...";

  final double maxVisualizerDistance = 200.0;

  @override
  void initState() {
    super.initState();
    isConnected = widget.connection.isConnected;
    _listenToIncomingData();
  }

  void _listenToIncomingData() {
    widget.connection.input?.listen((Uint8List data) {
      if (!mounted) return;
      String message = utf8.decode(data, allowMalformed: true).trim();

      if (message.startsWith("DIST:")) {
        final payload = message.substring(5);
        final parts = payload.split(',');

        setState(() {
          rawSensorData = "F:${parts.length > 0 ? parts[0] : 'N/A'} | L:${parts.length > 1 ? parts[1] : 'N/A'} | R:${parts.length > 2 ? parts[2] : 'N/A'}";
        });

        if (parts.length == 3) {
          setState(() {
            frontDistance = double.tryParse(parts[0]) ?? -1;
            leftDistance = double.tryParse(parts[1]) ?? -1;
            rightDistance = double.tryParse(parts[2]) ?? -1;
          });
        }
      }
    }).onDone(() {
      if (mounted) {
        print("🔌 Connection closed.");
        setState(() => isConnected = false);
      }
    });
  }

  // ===== CORRECTED FUNCTION =====
  void _sendCommand(String command) {
    if (!isConnected) return;
    if (isAutoMode && command != "AUTO_OFF") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Disable Auto Mode for manual control."), duration: Duration(seconds: 2)),
      );
      return;
    }

    // REMOVED the complex 'if (command != lastCommandSent...)' condition.
    // Now, we simply send any command that comes in.
    try {
      widget.connection.output.add(utf8.encode(command + '\n'));
      widget.connection.output.allSent;
      print("📤 Sent: $command");
      if(mounted) setState(() => lastCommandSent = command);
    } catch (e) {
      print("Error sending data: $e");
      if(mounted) setState(() => isConnected = false);
    }
  }

  void _toggleAutoMode(bool enable) {
    setState(() => isAutoMode = enable);
    _sendCommand(enable ? "AUTO_ON" : "AUTO_OFF");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Controller'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: isConnected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _buildPortraitLayout();
          } else {
            return _buildLandscapeLayout();
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildSensorDashboard(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildMovementControls(),
                const SizedBox(height: 16),
                _buildArmControlsPanel(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: _buildMovementControls(isScrollable: true),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: _buildSensorDashboard(),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            child: _buildArmControlsPanel(isScrollable: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorDashboard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sensor Dashboard", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(rawSensorData, style: Theme.of(context).textTheme.bodySmall),
            const Divider(height: 16),
            _SensorVisualizer(distance: frontDistance, icon: Icons.arrow_upward, label: "Front"),
            const SizedBox(height: 8),
            _SensorVisualizer(distance: leftDistance, icon: Icons.arrow_back, label: "Left"),
            const SizedBox(height: 8),
            _SensorVisualizer(distance: rightDistance, icon: Icons.arrow_forward, label: "Right"),
            const Divider(height: 16),
            SwitchListTile(
              title: const Text("Auto Mode"),
              value: isAutoMode,
              onChanged: _toggleAutoMode,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementControls({bool isScrollable = false}) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Movement", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        Joystick(
          listener: (details) {
            double x = details.x;
            double y = details.y;
            if (x.abs() < 0.2 && y.abs() < 0.2) _sendCommand("STOP");
            else if (y < -0.5) _sendCommand("FORWARD");
            else if (y > 0.5) _sendCommand("BACKWARD");
            else if (x > 0.5) _sendCommand("RIGHT");
            else if (x < -0.5) _sendCommand("LEFT");
          },
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isScrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }

  Widget _buildArmControlsPanel({bool isScrollable = false}) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Robotic Arm Control", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ArmControlButton(icon: Icons.rotate_left, label: "Base Left", startCmd: "BASE_LEFT_START", stopCmd: "BASE_LEFT_STOP"),
            _ArmControlButton(icon: Icons.rotate_right, label: "Base Right", startCmd: "BASE_RIGHT_START", stopCmd: "BASE_RIGHT_STOP"),
            _ArmControlButton(icon: Icons.arrow_upward, label: "Arm Up", startCmd: "ARM_UP_START", stopCmd: "ARM_UP_STOP"),
            _ArmControlButton(icon: Icons.arrow_downward, label: "Arm Down", startCmd: "ARM_DOWN_START", stopCmd: "ARM_DOWN_STOP"),
            _ArmControlButton(icon: Icons.arrow_back, label: "Arm Fwd", startCmd: "FOREARM_FORWARD_START", stopCmd: "FOREARM_FORWARD_STOP"),
            _ArmControlButton(icon: Icons.arrow_forward, label: "Arm Bwd", startCmd: "FOREARM_BACKWARD_START", stopCmd: "FOREARM_BACKWARD_STOP"),
            _ArmControlButton(icon: Icons.rotate_left_sharp, label: "Wrist L", startCmd: "WRIST_ROTATE_LEFT_START", stopCmd: "WRIST_ROTATE_LEFT_STOP"),
            _ArmControlButton(icon: Icons.rotate_right_sharp, label: "Wrist R", startCmd: "WRIST_ROTATE_RIGHT_START", stopCmd: "WRIST_ROTATE_RIGHT_STOP"),
            _ArmControlButton(icon: Icons.open_in_full, label: "Grip Open", startCmd: "GRIP_OPEN_START", stopCmd: "GRIP_OPEN_STOP"),
            _ArmControlButton(icon: Icons.close_fullscreen, label: "Grip Close", startCmd: "GRIP_CLOSE_START", stopCmd: "GRIP_CLOSE_STOP"),
          ],
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isScrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }

  Widget _ArmControlButton({
    required IconData icon,
    required String label,
    required String startCmd,
    required String stopCmd,
  }) {
    return Listener(
      onPointerDown: (_) => _sendCommand(startCmd),
      onPointerUp: (_) => _sendCommand(stopCmd),
      child: Material(
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

}

class _SensorVisualizer extends StatelessWidget {
  final String label;
  final IconData icon;
  final double distance;
  final double maxDistance = 200.0;

  const _SensorVisualizer({
    Key? key,
    required this.label,
    required this.icon,
    required this.distance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double proximity = 0.0;
    if (distance >= 0) {
      proximity = 1.0 - (distance / maxDistance).clamp(0.0, 1.0);
    }
    Color progressColor = Color.lerp(Colors.green, Colors.red, proximity) ?? Colors.red;

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(width: 45, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: LinearProgressIndicator(
            value: proximity,
            backgroundColor: progressColor.withOpacity(0.2),
            color: progressColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 55,
          child: Text(
            distance < 0 ? "N/A" : "${distance.toStringAsFixed(0)} cm",
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}