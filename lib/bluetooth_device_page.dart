import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BluetoothDevicePage extends StatefulWidget {
  final BluetoothDevice device;

  const BluetoothDevicePage({super.key, required this.device});

  @override
  _BluetoothDevicePageState createState() => _BluetoothDevicePageState();
}

class _BluetoothDevicePageState extends State<BluetoothDevicePage> {
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;
  Map<String, dynamic> sensorData = {};
  bool isConnected = false;

  // Nordic UART Service UUIDs
  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String txCharacteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Read (Notifications)
  final String rxCharacteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // Write

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    try {
      await widget.device.connect();
      setState(() => isConnected = true);
      await _discoverServices();
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  Future<void> _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUuid) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() == txCharacteristicUuid) {
            txCharacteristic = characteristic;
            await _enableNotifications();
          } else if (characteristic.uuid.toString().toUpperCase() == rxCharacteristicUuid) {
            rxCharacteristic = characteristic;
          }
        }
      }
    }
  }

  Future<void> _enableNotifications() async {
    if (txCharacteristic == null) return;

    await txCharacteristic!.setNotifyValue(true);
    txCharacteristic!.onValueReceived.listen((value) {
      String newData = String.fromCharCodes(value);
      try {
        Map<String, dynamic> parsedData = jsonDecode(newData);
        setState(() {
          sensorData = parsedData;
        });
      } catch (e) {
        print("Error parsing data: $e");
      }
    });
  }

  Future<void> _sendCommand(String command) async {
    if (rxCharacteristic == null) return;

    try {
      List<int> bytes = utf8.encode(command);
      await rxCharacteristic!.write(bytes);
      print("Sent command: $command");
    } catch (e) {
      print("Failed to send command: $e");
    }
  }

  Future<void> _disconnectDevice() async {
    await widget.device.disconnect();
    setState(() {
      isConnected = false;
      sensorData.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.device.name.isNotEmpty ? widget.device.name : "Unknown Device"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isConnected ? _discoverServices : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device ID: ${widget.device.remoteId}",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: sensorData.isEmpty
                  ? Center(
                child: Text(
                  "Waiting for data...",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: sensorData.entries.map((entry) {
                  return Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isConnected ? null : _connectToDevice,
                  child: const Text("Connect"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isConnected ? _disconnectDevice : null,
                  child: const Text("Disconnect"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: isConnected ? () => _sendCommand("Hello UART") : null,
                child: const Text("Send Command"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}