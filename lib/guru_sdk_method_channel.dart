import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'guru_sdk.dart';
import 'guru_sdk_platform_interface.dart';

/// An implementation of [GuruSdkPlatform] that uses method channels.
class MethodChannelGuruSdk extends GuruSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('guru_sdk');

  @override
  Future<void> createGuruVideoJob(
      String domain, String activity, String apiKey) async {
    await methodChannel
        .invokeMethod<String>('createGuruVideoJob', [domain, activity, apiKey]);
  }

  @override
  Future<FrameInference> newFrame(dynamic frame) async {
    final inference = await methodChannel.invokeMethod('newFrame', frame);
    return FrameInference.fromJson(jsonDecode(inference));
  }
}
