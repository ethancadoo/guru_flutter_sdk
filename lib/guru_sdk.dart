import 'dart:convert';

import 'guru_sdk_platform_interface.dart';

class GuruSdk {
  Future<void> createGuruVideoJob(
      String domain, String activity, String apiKey) {
    return GuruSdkPlatform.instance
        .createGuruVideoJob(domain, activity, apiKey);
  }

  Future<FrameInference> newFrame(dynamic frame) async {
    return GuruSdkPlatform.instance.newFrame(frame);
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

