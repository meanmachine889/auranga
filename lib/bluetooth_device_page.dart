import 'package:auranga/Screens/HomeScreen.dart';
import 'package:auranga/live_location_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class BluetoothDevicePage extends StatefulWidget {
  final BluetoothDevice device;

  const BluetoothDevicePage({super.key, required this.device});

  @override
  _BluetoothDevicePageState createState() => _BluetoothDevicePageState();
}

class _BluetoothDevicePageState extends State<BluetoothDevicePage> {

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;
  Map<String, dynamic> sensorData = {};
  bool isConnected = false;

  List<FlSpot> accelX = [], accelY = [], accelZ = [];
  List<FlSpot> gyroX = [], gyroY = [], gyroZ = [];
  int dataIndex = 0;
  final int maxDataPoints = 30; // Keep only the last 30 data points

  final String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  final String txCharacteristicUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";
  final String rxCharacteristicUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";

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
          _updateGraphData();
        });
      } catch (e) {
        print("Error parsing data: $e");
      }
    });
  }
  double minY = 0, maxY = 0;
  void _updateGraphData() {
    double newAccelX = sensorData["accel_x"] ?? 0;
    double newAccelY = sensorData["accel_y"] ?? 0;
    double newAccelZ = sensorData["accel_z"] ?? 0;
    double newGyroX = sensorData["gyro_x"] ?? 0;
    double newGyroY = sensorData["gyro_y"] ?? 0;
    double newGyroZ = sensorData["gyro_z"] ?? 0;

    const int maxDataPoints = 30; // 5 updates/sec * 30 sec

    // Add new data points
    accelX.add(FlSpot(dataIndex.toDouble(), newAccelX));
    accelY.add(FlSpot(dataIndex.toDouble(), newAccelY));
    accelZ.add(FlSpot(dataIndex.toDouble(), newAccelZ));
    gyroX.add(FlSpot(dataIndex.toDouble(), newGyroX));
    gyroY.add(FlSpot(dataIndex.toDouble(), newGyroY));
    gyroZ.add(FlSpot(dataIndex.toDouble(), newGyroZ));

    // Remove old data if exceeding maxDataPoints
    if (accelX.length > maxDataPoints) accelX.removeAt(0);
    if (accelY.length > maxDataPoints) accelY.removeAt(0);
    if (accelZ.length > maxDataPoints) accelZ.removeAt(0);
    if (gyroX.length > maxDataPoints) gyroX.removeAt(0);
    if (gyroY.length > maxDataPoints) gyroY.removeAt(0);
    if (gyroZ.length > maxDataPoints) gyroZ.removeAt(0);

    // Update min and max values dynamically
    List<double> allValues = [
      ...accelX.map((e) => e.y),
      ...accelY.map((e) => e.y),
      ...accelZ.map((e) => e.y),
      ...gyroX.map((e) => e.y),
      ...gyroY.map((e) => e.y),
      ...gyroZ.map((e) => e.y),
    ];

    if (allValues.isNotEmpty) {
      minY = allValues.reduce((a, b) => a < b ? a : b);
      maxY = allValues.reduce((a, b) => a > b ? a : b);
    }

    // Adjust X values so that the graph remains continuous
    double firstX = accelX.isNotEmpty ? accelX.first.x : 0;
    accelX = accelX.map((e) => FlSpot(e.x - firstX, e.y)).toList();
    accelY = accelY.map((e) => FlSpot(e.x - firstX, e.y)).toList();
    accelZ = accelZ.map((e) => FlSpot(e.x - firstX, e.y)).toList();
    gyroX = gyroX.map((e) => FlSpot(e.x - firstX, e.y)).toList();
    gyroY = gyroY.map((e) => FlSpot(e.x - firstX, e.y)).toList();
    gyroZ = gyroZ.map((e) => FlSpot(e.x - firstX, e.y)).toList();

    dataIndex++;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.device.name.isNotEmpty ? widget.device.name : "Unknown Device"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSensorGrid("Acceleration", sensorData["accel_x"], sensorData["accel_y"], sensorData["accel_z"]),
              SizedBox(height: 500,child: _buildMinimalChart("", accelX, accelY, accelZ)),  // Set fixed height
              _buildSensorGrid("Gyroscope", sensorData["gyro_x"], sensorData["gyro_y"], sensorData["gyro_z"]),
              SizedBox(height: 500,child: _buildMinimalChart("", gyroX, gyroY, gyroZ)),
              // SizedBox(
              //   height: 500, // Set a fixed height for HomeScreen
              //   child: HomeScreen(),
              // ),// Set fixed height
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMinimalChart(String title, List<FlSpot> x, List<FlSpot> y, List<FlSpot> z) {
    if (x.isEmpty || y.isEmpty || z.isEmpty) {
      return Center(
        child: Text("Waiting for data...", style: TextStyle(color: Colors.white)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.black, // Dark background
            borderRadius: BorderRadius.circular(12), // Rounded corners
            border: Border.all(color: Colors.white24), // Subtle border
          ),
          padding: EdgeInsets.all(10),
          child: SizedBox(
            height: 180,
            child: AspectRatio(
              aspectRatio: 1.8,
              child: LineChart(
                  LineChartData(
                    minX: x.first.x,
                    maxX: x.last.x,
                    minY: minY - 1, // Add some padding for better visualization
                    maxY: maxY + 1,
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _buildAreaChartData(x, Colors.red),
                      _buildAreaChartData(y, Colors.green),
                      _buildAreaChartData(z, Colors.blue),
                    ],
                  )
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildAreaChartData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      gradient: LinearGradient( // Use gradient instead of colors
        colors: [color, color.withOpacity(0.5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      barWidth: 1, // Minimal line width
      isStrokeCapRound: true,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3), // Lighter shade for gradient effect
            Colors.transparent,     // Fade out effect
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      dotData: FlDotData(show: false), // Hide dots for smoothness
    );
  }


  Widget _buildSensorGrid(String title, dynamic x, dynamic y, dynamic z) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSensorBox("X", x),
            _buildSensorBox("Y", y),
            _buildSensorBox("Z", z),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorBox(String axis, dynamic value) {
    return Expanded(
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(axis, style: TextStyle(color: Colors.white70)),
              Text(value?.toString() ?? "-", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}