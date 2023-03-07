import 'package:flutter/material.dart';
import 'dart:async';

import 'package:guru_sdk/guru_sdk.dart';
import 'package:camera/camera.dart';

import 'api_key.dart' as secrets;

const API_KEY = secrets.API_KEY;
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
  bool jobInProgress = false;
  String selectedWorkout = 'push_up';

  final _guruSdkPlugin = GuruSdk();
  late CameraController controller;

  FrameInference? lastFrameInference;

  @override
  void initState() {
    super.initState();

    _guruSdkPlugin.downloadStarted = () {
      print('Dart download started');
    };
    _guruSdkPlugin.downloadFinished = () {
      print('Dart download finished');
    };

    _guruSdkPlugin.doesModelNeedToBeDownloaded(API_KEY).then((value) {
      print('Model does need to be downloaded: $value');
      if (value) {
        _guruSdkPlugin.downloadModel(API_KEY);
      }
    });

    controller = CameraController(_cameras[1], ResolutionPreset.low,
        imageFormatGroup: ImageFormatGroup.yuv420);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});

      controller.startImageStream((image) async {
        final yRowStride = image.planes[0].bytesPerRow;
        final uvRowStride = image.planes[1].bytesPerRow;
        final uvPixelStride = image.planes[1].bytesPerPixel!;

        if (jobInProgress) {
          var inference = await _guruSdkPlugin.newFrame([
            image.planes.map((e) => e.bytes).toList(),
            yRowStride,
            uvRowStride,
            uvPixelStride,
            image.height,
            image.width
          ]);
          setState(() {
            lastFrameInference = inference;
          });
        }
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
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Guru Flutter SDK'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              CameraPreview(
                controller,
                child: CustomPaint(
                  size: controller.value.previewSize != null
                      ? controller.value.previewSize!
                      : Size.zero,
                  painter: JointOverlay(inference: lastFrameInference),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  lastFrameInference != null
                      ? '${lastFrameInference!.analysis.movement}  ${lastFrameInference!.analysis.reps.length}'
                      : 'null',
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text('Use smoothed keypoints'),
                  Switch(
                      value: GuruSdk.useSmoothedKeyPoints,
                      onChanged: (val) => setState(() {
                            GuruSdk.useSmoothedKeyPoints = val;
                          })),
                ],
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (jobInProgress) {
                      setState(() {
                        jobInProgress = false;
                      });
                      await _guruSdkPlugin.cancelVideoJob();
                    } else {
                      await _guruSdkPlugin.createGuruVideoJob(
                          'calisthenics', selectedWorkout, API_KEY);
                      setState(() {
                        jobInProgress = true;
                      });
                    }
                  },
                  child:
                      Text(jobInProgress ? 'Stop Guru Job' : 'Start guru job')),
              DropdownButton<String>(
                  value: selectedWorkout,
                  onChanged: (val) => setState(() => selectedWorkout = val!),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'push_up',
                      child: Text('Pushups'),
                    ),
                    DropdownMenuItem<String>(
                        value: 'bodyweight_squat',
                        child: Text('Body Weight Squat')),
                  ]),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class JointOverlay extends CustomPainter {
  FrameInference? inference;

  JointOverlay({this.inference});

  @override
  void paint(Canvas canvas, Size size) {
    if (inference == null) return;

    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.leftWrist),
        inference!.keypointForLandmark(InferenceLandmark.leftElbow));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.leftElbow),
        inference!.keypointForLandmark(InferenceLandmark.leftShoulder));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.leftShoulder),
        inference!.keypointForLandmark(InferenceLandmark.leftHip));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.leftHip),
        inference!.keypointForLandmark(InferenceLandmark.leftKnee));

    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.rightWrist),
        inference!.keypointForLandmark(InferenceLandmark.rightElbow));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.rightElbow),
        inference!.keypointForLandmark(InferenceLandmark.rightShoulder));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.rightShoulder),
        inference!.keypointForLandmark(InferenceLandmark.rightHip));
    drawJointTo(
        canvas,
        size,
        inference!.keypointForLandmark(InferenceLandmark.rightHip),
        inference!.keypointForLandmark(InferenceLandmark.rightKnee));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  final overlayPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 10.0;

  drawJointTo(Canvas canvas, Size s, KeyPoint? from, KeyPoint? to) {
    if (from != null) {
      final fromY = 1 - from.x;
      final fromX = 1 - from.y;

      canvas.drawCircle(
          Offset(fromX * s.width, fromY * s.height), 15.0, overlayPaint);

      if (to != null) {
        final toY = 1 - to.x;
        final toX = 1 - to.y;

        canvas.drawLine(Offset(fromX * s.width, fromY * s.height),
            Offset(toX * s.width, toY * s.height), overlayPaint);
      }
    }
  }
}
