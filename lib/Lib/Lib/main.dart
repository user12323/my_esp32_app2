import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Voltage Reader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  String voltageData = "No data yet";

  void startScan() {
    setState(() {
      scanResults.clear();
    });
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await flutterBlue.stopScan();
    await device.connect();
    setState(() {
      connectedDevice = device;
    });
    discoverServices(device);
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              voltageData = String.fromCharCodes(value);
            });
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 Voltage Reader")),
      body: connectedDevice == null
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: startScan,
                  child: const Text("Scan for Devices"),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: scanResults.length,
                    itemBuilder: (context, index) {
                      final result = scanResults[index];
                      return ListTile(
                        title: Text(result.device.name.isNotEmpty
                            ? result.device.name
                            : result.device.id.toString()),
                        subtitle: Text(result.device.id.toString()),
                        onTap: () => connectToDevice(result.device),
                      );
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                "Voltage: $voltageData",
                style: const TextStyle(fontSize: 28),
              ),
            ),
    );
  }
}
