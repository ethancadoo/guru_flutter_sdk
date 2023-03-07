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

  MethodChannelGuruSdk() {
    methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'downloadStarted':
          downloadStarted?.call();
          break;
        case 'downloadFinished':
          downloadFinished?.call();
          break;
        default:
          throw UnimplementedError();
      }
      return Future.value(null);
    });
  }

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

  @override
  Future<void> cancelVideoJob() async {
    await methodChannel.invokeMethod('cancelVideoJob');
  }

  @override
  Future<bool> doesModelNeedToBeDownloaded(String apiKey) async {
    return await methodChannel.invokeMethod(
        'doesModelNeedToBeDownloaded', apiKey);
  }

  @override
  Future<void> downloadModel(String apiKey) async {
    await methodChannel.invokeMethod('downloadModel', apiKey);
  }
}
