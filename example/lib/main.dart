import 'package:flutter/material.dart';
import 'dart:async';

import 'package:guru_sdk/guru_sdk.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _guruSdkPlugin = GuruSdk();
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[1], ResolutionPreset.low,
        imageFormatGroup: ImageFormatGroup.yuv420);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      Future.delayed(const Duration(milliseconds: 5000)).then((value) async {
        await _guruSdkPlugin.createGuruVideoJob(
          'calisthenics',
          'push_up',
          'REDACTED',
        );

        Future.delayed(const Duration(milliseconds: 2000)).then((value) {
          controller.startImageStream((image) async {
            final yRowStride = image.planes[0].bytesPerRow;
            final uvRowStride = image.planes[1].bytesPerRow;
            final uvPixelStride = image.planes[1].bytesPerPixel!;
            var inference = await _guruSdkPlugin.newFrame([
              image.planes.map((e) => e.bytes).toList(),
              yRowStride,
              uvRowStride,
              uvPixelStride,
              image.height,
              image.width
            ]);
            print(
                '${inference.analysis.movement}  ${inference.analysis.reps.length}');
          });
        });
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    initPlatformState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // String platformVersion;
    // // Platform messages may fail, so we use a try/catch PlatformException.
    // // We also handle the message potentially returning null.
    // try {
    //   platformVersion = await _guruSdkPlugin.getPlatformVersion() ??
    //       'Unknown platform version';
    // } on PlatformException {
    //   platformVersion = 'Failed to get platform version.';
    // }

    // // If the widget was removed from the tree while the asynchronous platform
    // // message was in flight, we want to discard the reply rather than calling
    // // setState to update our non-existent appearance.
    // if (!mounted) return;

    // setState(() {
    //   _platformVersion = platformVersion;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Guru SDK'),
        ),
        body: CameraPreview(controller),
      ),
    );
  }
}
