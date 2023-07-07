import 'package:flutter/material.dart';
import 'package:ocr_scan_text/ocr_scan_text.dart';
import 'package:ocr_scan_text_example/scan_all_module.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan"),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 20,
          height: MediaQuery.of(context).size.height - 40,
          child: LiveScanWidget(
            matchedResult: (ScanModule module, List<ScanResult> scanResult) {
              if (module is! ScanAllModule) {
                return;
              }
              for (var element in scanResult) {
                print("matchedResult : ${element.cleanedText}");
                // module.stop();
              }
            },
            scanModules: [
              ScanAllModule()..start(),
            ],
          ),
        ),
      ),
    );
  }
}
