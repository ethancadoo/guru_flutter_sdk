import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'guru_sdk.dart';
import 'guru_sdk_method_channel.dart';

abstract class GuruSdkPlatform extends PlatformInterface {
  /// Constructs a GuruSdkPlatform.
  GuruSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static GuruSdkPlatform _instance = MethodChannelGuruSdk();

  /// The default instance of [GuruSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelGuruSdk].
  static GuruSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GuruSdkPlatform] when
  /// they register themselves.
  static set instance(GuruSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> createGuruVideoJob(
      String domain, String activity, String apiKey);
  Future<FrameInference> newFrame(dynamic frame);
}
