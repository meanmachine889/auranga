import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDevicePage extends StatefulWidget {
  final BluetoothDevice device;

  const BluetoothDevicePage({Key? key, required this.device}) : super(key: key);

  @override
  _BluetoothDevicePageState createState() => _BluetoothDevicePageState();
}

class _BluetoothDevicePageState extends State<BluetoothDevicePage> {
  BluetoothCharacteristic? characteristic;
  List<String> receivedData = [];

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  Future<void> connectToDevice() async {
    try {
      await widget.device.connect();
      print("Connected to ${widget.device.remoteId}");

      List<BluetoothService> services = await widget.device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.read) {
            setState(() {
              characteristic = char;
            });
            readData();
            break;
          }
        }
      }
    } catch (e) {
      print("Error connecting: $e");
    }
  }

  void readData() async {
    if (characteristic == null) return;
    characteristic!.setNotifyValue(true);
    characteristic!.onValueReceived.listen((value) {
      setState(() {
        receivedData.add(String.fromCharCodes(value));
      });
    });
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text("Connected to ${widget.device.remoteId}",
              style: const TextStyle(fontSize: 16)),
          const Divider(),
          const Text("Received Data:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: receivedData.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(receivedData[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
