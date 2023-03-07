import 'dart:convert';

import 'guru_sdk_platform_interface.dart';

class GuruSdk {
  static bool useSmoothedKeyPoints = false;

  Future<void> createGuruVideoJob(
      String domain, String activity, String apiKey) {
    return GuruSdkPlatform.instance
        .createGuruVideoJob(domain, activity, apiKey);
  }

  Future<FrameInference> newFrame(dynamic frame) async {
    return GuruSdkPlatform.instance.newFrame(frame);
  }

  Future<void> cancelVideoJob() {
    return GuruSdkPlatform.instance.cancelVideoJob();
  }

  Function? get downloadStarted {
    return GuruSdkPlatform.instance.downloadStarted;
  }

  set downloadStarted(val) {
    GuruSdkPlatform.instance.downloadStarted = val;
  }

  Function? get downloadFinished {
    return GuruSdkPlatform.instance.downloadFinished;
  }

  set downloadFinished(val) {
    GuruSdkPlatform.instance.downloadFinished = val;
  }

  Future<bool> doesModelNeedToBeDownloaded(String apiKey) {
    return GuruSdkPlatform.instance.doesModelNeedToBeDownloaded(apiKey);
  }

  Future<void> downloadModel(String apiKey) {
    return GuruSdkPlatform.instance.downloadModel(apiKey);
  }
}

class FrameInference {
  FrameInference({
    required this.keypoints,
    required this.frameIndex,
    required this.secondsSinceStart,
    required this.analysis,
    required this.smoothKeypoints,
    required this.previousFrame,
  });
  late final List<KeyPoint> keypoints;
  late final int frameIndex;
  late final double secondsSinceStart;
  late final Analysis analysis;
  late final List<KeyPoint> smoothKeypoints;
  late final FrameInference? previousFrame;

  FrameInference.fromJson(Map<String, dynamic> json) {
    keypoints =
        List.from(json['keypoints']).map((e) => KeyPoint.fromJson(e)).toList();
    frameIndex = json['frameIndex'];
    secondsSinceStart = json['secondsSinceStart'];
    analysis = Analysis.fromJson(json['analysis']);
    smoothKeypoints = List.from(json['smoothKeypoints'])
        .map((e) => KeyPoint.fromJson(e))
        .toList();
    previousFrame = json['previousFrame'] != null
        ? FrameInference.fromJson(json['previousFrame'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['keypoints'] = keypoints.map((e) => e.toJson()).toList();
    data['frameIndex'] = frameIndex;
    data['secondsSinceStart'] = secondsSinceStart;
    data['analysis'] = analysis.toJson();
    data['smoothKeypoints'] = smoothKeypoints.map((e) => e.toJson()).toList();
    data['previousFrame'] = previousFrame?.toJson();
    return data;
  }

  final cocoKeypoints = [
    "nose",
    "left_eye",
    "right_eye",
    "left_ear",
    "right_ear",
    "left_shoulder",
    "right_shoulder",
    "left_elbow",
    "right_elbow",
    "left_wrist",
    "right_wrist",
    "left_hip",
    "right_hip",
    "left_knee",
    "right_knee",
    "left_ankle",
    "right_ankle",
  ];

  final cocoPairs = [
    ["left_shoulder", "right_shoulder"],
    ["left_shoulder", "left_hip"],
    ["left_hip", "left_knee"],
    ["left_knee", "left_ankle"],
    ["right_shoulder", "right_hip"],
    ["right_hip", "right_knee"],
    ["right_knee", "right_ankle"],
    ["left_hip", "right_hip"],
    ["left_shoulder", "left_elbow"],
    ["left_elbow", "left_wrist"],
    ["right_shoulder", "right_elbow"],
    ["right_elbow", "right_wrist"],
  ];

  int cocoLabelToIdx(String label) {
    return cocoKeypoints.indexOf(label);
  }

  KeyPoint? keypointForLandmark(InferenceLandmark landmark) {
    return GuruSdk.useSmoothedKeyPoints
        ? smoothKeypoints.isEmpty
            ? null
            : smoothKeypoints[
                cocoLabelToIdx(landmark.label).clamp(0, smoothKeypoints.length)]
        : keypoints.isEmpty
            ? null
            : keypoints[
                cocoLabelToIdx(landmark.label).clamp(0, keypoints.length)];
  }
}

class KeyPoint {
  KeyPoint({
    required this.score,
    required this.x,
    required this.y,
  });
  late final double score;
  late final double x;
  late final double y;

  KeyPoint.fromJson(Map<String, dynamic> json) {
    score = json['score'];
    x = json['x'];
    y = json['y'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['score'] = score;
    data['x'] = x;
    data['y'] = y;
    return data;
  }
}

class Analysis {
  Analysis({
    required this.movement,
    required this.reps,
  });
  late final String? movement;
  late final List<Reps> reps;

  Analysis.fromJson(Map<String, dynamic> json) {
    movement = json['movement'];
    reps = List.from(json['reps']).map((e) => Reps.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['movement'] = movement;
    data['reps'] = reps.map((e) => e.toJson()).toList();
    return data;
  }
}

class Reps {
  Reps({
    required this.startTimestamp,
    required this.midTimestamp,
    required this.endTimestamp,
    required this.analyses,
  });
  late final int startTimestamp;
  late final int midTimestamp;
  late final int endTimestamp;
  late final Map<String, dynamic> analyses;

  Reps.fromJson(Map<String, dynamic> json) {
    startTimestamp = json['startTimestamp'];
    midTimestamp = json['midTimestamp'];
    endTimestamp = json['endTimestamp'];
    analyses = jsonDecode(json['analyses']);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['startTimestamp'] = startTimestamp;
    data['midTimestamp'] = midTimestamp;
    data['endTimestamp'] = endTimestamp;
    data['analyses'] = analyses;
    return data;
  }
}

enum InferenceLandmark {
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

extension InferenceLandmarkExt on InferenceLandmark {
  static const labels = {
    InferenceLandmark.leftEye: "left_eye",
    InferenceLandmark.rightEye: "right_eye",
    InferenceLandmark.leftEar: "left_ear",
    InferenceLandmark.rightEar: "right_ear",
    InferenceLandmark.nose: "nose",
    InferenceLandmark.leftShoulder: "left_shoulder",
    InferenceLandmark.rightShoulder: "right_shoulder",
    InferenceLandmark.leftElbow: "left_elbow",
    InferenceLandmark.rightElbow: "right_elbow",
    InferenceLandmark.leftWrist: "left_wrist",
    InferenceLandmark.rightWrist: "right_wrist",
    InferenceLandmark.leftHip: "left_hip",
    InferenceLandmark.rightHip: "right_hip",
    InferenceLandmark.leftKnee: "left_knee",
    InferenceLandmark.rightKnee: "right_knee",
    InferenceLandmark.leftAnkle: "left_ankle",
    InferenceLandmark.rightAnkle: "right_ankle",
  };

  String get label => labels[this]!;
}

// class Analyses {
//   Analyses({
//     required this.STANDARDTECHNIQUECONFIDENCE,
//     required this.SIDEFACINGCONFIDENCE,
//     required this.VIDEOQUALITYSCORE,
//     required this.FORMSCORE,
//   });
//   late final int STANDARDTECHNIQUECONFIDENCE;
//   late final int SIDEFACINGCONFIDENCE;
//   late final double VIDEOQUALITYSCORE;
//   late final double FORMSCORE;
  
//   Analyses.fromJson(Map<String, dynamic> json){
//     STANDARDTECHNIQUECONFIDENCE = json['STANDARD_TECHNIQUE_CONFIDENCE'];
//     SIDEFACINGCONFIDENCE = json['SIDE_FACING_CONFIDENCE'];
//     VIDEOQUALITYSCORE = json['VIDEO_QUALITY_SCORE'];
//     FORMSCORE = json['FORM_SCORE'];
//   }

//   Map<String, dynamic> toJson() {
//     final _data = <String, dynamic>{};
//     _data['STANDARD_TECHNIQUE_CONFIDENCE'] = STANDARDTECHNIQUECONFIDENCE;
//     _data['SIDE_FACING_CONFIDENCE'] = SIDEFACINGCONFIDENCE;
//     _data['VIDEO_QUALITY_SCORE'] = VIDEOQUALITYSCORE;
//     _data['FORM_SCORE'] = FORMSCORE;
//     return _data;
//   }
// }

