import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const BluetoothScannerPage(),
    );
  }
}

class BluetoothScannerPage extends StatefulWidget {
  const BluetoothScannerPage({super.key});

  @override
  _BluetoothScannerPageState createState() => _BluetoothScannerPageState();
}

class _BluetoothScannerPageState extends State<BluetoothScannerPage> {
  List<BluetoothDevice> pairedDevices = [];
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String receivedData = "No data received";

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      getPairedDevices();
      startScan();
    });
  }

  /// ✅ Request necessary Bluetooth & Location permissions
  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request(); // Required for scanning
  }

  /// ✅ Fetch paired devices
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = (await FlutterBluePlus.systemDevices) as List<BluetoothDevice>;
    setState(() {
      pairedDevices = devices;
    });
  }

  /// ✅ Start scanning for Bluetooth devices
  void startScan() async {
    if (!(await FlutterBluePlus.isSupported)) {
      print("BLE not supported on this device");
      return;
    }

    if (!(await FlutterBluePlus.isOn)) {
      print("Bluetooth is OFF. Please enable Bluetooth.");
      return;
    }

    if (await FlutterBluePlus.isScanning.first) {
      FlutterBluePlus.stopScan();
    }

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  /// ✅ Connect to selected Bluetooth device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.read) {
            setState(() {
              connectedDevice = device;
              characteristic = char;
            });
            readSensorData();
            break;
          }
        }
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  /// ✅ Read data from connected Bluetooth device
  void readSensorData() async {
    if (characteristic != null) {
      await characteristic!.setNotifyValue(true);
      characteristic!.lastValueStream.listen((value) {
        setState(() {
          receivedData = value.toString();
        });
        print("Received Data: $value");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Scanner")),
      body: connectedDevice == null
          ? Column(
        children: [
          ElevatedButton(
            onPressed: () {
              getPairedDevices();
              startScan();
            },
            child: const Text("Refresh Devices"),
          ),
          const SizedBox(height: 10),
          const Text("🔵 Paired Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: pairedDevices.length,
              itemBuilder: (context, index) {
                final device = pairedDevices[index];
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                  subtitle: Text(device.remoteId.str),
                  onTap: () => connectToDevice(device),
                );
              },
            ),
          ),
          const Divider(),
          const Text("🔍 Scanned Devices", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                  subtitle: Text(device.remoteId.str),
                  onTap: () => connectToDevice(device),
                );
              },
            ),
          ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Connected to ${connectedDevice!.name}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Received Data: $receivedData",
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                connectedDevice!.disconnect();
                setState(() {
                  connectedDevice = null;
                  receivedData = "No data received";
                });
              },
              child: const Text("Disconnect"),
            ),
          ],
        ),
      ),
    );
  }
}
