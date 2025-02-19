import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_device_page.dart';
import 'bluetooth_scan_modal.dart';

void showScanModal(BuildContext context, List<ScanResult> scanResults) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Scanned Devices",
                style: TextStyle(fontSize: 18, color: Colors.white)),
            const Divider(color: Colors.grey),
            scanResults.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No devices found", style: TextStyle(color: Colors.grey)),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final device = scanResults[index].device;
                  return ListTile(
                    title: Text(
                      device.name.isNotEmpty ? device.name : "Unknown Device",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(device.remoteId.str, style: const TextStyle(color: Colors.grey)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BluetoothDevicePage(device: device),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
