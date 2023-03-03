import 'package:flutter_test/flutter_test.dart';
import 'package:guru_sdk/guru_sdk_platform_interface.dart';
import 'package:guru_sdk/guru_sdk_method_channel.dart';

// class MockGuruSdkPlatform
//     with MockPlatformInterfaceMixin
//     implements GuruSdkPlatform {
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

void main() {
  final GuruSdkPlatform initialPlatform = GuruSdkPlatform.instance;

  test('$MethodChannelGuruSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGuruSdk>());
  });

  // test('getPlatformVersion', () async {
  //   GuruSdk guruSdkPlugin = GuruSdk();
  //   MockGuruSdkPlatform fakePlatform = MockGuruSdkPlatform();
  //   GuruSdkPlatform.instance = fakePlatform;

  //   expect(await guruSdkPlugin.getPlatformVersion(), '42');
  // });
}
